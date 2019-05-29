const std = @import("std");
const builtin = @import("builtin");
const Token = std.zig.Token;
const ast = std.zig.ast;
const mem = std.mem;
const warn = std.debug.warn;
const Tree = ast.Tree;
const Node = ast.Node;
const Allocator = std.mem.Allocator;
const parse = std.zig.parse;

pub const Object = struct {
    parent: ?*Scope,
    position: Token,
    package: ?*Package,
    name: []const u8,
    id: []const u8,

    order: usize,
    color: Color,

    sameIdFn: fn (self: *Object, pkg: *Package, name: []const u8) bool,

    /// The start position for the scope that conains this object.
    scope_position: Token,

    pub const Color = enum {
        White,
        Black,
        Grey,
    };

    pub const Map = std.AutoHashMap([]const u8, *Object);

    pub fn format(
        self: *Object,
        comptime fmt: []const u8,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        return self.formatFn(self, fmt, context, Errors, output);
    }

    fn sameIdFn(self: *Object, pkg: *Package, name: []const u8) bool {
        return self.sameIdFn(self, pkg, name);
    }

    pub const Var = struct {
        object: Object,
        bound: ?bool,
    };
};

pub const Type = struct {
    id: Id,

    pub const Id = enum {
        Basic,
        Array,
        Slice,
        Container,
        Pointer,
        Signature,
        Mao,
        Named,
    };

    pub const Basic = struct {
        base: Type,
        id: builtin.TypeId,
        name: []const u8,
    };

    pub const Array = struct {
        length: usize,
        element: *Type,
    };

    pub const Slice = struct {
        element: *Type,
    };

    pub const Container = struct {
        members: std.ArrayList(*Object.Var),
    };

    pub const Pointer = struct {
        base_type: *Type,
    };

    pub fn format(
        self: *const Type,
        comptime fmt: []const u8,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        return self.defaultFormat(fmt, context, Errors, output);
    }

    pub fn defaultFormat(
        self: *const Type,
        comptime fmt: []const u8,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        switch (self.id) {
            .Basic => {
                const basic_decl = @fieldParentPtr(Basic, "base", self);
                try output(context, basic_decl.name);
            },
            else => unreachable,
        }
    }
};

pub const Scope = struct {
    parent: *Scope,
    children: List,
    elements: Object.Map,
    token: ?Token,
    is_func: bool,

    pub const List = std.ArrayList(*Scope);

    fn create(a: *Allocator, parent: ?*Scope) !*Scope {
        var s = try a.create(Scope);
        s.* = Scope{
            .parent = parent,
            .children = List.init(a),
            .elements = Map.init(a),
            .token = null,
            .is_func = false,
        };
        return s;
    }
    fn addSymbol(
        self: *Scope,
        parent: ?*Scope,
        name: []const u8,
        node: *Node,
    ) !void {}
};

/// Package defines a repesentation of a zig source file.
pub const Package = struct {
    ctx: ?*Context,
    name: []const u8,
    tree: ?Tree,
    scope: ?*Scope,
    imports: ?List,

    var standard_package = initName("std");
    var builtin_package = initName("builtin");

    fn initName(name: []const u8) Package {
        return Package{
            .name = name,
            .ctx = null,
            .tree = null,
            .scope = null,
            .imports = null,
        };
    }

    pub const Context = struct {
        allocator: *Allocator,

        // use this for creating objects that will live for the duration of the
        // context.All objects will be freed when the context is destored.
        arena_allocator: std.heap.ArenaAllocator,
        seen: SeenMap,

        pub const SeenMap = std.AutoHashMap([]const u8, *Package);

        fn init(a: *Allocator) !Context {
            var ctx = Context{
                .allocator = a,
                .arena_allocator = std.heap.ArenaAllocator.init(a),
                .seen = SeenMap.init(a),
            };
            _ = try (&ctx.seen).put("std", &standard_package);
            _ = try (&ctx.seen).put("builtin", &standard_package);
            return ctx;
        }

        fn arena(self: *Context) *Allocator {
            return &self.arena.allocator;
        }

        fn deinit(self: *Context) void {
            self.seen.deinit();
            self.arena_allocator.deinit();
        }
    };

    pub fn deinit(self: *Package) void {
        if (self.tree != null) {
            self.tree.deinit();
        }
    }

    pub const List = std.ArrayList(*Package);

    pub fn init(ctx: *Context, name: []const u8) !*Package {
        const m = &ctx.seen;
        if (m.get(name)) |kv| {
            return kv.value;
        }
        var pkg = try ctx.arena().create(Package);
        _ = try m.put(name, pkg);
        pkg.name = name;
        pkg.ctx = ctx;
        const contents = try readPackageFile(ctx.allocator, name);
        errdefer ctx.allocator.free(contents);
        defer ctx.allocator.free(contents);
        pkg.tree = try parse(ctx.arena(), contents);
        try pkg.import();
        return pkg;
    }

    fn import(self: *Package) !void {
        if (self.tree) |*tree| {
            var it = tree.root_node.decls.iterator(0);
            while (true) {
                var decl = (it.next() orelse return).*;
                try self.importNode(tree, decl);
            }
        }
    }

    fn importSybols(self: *Package, tree: *Tree, decl: *Node, lazy: bool) anyerror!void {
        // if context is not set yet there is no need for further processing of
        // this package.
        //
        //THis implies we don't want to load the package at the moment.
        if (self.ctx == null) return;

        switch (decl.id) {
            .VarDecl => {
                const var_decl = @fieldParentPtr(ast.Node.VarDecl, "base", decl);
                const decl_name = tree.tokenSlice(var_decl.name_token);
                if (var_decl.init_node) |node| {
                    switch (node.id) {
                        ast.Node.Id.BuiltinCall => {
                            const builtin_decl = @fieldParentPtr(ast.Node.BuiltinCall, "base", node);
                            const call_name = tree.tokenSlice(builtin_decl.builtin_token);
                            if (mem.eql(u8, call_name, "@import")) {
                                if (builtin_decl.iterate(0)) |param| {
                                    const param_decl = @fieldParentPtr(ast.Node.StringLiteral, "base", param);
                                    var param_name = tree.tokenSlice(param_decl.token);
                                    var pkg = self.ctx.?.arena().create(Package);
                                    param_name = mem.trim(u8, param_name, "\"");
                                    if (self.ctx.?.seen.get(parm)) |kv| {}
                                    pkg.* = Package.initName(param_name);
                                    warn("{}\n", param_name);
                                }
                            }
                        },
                        else => {},
                    }
                }
            },
            .FnProto => {
                const fn_decl = @fieldParentPtr(ast.Node.FnProto, "base", decl);
            },
            else => {},
        }
    }

    fn readPackageFile(a: *Allocator, path: []const u8) ![]const u8 {
        var ls = &std.ArrayList([]const u8).init(a);
        defer ls.deinit();
        const ext = ".zig";
        if (path.len < ext.len or !mem.eql(u8, path[(path.len - ext.len)..], ext)) {
            // the path is not for a zig file. eg @import("std"). We add the zig
            // extension before trying to read the file
            const file_name = try a.alloc(u8, path.len + ext.len);
            defer a.free(file_name);
            errdefer a.free(file_name);
            mem.copy(u8, file_name, path);
            mem.copy(u8, file_name[path.len..], ext);
            return std.io.readFileAlloc(a, file_name);
        }
        try ls.append(path);
        const resolved = try std.os.path.resolve(a, ls.toSlice());
        errdefer a.free(resolved);
        defer a.free(resolved);
        return std.io.readFileAlloc(a, resolved);
    }
};

test "Type.format" {
    const basic = Type.Basic{
        .base = Type{
            .id = .Basic,
        },
        .name = "basic_number",
        .id = .Int,
    };
    var typ = &basic.base;
    warn("{}\n", typ);
}

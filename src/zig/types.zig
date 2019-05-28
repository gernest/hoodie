const std = @import("std");
const Token = std.zig.Token;
const ast = std.zig.ast;
const mem = std.mem;
const warn = std.debug.warn;
const Tree = ast.Tree;
const Node = ast.Node;
const Allocator = std.mem.Allocator;
const parse = std.zig.parse;

pub const Object = struct {
    id: Id,
    base_object: ?*Base,
    pub const Id = enum {
        TypeName,
        Var,
        Const,
        PkgName,
    };

    pub const Base = struct {
        parent: *Scope,
        position: Token,
        pkg: *Package,
        name: []const u8,
        node: *Node,
        order: usize,
    };

    pub const Color = struct {};
    pub const Map = std.AutoHashMap([]const u8, *Object);
};

pub const Scope = struct {
    parent: *Scope,
    children: List,
    elements: Map,
    token: Token,

    // set to true if this is a function scope.
    is_func: bool,
    pub const List = std.ArrayList(*Scope);
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
        seen: SeenMap,

        pub const SeenMap = std.AutoHashMap([]const u8, *Package);

        fn init(a: *Allocator) !Context {
            var ctx = Context{
                .allocator = a,
                .seen = SeenMap.init(a),
            };
            _ = try (&ctx.seen).put("std", &standard_package);
            _ = try (&ctx.seen).put("builtin", &standard_package);
            return ctx;
        }

        fn deinit(self: *Context) void {
            self.seen.deinit();
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
        var pkg = try ctx.allocator.create(Package);
        _ = try m.put(name, pkg);
        pkg.name = name;
        pkg.ctx = ctx;
        const contents = try readPackageFile(ctx.allocator, name);
        errdefer ctx.allocator.free(contents);
        defer ctx.allocator.free(contents);
        pkg.tree = try parse(ctx.allocator, contents);
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

    fn importNode(self: *Package, tree: *Tree, decl: *Node) anyerror!void {
        switch (decl.id) {
            ast.Node.Id.VarDecl => {
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
                                    param_name = mem.trim(u8, param_name, "\"");
                                    warn("{}\n", param_name);
                                }
                            }
                        },
                        else => {},
                    }
                }
            },
            ast.Node.Id.FnProto => {
                // TODO: check for imports inside function bodies;
            },
            ast.Node.Id.TestDecl => {
                // TODO: check for imports inside tests functions.
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
        warn("\n{}\n", resolved);
        return std.io.readFileAlloc(a, resolved);
    }
};

test "package" {
    var a = std.debug.global_allocator;
    var ctx = &try Package.Context.init(a);

    var pkg = try Package.init(ctx, "../main.zig");
    defer pkg.deinit();
}
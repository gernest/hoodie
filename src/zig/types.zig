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
    name: []const u8,
    tree: ?Tree,
    scope: ?*Scope,
    imports: ?List,

    pub const List = std.ArrayList(*Package);
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

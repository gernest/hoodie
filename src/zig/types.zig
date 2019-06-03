const builtin = @import("builtin");
const std = @import("std");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Node = ast.Node;
const Token = std.zig.Token;
const Tree = ast.Tree;
const ast = std.zig.ast;
const mem = std.mem;
const parse = std.zig.parse;
const sort = std.sort.sort;
const warn = std.debug.warn;

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

    pub const Map = std.AutoHashMap([]const u8, *Object);

    pub const Var = struct {
        object: Object,
        bound: ?bool,
    };

    pub const Color = enum {
        White,
        Black,
        Grey,
    };

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
};

pub const Type = struct {
    id: Id,

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

pub const StringSlice = ArrayList([]const u8);

pub const Scope = struct {
    parent: *Scope,
    children: List,
    elements: Object.Map,
    token: ?Token,
    is_func: bool,

    pub const List = ArrayList(*Scope);

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

    /// returns a scope's element names in sorted order.
    fn names(self: *Scope, a: *Allocator) !StringSlice {
        var ls = StringSlice.init(a);
        var it = self.elements.iterator();
        while (it.next()) |next| {
            try ls.append(next.key);
        }
        sort([]const u8, ls.toSlice(), stringSortFn);
        return ls;
    }

    fn stringSortFn(lhs: []const u8, rhs: []const u8) bool {
        return mem.compare(u8, lhs, rhs) == .LessThan;
    }
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

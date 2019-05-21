const std = @import("std");
const Token = std.zig.Token;

/// Package defines a repesentation of a zig source file.
pub const Package = struct {
    path: []const u8,
    name: []const u8,
    scope: *Scope,
    complete: bool,
    imports: List,

    pub const List = std.ArrayList(*Package);
};

pub const Scope = struct {
    parent: *Scope,
    children: List,
    elements: Object.Map,
    token: Token,

    // set to true if this is a function scope.
    is_func: bool,
    pub const List = std.ArrayList(*Scope);
};

pub const Object = struct {
    pub const Map = std.AutoHashMap([]const u8, *Object);
};

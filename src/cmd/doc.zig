const html = @import("docs/html.zig");
const outline = @import("outline");
const std = @import("std");

pub const File = struct {
    path: []const u8,
};

pub const Package = struct {
    path: []const u8,
    name: ?[]const u8,
};

pub const Spot = enum {
    ImportDecl,
    ConstDecl,
    TypeDecl,
    VarDecl,
    FuncDecl,
    MethodDecl,
    Use,
};

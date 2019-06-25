const std = @import("std");

const Allocator = std.mem.Allocator;
const ast = std.zig.ast;
const heap = std.heap;
const mem = std.mem;

pub const Position = struct {
    filename: []const u8,
    location: ast.Tree.Location,

    pub fn format(
        self: Position,
        comptime fmt: []const u8,
        comptime options: std.fmt.FormatOptions,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        try output(context, self.filename);
        var n = self.filename.len;
        if (!mem.eql(u8, self.filename, "")) {
            try output(context, ":");
        }
        try std.fmt.format(context, Errors, output, "{}", self.location.line);
        if (self.column != 0) {
            try std.fmt.format(context, Errors, output, ":{}", self.location.column);
        }
    }
};

pub const File = struct {
    set: *FileSet,
    name: []const u8,
    size: usize,
    arena: std.heap.ArenaAllocator,
    allocator: *mem.Allocator,
    ast: *ast.Tree,
    mutex: std.Mutex,
};

pub const FileSet = struct {
    mutex: std.Mutex,
    base: usize,
    files: FileList,
    last: ?*File,
    arena: std.heap.ArenaAllocator,

    /// general pusrpose allocator. Memory allocated with this are to me
    /// anually freed.
    allocator: *mem.Allocator,

    pub const FileList = std.ArrayList(*File);
};

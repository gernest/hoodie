const std = @import("std");
const debug = std.debug;
const mem = std.mem;
const os = std.os;
const heap = std.heap;
const builtin = @import("builtin");

const outline = @import("outline.zig").outline;

// taken from https://github.com/Hejsil/zig-clap
pub const OsIterator = struct {
    const Error = os.ArgIterator.NextError;

    arena: heap.ArenaAllocator,
    args: os.ArgIterator,

    pub fn init(allocator: *mem.Allocator) OsIterator {
        return OsIterator{
            .arena = heap.ArenaAllocator.init(allocator),
            .args = os.args(),
        };
    }

    pub fn deinit(iter: *OsIterator) void {
        iter.arena.deinit();
    }

    pub fn next(iter: *OsIterator) Error!?[]const u8 {
        if (builtin.os == builtin.Os.windows) {
            return try iter.args.next(&iter.arena.allocator) orelse return null;
        } else {
            return iter.args.nextPosix();
        }
    }
};

pub fn main() anyerror!void {
    var direct_allocator = std.heap.DirectAllocator.init();
    const allocator = &direct_allocator.allocator;
    defer direct_allocator.deinit();

    var iter = OsIterator.init(allocator);
    defer iter.deinit();
    _ = try iter.next(); //exe
    while (try iter.next()) |param| {
        if (mem.eql(u8, param, "outline")) {
            if (try iter.next()) |file_name| {
                if (std.io.readFileAlloc(allocator, file_name)) |data| {
                    defer allocator.free(data);
                    var buf = &try std.Buffer.init(allocator, "");
                    defer buf.deinit();
                    var stream = &std.io.BufferOutStream.init(buf).stream;
                    try outline(allocator, data, stream);
                    debug.warn("{}", buf.toSlice());
                } else |err| {
                    std.debug.warn("{}\n", err);
                    os.exit(1);
                }
            } else {
                debug.warn("{}\n", outline_help_missing_filename);
                os.exit(1);
            }
            return;
        }
    }
}

const outline_help_missing_filename =
    \\missing filename to outline command
    \\  USAGE
    \\hoodie outline [FILENAME]
    \\  FILENAME is absolute or relatime path to the zig source file.
;

const std = @import("std");
const clap = @import("clap/index.zig");
const debug = std.debug;

pub fn main() anyerror!void {
    var direct_allocator = std.heap.DirectAllocator.init();
    const allocator = &direct_allocator.allocator;
    defer direct_allocator.deinit();

    const params = []clap.Param([]const u8){clap.Param([]const u8).positional("outline")};

    var iter = clap.args.OsIterator.init(allocator);
    defer iter.deinit();

    const exe = try iter.next();

    // Finally we initialize our streaming parser.
    var parser = clap.StreamingClap([]const u8, clap.args.OsIterator).init(params, &iter);
    while (try parser.next()) |arg| {
        debug.warn("{}\n", arg);
    }
}

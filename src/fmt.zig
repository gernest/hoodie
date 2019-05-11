const std = @import("std");
const io = std.io;
const os = std.os;
const mem = std.mem;
const render = @import("fmt/render.zig").render;
const max_src_size = 2 * 1024 * 1024 * 1024; // 2 GiB

pub fn format(allocator: *mem.Allocator, stdout: var) !void {
    var stdin_file = try io.getStdIn();
    var stdin = stdin_file.inStream();

    const source_code = try stdin.stream.readAllAlloc(allocator, max_src_size);
    defer allocator.free(source_code);

    var tree = std.zig.parse(allocator, source_code) catch |err| {
        std.debug.warn("error parsing stdin: {}\n", err);
        os.exit(1);
    };
    defer tree.deinit();
    _ = try render(allocator, stdout, &tree);
}

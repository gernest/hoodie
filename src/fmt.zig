const render = @import("imports.zig").render;
const std = @import("std");

const io = std.io;
const mem = std.mem;
const os = std.os;

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
    if (tree.errors.count() > 0) {
        var stderr = try std.debug.getStderrStream();
        var error_it = tree.errors.iterator(0);
        while (error_it.next()) |parse_error| {
            try parse_error.render(&tree.tokens, stderr);
        }
        return;
    }
    _ = try render(allocator, stdout, tree);
}

pub fn formatFile(allocator: *mem.Allocator, file_path: []const u8, stdout: var) !void {
    const source_code = try std.io.readFileAlloc(allocator, file_path);
    defer allocator.free(source_code);

    var tree = std.zig.parse(allocator, source_code) catch |err| {
        std.debug.warn("error parsing stdin: {}\n", err);
        os.exit(1);
    };
    defer tree.deinit();
    if (tree.errors.count() > 0) {
        var stderr = try std.debug.getStderrStream();
        var error_it = tree.errors.iterator(0);
        while (error_it.next()) |parse_error| {
            try parse_error.render(&tree.tokens, stderr);
        }
        return;
    }
    const baf = try io.BufferedAtomicFile.create(allocator, file_path);
    defer baf.destroy();
    _ = try render(allocator, baf.stream(), tree);
    try baf.finish();
}

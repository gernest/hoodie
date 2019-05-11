const std = @import("std");
const render = @import("render.zig").render;
const warn = std.debug.warn;

fn testFmt(buf: *std.Buffer, src: []const u8, want: []const u8) !void {
    try buf.resize(0);
    var stream = &std.io.BufferOutStream.init(buf).stream;

    var tree = try std.zig.parse(buf.list.allocator, src);
    defer tree.deinit();
    _ = try render(buf.list.allocator, stream, &tree);
    warn("\n{}\n", buf.toSlice());
}

test "fmt" {
    var a = std.debug.global_allocator;
    var buf = &try std.Buffer.init(a, "");
    defer buf.deinit();

    try testFmt(buf,
        \\fn a()void{}
        \\fn b()void{}
    , "");
}

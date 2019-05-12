const std = @import("std");
const render = @import("render.zig").render;
const warn = std.debug.warn;
const testing = std.testing;

fn testFmt(buf: *std.Buffer, src: []const u8, want: []const u8) !void {
    try buf.resize(0);
    var stream = &std.io.BufferOutStream.init(buf).stream;

    var tree = try std.zig.parse(buf.list.allocator, src);
    defer tree.deinit();
    _ = try render(buf.list.allocator, stream, &tree);
    if (!buf.eql(want)) {
        warn("\n{x} {x}\n", buf.toSlice(), want);
    }
    testing.expect(buf.eql(want));
}

test "fmt" {
    var a = std.debug.global_allocator;
    var buf = &try std.Buffer.init(a, "");
    defer buf.deinit();

    // add newline for adjucent functions. It doesn't matter if they have
    // comments or not.
    try testFmt(buf,
        \\fn a()void{}
        \\fn b()void{}
    ,
        \\fn a() void {}
        \\
        \\fn b() void {}
        \\
    );

    // break down all blank lines to only one for functions defined next to each
    // other
    try testFmt(buf,
        \\fn a()void{}
        \\
        \\
        \\
        \\fn b()void{}
    ,
        \\fn a() void {}
        \\
        \\fn b() void {}
        \\
    );
}

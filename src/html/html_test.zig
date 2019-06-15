const html = @import("html.zig");
const std = @import("std");

const testing = std.testing;
const warn = std.debug.warn;

test "escape" {
    var a = std.debug.global_allocator;

    const src = "AAAAA < BBBBB > CCCCC & DDDDD ' EEEEE \" ";
    var buf = &try std.Buffer.init(a, "");
    defer buf.deinit();

    try html.escape(buf, src);
    const expect = "AAAAA &lt; BBBBB &gt; CCCCC &amp; DDDDD &apos; EEEEE &quot; ";
    testing.expect(buf.eql(expect));
}

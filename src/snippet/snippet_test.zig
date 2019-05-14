const std = @import("std");
const testing = std.testing;
const warn = std.debug.warn;
const snippet = @import("snippet.zig");

test "Builder" {
    const fixture = struct {
        fn case0(self: *snippet.Builder) anyerror!void {}
        fn case1(self: *snippet.Builder) anyerror!void {
            try self.writeText(
                \\hi { } $ | " , / \
            );
        }
        fn case2(self: *snippet.Builder) anyerror!void {
            try self.writePlaceholder(null);
        }
    };

    var a = std.debug.global_allocator;
    var buf = &try std.Buffer.init(a, "");
    defer buf.deinit();

    var b = &try snippet.Builder.init(a, buf);

    try expect(b, "", fixture.case0);
    try expect(
        b,
        \\hi { \} \$ | " , / \\
    ,
        fixture.case1,
    );
    try expect(
        b,
        \\${1}
    ,
        fixture.case2,
    );
}

fn expect(b: *snippet.Builder, expected: []const u8, cb: fn (*snippet.Builder) anyerror!void) !void {
    try b.reset();
    try cb(b);
    testing.expect(b.buf.eql(expected));
}

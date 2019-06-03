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
        fn case3(self: *snippet.Builder) anyerror!void {
            try self.writeText("hi ");
            try self.writePlaceholder(case3Part);
        }

        fn case3Part(self: *snippet.Builder) anyerror!void {
            try self.writeText("there");
        }

        fn case4(self: *snippet.Builder) anyerror!void {
            try self.writePlaceholder(case4id);
        }

        fn case4id(self: *snippet.Builder) anyerror!void {
            try self.writeText("id=");
            try self.writePlaceholder(case4nest);
        }

        fn case4nest(self: *snippet.Builder) anyerror!void {
            try self.writeText("{your id}");
        }

        fn case5(self: *snippet.Builder) anyerror!void {
            try self.writeChoice(
                [][]const u8{
                    "one",                    
                        \\{ } $ | " , / \
                    ,
                    "three",
                },
            );
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
    try expect(
        b,
        \\hi ${1:there}
    ,
        fixture.case3,
    );
    try expect(
        b,
        \\${1:id=${2:{your id\}}}
    ,
        fixture.case4,
    );
    try expect(
        b,
        \\${1|one,{ \} \$ \| " \, / \\,three|}
    ,
        fixture.case5,
    );
}

fn expect(b: *snippet.Builder, expected: []const u8, cb: fn (*snippet.Builder) anyerror!void) !void {
    try b.reset();
    try cb(b);
    testing.expect(b.buf.eql(expected));
}

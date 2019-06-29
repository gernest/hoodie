const std = @import("std");
const ignore = @import("ignore.zig");
const warn = std.debug.warn;
const testing = std.testing;

test "parse" {
    const rules =
        \\#ignore
        \\#ignore
        \\foo
        \\bar/*
        \\baz/bar/foo.txt
        \\one/more
    ;

    var a = std.debug.global_allocator;
    var rule = try ignore.parseString(a, rules);
    defer rule.deinit();

    testing.expectEqual(rule.patterns.len, 4);
    const expects = [_][]const u8{
        "foo", "bar/*", "baz/bar/foo.txt", "one/more",
    };
    for (rule.patterns.toSlice()) |p, i| {
        testing.expectEqualSlices(u8, p.raw, expects[i]);
    }
}

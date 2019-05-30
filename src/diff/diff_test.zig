const diff = @import("diff.zig");
const std = @import("std");

const testing = std.testing;
const warn = std.debug.warn;

const TestCase = struct {
    a: []const u8,
    b: []const u8,
    ops: []const diff.Op,
};

test "split lines" {
    var a = std.debug.global_allocator;

    var src = "A\nB\nC\n";

    const lines = try diff.splitLines(a, src);
    defer lines.deinit();

    const want = [][]const u8{
        "A",
        "B",
        "C",
    };

    testing.expectEqual(lines.len, want.len);
    for (lines.toSlice()) |v, i| {
        testing.expectEqualSlices(u8, v, want[i]);
    }
}

test "diff" {
    var a = std.debug.global_allocator;
    const cases = []const TestCase{
        TestCase{
            .a = "A\nB\nC\n",
            .b = "A\nB\nC\n",
            .ops = []const diff.Op{},
        },
        TestCase{
            .a = "A\nB\nC\n",
            .b = "A\nB\nC\n",
        },
    };
}

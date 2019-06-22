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

    const want = [_][]const u8{
        "A\n",
        "B\n",
        "C\n",
    };

    testing.expectEqual(lines.len, want.len);
    for (lines.toSlice()) |v, i| {
        testing.expectEqualSlices(u8, v, want[i]);
    }
}

const file_a = "a/a.go";
const file_b = "b/b.go";
const unified_prefix = "--- " ++ file_a ++ "\n+++ " ++ file_b ++ "\n";

test "diff" {
    var allocator = std.debug.global_allocator;
    const cases = [_]TestCase{
        TestCase{
            .a = "A\nB\nC\n",
            .b = "A\nB\nC\n",
            .ops = [_]diff.Op{},
        },
        TestCase{
            .a = "A\n",
            .b = "B\n",
            .ops = [_]diff.Op{
                diff.Op{
                    .kind = .Delete,
                    .content = null,
                    .i_1 = 0,
                    .i_2 = 1,
                    .j_1 = 0,
                },
                diff.Op{
                    .kind = .Insert,
                    .content = [_][]const u8{"B\n"},
                    .i_1 = 1,
                    .i_2 = 1,
                    .j_1 = 0,
                },
            },
        },
    };

    for (cases) |ts, i| {
        if (i == 0) {
            continue;
        }
        var arena = std.heap.ArenaAllocator.init(allocator);
        var a = try diff.splitLines(&arena.allocator, ts.a);
        var b = try diff.splitLines(&arena.allocator, ts.b);

        var ls = try diff.applyEdits(&arena.allocator, a.toSlice(), ts.ops);
        var u = try diff.Unified.init(
            &arena.allocator,
            file_a,
            file_b,
            a.toSlice(),
            ts.ops,
        );
        warn("{}\n", u);
        arena.deinit();
    }
}

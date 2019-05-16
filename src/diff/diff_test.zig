const Diff = @import("diff.zig");

const TestCase = struct {
    a: []const u8,
    b: []const u8,
};

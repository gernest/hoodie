const Clean = @import("Result.zig").Clean;
const std = @import("std");

const testing = std.testing;
const warn = std.debug.warn;

const NameResult = Clean([]const u8);

fn Hello(name: []const u8) NameResult {
    if (name.len > 0) {
        return NameResult.Some(name);
    }
    return NameResult.Raise("too short");
}

test "Result" {
    switch (Hello("")) {
        .Err => |err| {
            warn(" err {}\n", err);
        },
        .Ok => |ok| {
            warn(" ok {}\n", ok);
        },
        else => unreachable,
    }
}

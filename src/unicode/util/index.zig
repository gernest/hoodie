const debug = @import("std").debug;

pub fn terror(comptime fmt: []const u8) !void {
    debug.warn("{}\n", fmt);
    return error.TestFailed;
}

pub fn terrorf(comptime fmt: []const u8, args: ...) !void {
    debug.warn(fmt ++ "\n", args);
    return error.TestFailed;
}

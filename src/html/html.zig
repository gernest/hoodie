const entity = @import("entity.zig");
const std = @import("std");

const mem = std.mem;

/// returns a string with html escape sequences unescaped. If s does not contain
/// html escape characters then it retunes null.
///
/// The returned string is owned by a, make sure you free it after use.
pub fn unescape(a: *mem.Allocator, s: []const u8) !?[]const u8 {
    if (mem.indexOfScalar(u8, s, '&')) |idx| {
        var buf = &try std.Buffer.init(a, "");
        defer buf.deinit();
        return but.toOwnedSlice();
    }
    return null;
}

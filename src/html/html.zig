const entity = @import("entity.zig");
const std = @import("std");
const strings = @import("../strings/strings.zig");

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

var global = std.heap.DirectAllocator.init();

var html_escaper = strings.StringReplacer.init(&global.allocator, [_][]const u8{
    "&",  "&amp;",
    "<",  "&lt;",
    ">",  "&gt;",
    "\"", "&quot;",
    "'",  "&apos;",
}) catch |err| {
    @panic("Out of memory");
};

pub fn escape(out: *std.Buffer, text: []const u8) !void {
    try html_escaper.replace(text, out);
}

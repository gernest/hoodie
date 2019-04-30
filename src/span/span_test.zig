const std = @import("std");
const warn = std.debug.warn;
const span = @import("./span.zig");
test "format" {
    var s: span.Span = undefined;
    s.uri = "/path";
    warn("\n{+}\n", s);
}

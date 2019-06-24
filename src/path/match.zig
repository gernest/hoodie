const std = @import("std");
const unicode = std.unicode;

const EscapeResult = struct {
    rune: u32,
    chunk: []const u8,
};

fn getEsc(chunk: []const u8) !ExcapeResult {
    if (chunk.len == 0 or chunk[0] == '-' or chunk[0] == ']') {
        return error.BadPattern;
    }
    var e = ExcapeResult{ .rune = 0, .chunk = chunk };
    if (chunk[0] == '\\') {
        e.chunk = chunk[1..];
        if (e.chunk.len == 0) {
            return error.BadPattern;
        }
    }
    const r = try unicode.utf8Decode(chunk);
    e.chunk = e.chunk[@intCast(usize, r)..];
    if (e.chunk.len == 0) {
        return error.BadPattern;
    }
    e.rune = r;
    return e;
}

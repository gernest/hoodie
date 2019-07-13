const std = @import("std");
const encoding = @import("encoding.zig");

const Part = encoding.Part;
const warn = std.debug.warn;

const SanitizePartCase = struct {
    src: []const u8,

    fn init(src: []const u8) SanitizePartCase {
        return SanitizePartCase{ .src = src };
    }
};
test "lexParts" {
    const lex_parts_cases = [_]SanitizePartCase{
        SanitizePartCase.init("select 42"),
        SanitizePartCase.init("select 'quoted $42', $1"),
        SanitizePartCase.init(
            \\select "doubled quoted $42", $1
        ),
        SanitizePartCase.init("select 'foo''bar', $1"),
        SanitizePartCase.init(
            \\select """", $1
        ),
        SanitizePartCase.init(
            \\select "adsf""$1""adsf", $1, 'foo''$$12bar', $2, '$3
        ),
        SanitizePartCase.init(
            \\select E'escape string\' $42', $1
        ),
        SanitizePartCase.init(
            \\select e'escape string\' $42', $1
        ),
    };
    var a = std.debug.global_allocator;
    var ls = std.ArrayList(Part).init(a);
    for (lex_parts_cases) |case, i| {
        if (i != 1) {
            continue;
        }
        try ls.resize(0);
        try encoding.lexParts(&ls, case.src);
        warn("==>{}\n> ", i);
        for (ls.toSlice()) |p| {
            warn("{}\n", p);
        }
        warn("\n");
    }
}

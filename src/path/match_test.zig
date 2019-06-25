const std = @import("std");
const testing = std.testing;
const match_path = @import("match.zig");
const warn = std.debug.warn;

const MatchTest = struct {
    pattern: []const u8,
    s: []const u8,
    match: bool,
    err: ?match_path.MatchError,

    fn init(
        pattern: []const u8,
        s: []const u8,
        match: bool,
        err: ?match_path.MatchError,
    ) MatchTest {
        return MatchTest{
            .pattern = pattern,
            .s = s,
            .match = match,
            .err = err,
        };
    }
};

const sample = [_]MatchTest{
    MatchTest.init("abc", "abc", true, null),
    MatchTest.init("*", "abc", true, null),
    MatchTest.init("*c", "abc", true, null),
    MatchTest.init("a*", "a", true, null),
    MatchTest.init("a*", "abc", true, null),
    MatchTest.init("a*", "ab/c", false, null),
    MatchTest.init("a*/b", "abc/b", true, null),
    MatchTest.init("a*/b", "a/c/b", false, null),
    MatchTest.init("a*b*c*d*e*/f", "axbxcxdxe/f", true, null),
    MatchTest.init("a*b*c*d*e*/f", "axbxcxdxexxx/f", true, null),
    MatchTest.init("a*b*c*d*e*/f", "axbxcxdxe/xxx/f", false, null),
    MatchTest.init("a*b*c*d*e*/f", "axbxcxdxexxx/fff", false, null),
    MatchTest.init("a*b?c*x", "abxbbxdbxebxczzx", true, null),
    MatchTest.init("a*b?c*x", "abxbbxdbxebxczzy", false, null),
    MatchTest.init("ab[c]", "abc", true, null),
    MatchTest.init("ab[b-d]", "abc", true, null),
    MatchTest.init("ab[e-g]", "abc", false, null),
    MatchTest.init("ab[^c]", "abc", false, null),
    MatchTest.init("ab[^b-d]", "abc", false, null),
    MatchTest.init("ab[^e-g]", "abc", true, null),
    MatchTest.init("a\\*b", "a*b", true, null),
    MatchTest.init("a\\*b", "ab", false, null),
    MatchTest.init("a?b", "a☺b", true, null),
    MatchTest.init("a[^a]b", "a☺b", true, null),
    MatchTest.init("a???b", "a☺b", false, null),
    MatchTest.init("a[^a][^a][^a]b", "a☺b", false, null),
    MatchTest.init("[a-ζ]*", "α", true, null),
    MatchTest.init("*[a-ζ]", "A", false, null),
    MatchTest.init("a?b", "a/b", false, null),
    MatchTest.init("a*b", "a/b", false, null),
    MatchTest.init("[\\]a]", "]", true, null),
    MatchTest.init("[\\-]", "-", true, null),
    MatchTest.init("[x\\-]", "x", true, null),
    MatchTest.init("[x\\-]", "-", true, null),
    MatchTest.init("[x\\-]", "z", false, null),
    MatchTest.init("[\\-x]", "x", true, null),
    MatchTest.init("[\\-x]", "-", true, null),
    MatchTest.init("[\\-x]", "a", false, null),
    MatchTest.init("[]a]", "]", false, error.BadPattern),
    MatchTest.init("[-]", "-", false, error.BadPattern),
    MatchTest.init("[x-]", "x", false, error.BadPattern),
    MatchTest.init("[x-]", "-", false, error.BadPattern),
    MatchTest.init("[x-]", "z", false, error.BadPattern),
    MatchTest.init("[-x]", "x", false, error.BadPattern),
    MatchTest.init("[-x]", "-", false, error.BadPattern),
    MatchTest.init("[-x]", "a", false, error.BadPattern),
    MatchTest.init("\\", "a", false, error.BadPattern),
    MatchTest.init("[a-b-c]", "a", false, error.BadPattern),
    MatchTest.init("[", "a", false, error.BadPattern),
    MatchTest.init("[^", "a", false, error.BadPattern),
    MatchTest.init("[^bc", "a", false, error.BadPattern),
    MatchTest.init("a[", "a", false, null),
    MatchTest.init("a[", "ab", false, error.BadPattern),
    MatchTest.init("*x", "xxx", true, null),
};

test "match" {
    for (sample) |ts, i| {
        // if (i == 4) {
        //     break;
        // }
        // if (i != 14) {
        //     continue;
        // }
        if (ts.err) |err| {} else {
            const ok = try match_path.match(ts.pattern, ts.s);
            if (ok != ts.match) {
                warn("{} expected {} got {}\n", i, ts.match, ok);
            }
        }
    }
}

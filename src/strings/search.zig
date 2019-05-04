const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const warn = std.debug.warn;
const testing = std.testing;
// stringFinder efficiently finds strings in a source text. It's implemented
// using the Boyer-Moore string search algorithm:
// https://en.wikipedia.org/wiki/Boyer-Moore_string_search_algorithm
// https://www.cs.utexas.edu/~moore/publications/fstrpos.pdf (note: this aged
// document uses 1-based indexing)
pub const StringFinder = struct {
    pattern: []const u8,
    bad_char_skip: [256]usize,
    good_suffix_skip: []usize,
    const Self = @This();
    a: *Allocator,

    fn init(a: *Allocator, pattern: []const u8) !Self {
        var s: Self = undefined;
        s.a = a;
        s.pattern = pattern;
        if (pattern.len == 0) {
            return s;
        }
        s.good_suffix_skip = try a.alloc(usize, pattern.len);

        // last is the index of the last character in the pattern.
        const last = pattern.len - 1;
        // Build bad character table.
        // Bytes not in the pattern can skip one pattern's length.
        for (s.bad_char_skip) |*value| {
            value.* = pattern.len;
        }

        // The loop condition is < instead of <= so that the last byte does not
        // have a zero distance to itself. Finding this byte out of place implies
        // that it is not in the last position.
        var i: usize = 0;
        while (i < last) : (i += 1) {
            s.bad_char_skip[@intCast(usize, pattern[i])] = last - i;
        }

        // Build good suffix table.
        // First pass: set each value to the next index which starts a prefix of
        // pattern.
        var last_prefix = last;
        i = last;
        while (i >= 0) {
            if (hasPrefix(pattern, pattern[i + 1 ..])) {
                last_prefix = i + 1;
            }
            // lastPrefix is the shift, and (last-i) is len(suffix).
            s.good_suffix_skip[i] = last_prefix + last - 1;
            if (i == 0) {
                break;
            }
            i -= 1;
        }
        // Second pass: find repeats of pattern's suffix starting from the front.
        i = 0;
        while (i < last) : (i += 1) {
            const len_suffix = longestCommonSuffix(pattern, pattern[1 .. i + 1]);
            if (pattern[i - len_suffix] != pattern[last - len_suffix]) {
                s.good_suffix_skip[last - len_suffix] = len_suffix + last - i;
            }
        }
        return s;
    }

    fn deinit(self: *Self) void {
        if (self.pattern.len > 0) {
            self.a.free(self.good_suffix_skip);
        }
    }

    fn next(self: *Self, text: []const u8) ?usize {
        const size = self.pattern.len;
        var i = @intCast(isize, size) - 1;
        while (i < @intCast(isize, text.len)) {
            var j: isize = @intCast(isize, size) - 1;
            while (j >= 0 and (text[@intCast(usize, i)] == self.pattern[@intCast(usize, j)])) {
                i -= 1;
                j -= 1;
            }
            if (j < 0) {
                return @intCast(usize, i + 1);
            }
            i += @intCast(isize, max(
                self.bad_char_skip[@intCast(usize, text[@intCast(usize, i)])],
                self.good_suffix_skip[@intCast(usize, j)],
            ));
        }
        return null;
    }
};

pub fn stringFind(a: *Allocator, pattern: []const u8, text: []const u8) !?usize {
    var f = &try StringFinder.init(a, pattern);
    defer f.deinit();
    return f.next(text);
}

fn max(a: usize, b: usize) usize {
    if (a > b) {
        return a;
    }
    return b;
}

pub fn hasPrefix(s: []const u8, prefix: []const u8) bool {
    if (s.len < prefix.len) {
        return false;
    }
    return std.mem.eql(u8, s[0..prefix.len], prefix);
}

fn longestCommonSuffix(a: []const u8, b: []const u8) usize {
    var i: usize = 0;
    while (i < a.len and i < b.len) : (i += 1) {
        if (a[a.len - 1 - i] != b[b.len - 1 - i]) {
            break;
        }
    }
    return i;
}

test "next" {
    var a = std.debug.global_allocator;
    const TestCase = struct {
        pattern: []const u8,
        text: []const u8,
        index: ?usize,
        const Self = @This();

        fn init(pattern: []const u8, text: []const u8, index: ?usize) Self {
            return Self{
                .pattern = pattern,
                .text = text,
                .index = index,
            };
        }
    };

    const sample = []TestCase{
        TestCase.init("", "", 0),
        TestCase.init("", "abc", 0),
        TestCase.init("abc", "", null),
        TestCase.init("abc", "abc", 0),
        TestCase.init("d", "abcdefg", 3),
        TestCase.init("nan", "banana", 2),
        TestCase.init("pan", "anpanman", 2),
        TestCase.init("nnaaman", "anpanmanam", null),
        TestCase.init("abcd", "abc", null),
        TestCase.init("abcd", "bcd", null),
        TestCase.init("bcd", "abcd", 1),
        TestCase.init("abc", "acca", null),
        TestCase.init("aa", "aaa", 0),
        TestCase.init("baa", "aaaaa", null),
        TestCase.init("at that", "which finally halts.  at that point", 22),
    };
    for (sample) |ts, i| {
        if (i != 4) {
            continue;
        }
        const idx = try stringFind(a, ts.pattern, ts.text);
        std.testing.expectEqual(ts.index, idx);
    }
}

test "init" {
    var a = std.debug.global_allocator;
    const TestCase = struct {
        pattern: []const u8,
        bad: [256]usize,
        suf: []const usize,
        const Self = @This();

        fn init(pattern: []const u8, bad: [256]usize, suf: []const usize) Self {
            return Self{
                .pattern = pattern,
                .bad = bad,
                .suf = suf,
            };
        }
    };

    const sample = []TestCase{
        TestCase.init("abc", bad1, []usize{ 5, 4, 1 }),
        TestCase.init("mississi", bad2, []usize{ 5, 14, 13, 7, 11, 10, 7, 1 }),
        TestCase.init("abcxxxabc", bad3, []usize{ 14, 13, 12, 11, 10, 9, 11, 10, 1 }),
        TestCase.init("abyxcdeyx", bad4, []usize{ 7, 16, 15, 14, 13, 12, 7, 10, 1 }),
    };
    for (sample) |ts, idx| {
        var f = &try StringFinder.init(a, ts.pattern);
        for (f.bad_char_skip) |c, i| {
            var want = ts.bad[i];
            if (want == 0) {
                want = ts.pattern.len;
            }
            testing.expectEqual(c, want);
        }
        f.deinit();
    }
}

const bad1 = blk: {
    var a: [256]usize = undefined;
    a['a'] = 2;
    a['b'] = 1;
    a['c'] = 3;
    break :blk a;
};

const bad2 = blk: {
    var a: [256]usize = undefined;
    a['i'] = 3;
    a['m'] = 7;
    a['s'] = 1;
    break :blk a;
};

const bad3 = blk: {
    var a: [256]usize = undefined;
    a['a'] = 2;
    a['b'] = 1;
    a['c'] = 6;
    a['x'] = 3;
    break :blk a;
};

const bad4 = blk: {
    var a: [256]usize = undefined;
    a['a'] = 8;
    a['b'] = 7;
    a['c'] = 4;
    a['d'] = 3;
    a['e'] = 2;
    a['y'] = 1;
    a['x'] = 5;
    break :blk a;
};

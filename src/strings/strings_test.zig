const strings = @import("strings.zig");
const std = @import("std");
const warn = std.debug.warn;
const testing = std.testing;

test "StringFinder.next" {
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
        const idx = try strings.stringFind(a, ts.pattern, ts.text);
        std.testing.expectEqual(ts.index, idx);
    }
}

test "StringFinder.init" {
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
        var f = &try strings.StringFinder.init(a, ts.pattern);
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

// test "Replacer" {
//     var a = std.debug.global_allocator;
//     var html_escaper = &strings.Replacer.init(a);
//     try html_escaper.add("&", "&amp;");
//     try html_escaper.add("<", "&lt;");
//     try html_escaper.add(">", "&gt;");
//     try html_escaper.add(
//         \\"
//     , "&quot;");
//     try html_escaper.add("''", "&apos;");
//     defer html_escaper.deinit();
//     var buf = &try std.Buffer.init(a, "");
//     defer buf.deinit();

//     try testReplacer(buf, html_escaper, "No changes", "No changes");
//     try testReplacer(buf, html_escaper, "I <3 escaping & stuff", "I <3 escaping &amp; stuff");
//     try testReplacer(buf, html_escaper, "&&&", "&amp;&amp;&amp;");
//     try testReplacer(buf, html_escaper, "", "");
// }

test "SingleReplacer" {
    var a = std.debug.global_allocator;
    var html_escaper = &try strings.SingleReplacer.init(a, "&", "&amp;");
    defer html_escaper.deinit();
    var buf = &try std.Buffer.init(a, "");
    defer buf.deinit();
    var rep = &html_escaper.replacer;

    try testReplacer(buf, rep, "No changes", "No changes");
    try testReplacer(buf, rep, "I <3 escaping & stuff", "I <3 escaping &amp; stuff");
    try testReplacer(buf, rep, "&&&", "&amp;&amp;&amp;");
    try testReplacer(buf, rep, "", "");
}

fn testReplacer(buf: *std.Buffer, r: *strings.Replacer, text: []const u8, final: []const u8) !void {
    try buf.resize(0);
    try r.replace(text, buf);
    testing.expect(buf.eql(final));
}

test "generic" {
    var a = std.debug.global_allocator;

    var g = strings.GenericReplacer.init(a, [][]const u8{ "aa", "==" });
}

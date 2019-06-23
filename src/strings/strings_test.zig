const std = @import("std");
const strings = @import("strings.zig");

const math = std.math;
const testing = std.testing;
const warn = std.debug.warn;

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

    const sample = [_]TestCase{
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

    const sample = [_]TestCase{
        TestCase.init("abc", bad1, [_]usize{ 5, 4, 1 }),
        TestCase.init("mississi", bad2, [_]usize{ 5, 14, 13, 7, 11, 10, 7, 1 }),
        TestCase.init("abcxxxabc", bad3, [_]usize{ 14, 13, 12, 11, 10, 9, 11, 10, 1 }),
        TestCase.init("abyxcdeyx", bad4, [_]usize{ 7, 16, 15, 14, 13, 12, 7, 10, 1 }),
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

fn testReplacer(buf: *std.Buffer, r: *strings.StringReplacer, text: []const u8, final: []const u8) !void {
    try buf.resize(0);
    try r.replace(text, buf);
    if (!buf.eql(final)) {
        warn("expectt {} got {}\n", final, buf.toSlice());
    }
    testing.expect(buf.eql(final));
}

test "Replacer" {
    var a = std.heap.direct_allocator;

    var html_escaper = &try strings.StringReplacer.init(a, [_][]const u8{
        "&",  "&amp;",
        "<",  "&lt;",
        ">",  "&gt;",
        "\"", "&quot;",
        "'",  "&apos;",
    });
    defer html_escaper.deinit();

    var html_unescaper = &try strings.StringReplacer.init(a, [_][]const u8{
        "&amp;",  "&",
        "&lt;",   "<",
        "&gt;",   ">",
        "&quot;", "\"",
        "&apos;", "'",
    });
    defer html_unescaper.deinit();

    var capital_letters = &try strings.StringReplacer.init(a, [_][]const u8{
        "a", "A",
        "b", "B",
    });

    defer capital_letters.deinit();

    var buf = &try std.Buffer.init(a, "");
    defer buf.deinit();

    const s = [_][]const u8{
        [_]u8{0x0},  [_]u8{0x1},  [_]u8{0x1},
        [_]u8{0x2},  [_]u8{0x2},  [_]u8{0x3},
        [_]u8{0x3},  [_]u8{0x4},  [_]u8{0x4},
        [_]u8{0x5},  [_]u8{0x5},  [_]u8{0x6},
        [_]u8{0x6},  [_]u8{0x7},  [_]u8{0x7},
        [_]u8{0x8},  [_]u8{0x8},  [_]u8{0x9},
        [_]u8{0x9},  [_]u8{0xa},  [_]u8{0xa},
        [_]u8{0xb},  [_]u8{0xb},  [_]u8{0xc},
        [_]u8{0xc},  [_]u8{0xd},  [_]u8{0xd},
        [_]u8{0xe},  [_]u8{0xe},  [_]u8{0xf},
        [_]u8{0xf},  [_]u8{0x10}, [_]u8{0x10},
        [_]u8{0x11}, [_]u8{0x11}, [_]u8{0x12},
        [_]u8{0x12}, [_]u8{0x13}, [_]u8{0x13},
        [_]u8{0x14}, [_]u8{0x14}, [_]u8{0x15},
        [_]u8{0x15}, [_]u8{0x16}, [_]u8{0x16},
        [_]u8{0x17}, [_]u8{0x17}, [_]u8{0x18},
        [_]u8{0x18}, [_]u8{0x19}, [_]u8{0x19},
        [_]u8{0x1a}, [_]u8{0x1a}, [_]u8{0x1b},
        [_]u8{0x1b}, [_]u8{0x1c}, [_]u8{0x1c},
        [_]u8{0x1d}, [_]u8{0x1d}, [_]u8{0x1e},
        [_]u8{0x1e}, [_]u8{0x1f}, [_]u8{0x1f},
        [_]u8{0x20}, [_]u8{0x20}, [_]u8{0x21},
        [_]u8{0x21}, [_]u8{0x22}, [_]u8{0x22},
        [_]u8{0x23}, [_]u8{0x23}, [_]u8{0x24},
        [_]u8{0x24}, [_]u8{0x25}, [_]u8{0x25},
        [_]u8{0x26}, [_]u8{0x26}, [_]u8{0x27},
        [_]u8{0x27}, [_]u8{0x28}, [_]u8{0x28},
        [_]u8{0x29}, [_]u8{0x29}, [_]u8{0x2a},
        [_]u8{0x2a}, [_]u8{0x2b}, [_]u8{0x2b},
        [_]u8{0x2c}, [_]u8{0x2c}, [_]u8{0x2d},
        [_]u8{0x2d}, [_]u8{0x2e}, [_]u8{0x2e},
        [_]u8{0x2f}, [_]u8{0x2f}, [_]u8{0x30},
        [_]u8{0x30}, [_]u8{0x31}, [_]u8{0x31},
        [_]u8{0x32}, [_]u8{0x32}, [_]u8{0x33},
        [_]u8{0x33}, [_]u8{0x34}, [_]u8{0x34},
        [_]u8{0x35}, [_]u8{0x35}, [_]u8{0x36},
        [_]u8{0x36}, [_]u8{0x37}, [_]u8{0x37},
        [_]u8{0x38}, [_]u8{0x38}, [_]u8{0x39},
        [_]u8{0x39}, [_]u8{0x3a}, [_]u8{0x3a},
        [_]u8{0x3b}, [_]u8{0x3b}, [_]u8{0x3c},
        [_]u8{0x3c}, [_]u8{0x3d}, [_]u8{0x3d},
        [_]u8{0x3e}, [_]u8{0x3e}, [_]u8{0x3f},
        [_]u8{0x3f}, [_]u8{0x40}, [_]u8{0x40},
        [_]u8{0x41}, [_]u8{0x41}, [_]u8{0x42},
        [_]u8{0x42}, [_]u8{0x43}, [_]u8{0x43},
        [_]u8{0x44}, [_]u8{0x44}, [_]u8{0x45},
        [_]u8{0x45}, [_]u8{0x46}, [_]u8{0x46},
        [_]u8{0x47}, [_]u8{0x47}, [_]u8{0x48},
        [_]u8{0x48}, [_]u8{0x49}, [_]u8{0x49},
        [_]u8{0x4a}, [_]u8{0x4a}, [_]u8{0x4b},
        [_]u8{0x4b}, [_]u8{0x4c}, [_]u8{0x4c},
        [_]u8{0x4d}, [_]u8{0x4d}, [_]u8{0x4e},
        [_]u8{0x4e}, [_]u8{0x4f}, [_]u8{0x4f},
        [_]u8{0x50}, [_]u8{0x50}, [_]u8{0x51},
        [_]u8{0x51}, [_]u8{0x52}, [_]u8{0x52},
        [_]u8{0x53}, [_]u8{0x53}, [_]u8{0x54},
        [_]u8{0x54}, [_]u8{0x55}, [_]u8{0x55},
        [_]u8{0x56}, [_]u8{0x56}, [_]u8{0x57},
        [_]u8{0x57}, [_]u8{0x58}, [_]u8{0x58},
        [_]u8{0x59}, [_]u8{0x59}, [_]u8{0x5a},
        [_]u8{0x5a}, [_]u8{0x5b}, [_]u8{0x5b},
        [_]u8{0x5c}, [_]u8{0x5c}, [_]u8{0x5d},
        [_]u8{0x5d}, [_]u8{0x5e}, [_]u8{0x5e},
        [_]u8{0x5f}, [_]u8{0x5f}, [_]u8{0x60},
        [_]u8{0x60}, [_]u8{0x61}, [_]u8{0x61},
        [_]u8{0x62}, [_]u8{0x62}, [_]u8{0x63},
        [_]u8{0x63}, [_]u8{0x64}, [_]u8{0x64},
        [_]u8{0x65}, [_]u8{0x65}, [_]u8{0x66},
        [_]u8{0x66}, [_]u8{0x67}, [_]u8{0x67},
        [_]u8{0x68}, [_]u8{0x68}, [_]u8{0x69},
        [_]u8{0x69}, [_]u8{0x6a}, [_]u8{0x6a},
        [_]u8{0x6b}, [_]u8{0x6b}, [_]u8{0x6c},
        [_]u8{0x6c}, [_]u8{0x6d}, [_]u8{0x6d},
        [_]u8{0x6e}, [_]u8{0x6e}, [_]u8{0x6f},
        [_]u8{0x6f}, [_]u8{0x70}, [_]u8{0x70},
        [_]u8{0x71}, [_]u8{0x71}, [_]u8{0x72},
        [_]u8{0x72}, [_]u8{0x73}, [_]u8{0x73},
        [_]u8{0x74}, [_]u8{0x74}, [_]u8{0x75},
        [_]u8{0x75}, [_]u8{0x76}, [_]u8{0x76},
        [_]u8{0x77}, [_]u8{0x77}, [_]u8{0x78},
        [_]u8{0x78}, [_]u8{0x79}, [_]u8{0x79},
        [_]u8{0x7a}, [_]u8{0x7a}, [_]u8{0x7b},
        [_]u8{0x7b}, [_]u8{0x7c}, [_]u8{0x7c},
        [_]u8{0x7d}, [_]u8{0x7d}, [_]u8{0x7e},
        [_]u8{0x7e}, [_]u8{0x7f}, [_]u8{0x7f},
        [_]u8{0x80}, [_]u8{0x80}, [_]u8{0x81},
        [_]u8{0x81}, [_]u8{0x82}, [_]u8{0x82},
        [_]u8{0x83}, [_]u8{0x83}, [_]u8{0x84},
        [_]u8{0x84}, [_]u8{0x85}, [_]u8{0x85},
        [_]u8{0x86}, [_]u8{0x86}, [_]u8{0x87},
        [_]u8{0x87}, [_]u8{0x88}, [_]u8{0x88},
        [_]u8{0x89}, [_]u8{0x89}, [_]u8{0x8a},
        [_]u8{0x8a}, [_]u8{0x8b}, [_]u8{0x8b},
        [_]u8{0x8c}, [_]u8{0x8c}, [_]u8{0x8d},
        [_]u8{0x8d}, [_]u8{0x8e}, [_]u8{0x8e},
        [_]u8{0x8f}, [_]u8{0x8f}, [_]u8{0x90},
        [_]u8{0x90}, [_]u8{0x91}, [_]u8{0x91},
        [_]u8{0x92}, [_]u8{0x92}, [_]u8{0x93},
        [_]u8{0x93}, [_]u8{0x94}, [_]u8{0x94},
        [_]u8{0x95}, [_]u8{0x95}, [_]u8{0x96},
        [_]u8{0x96}, [_]u8{0x97}, [_]u8{0x97},
        [_]u8{0x98}, [_]u8{0x98}, [_]u8{0x99},
        [_]u8{0x99}, [_]u8{0x9a}, [_]u8{0x9a},
        [_]u8{0x9b}, [_]u8{0x9b}, [_]u8{0x9c},
        [_]u8{0x9c}, [_]u8{0x9d}, [_]u8{0x9d},
        [_]u8{0x9e}, [_]u8{0x9e}, [_]u8{0x9f},
        [_]u8{0x9f}, [_]u8{0xa0}, [_]u8{0xa0},
        [_]u8{0xa1}, [_]u8{0xa1}, [_]u8{0xa2},
        [_]u8{0xa2}, [_]u8{0xa3}, [_]u8{0xa3},
        [_]u8{0xa4}, [_]u8{0xa4}, [_]u8{0xa5},
        [_]u8{0xa5}, [_]u8{0xa6}, [_]u8{0xa6},
        [_]u8{0xa7}, [_]u8{0xa7}, [_]u8{0xa8},
        [_]u8{0xa8}, [_]u8{0xa9}, [_]u8{0xa9},
        [_]u8{0xaa}, [_]u8{0xaa}, [_]u8{0xab},
        [_]u8{0xab}, [_]u8{0xac}, [_]u8{0xac},
        [_]u8{0xad}, [_]u8{0xad}, [_]u8{0xae},
        [_]u8{0xae}, [_]u8{0xaf}, [_]u8{0xaf},
        [_]u8{0xb0}, [_]u8{0xb0}, [_]u8{0xb1},
        [_]u8{0xb1}, [_]u8{0xb2}, [_]u8{0xb2},
        [_]u8{0xb3}, [_]u8{0xb3}, [_]u8{0xb4},
        [_]u8{0xb4}, [_]u8{0xb5}, [_]u8{0xb5},
        [_]u8{0xb6}, [_]u8{0xb6}, [_]u8{0xb7},
        [_]u8{0xb7}, [_]u8{0xb8}, [_]u8{0xb8},
        [_]u8{0xb9}, [_]u8{0xb9}, [_]u8{0xba},
        [_]u8{0xba}, [_]u8{0xbb}, [_]u8{0xbb},
        [_]u8{0xbc}, [_]u8{0xbc}, [_]u8{0xbd},
        [_]u8{0xbd}, [_]u8{0xbe}, [_]u8{0xbe},
        [_]u8{0xbf}, [_]u8{0xbf}, [_]u8{0xc0},
        [_]u8{0xc0}, [_]u8{0xc1}, [_]u8{0xc1},
        [_]u8{0xc2}, [_]u8{0xc2}, [_]u8{0xc3},
        [_]u8{0xc3}, [_]u8{0xc4}, [_]u8{0xc4},
        [_]u8{0xc5}, [_]u8{0xc5}, [_]u8{0xc6},
        [_]u8{0xc6}, [_]u8{0xc7}, [_]u8{0xc7},
        [_]u8{0xc8}, [_]u8{0xc8}, [_]u8{0xc9},
        [_]u8{0xc9}, [_]u8{0xca}, [_]u8{0xca},
        [_]u8{0xcb}, [_]u8{0xcb}, [_]u8{0xcc},
        [_]u8{0xcc}, [_]u8{0xcd}, [_]u8{0xcd},
        [_]u8{0xce}, [_]u8{0xce}, [_]u8{0xcf},
        [_]u8{0xcf}, [_]u8{0xd0}, [_]u8{0xd0},
        [_]u8{0xd1}, [_]u8{0xd1}, [_]u8{0xd2},
        [_]u8{0xd2}, [_]u8{0xd3}, [_]u8{0xd3},
        [_]u8{0xd4}, [_]u8{0xd4}, [_]u8{0xd5},
        [_]u8{0xd5}, [_]u8{0xd6}, [_]u8{0xd6},
        [_]u8{0xd7}, [_]u8{0xd7}, [_]u8{0xd8},
        [_]u8{0xd8}, [_]u8{0xd9}, [_]u8{0xd9},
        [_]u8{0xda}, [_]u8{0xda}, [_]u8{0xdb},
        [_]u8{0xdb}, [_]u8{0xdc}, [_]u8{0xdc},
        [_]u8{0xdd}, [_]u8{0xdd}, [_]u8{0xde},
        [_]u8{0xde}, [_]u8{0xdf}, [_]u8{0xdf},
        [_]u8{0xe0}, [_]u8{0xe0}, [_]u8{0xe1},
        [_]u8{0xe1}, [_]u8{0xe2}, [_]u8{0xe2},
        [_]u8{0xe3}, [_]u8{0xe3}, [_]u8{0xe4},
        [_]u8{0xe4}, [_]u8{0xe5}, [_]u8{0xe5},
        [_]u8{0xe6}, [_]u8{0xe6}, [_]u8{0xe7},
        [_]u8{0xe7}, [_]u8{0xe8}, [_]u8{0xe8},
        [_]u8{0xe9}, [_]u8{0xe9}, [_]u8{0xea},
        [_]u8{0xea}, [_]u8{0xeb}, [_]u8{0xeb},
        [_]u8{0xec}, [_]u8{0xec}, [_]u8{0xed},
        [_]u8{0xed}, [_]u8{0xee}, [_]u8{0xee},
        [_]u8{0xef}, [_]u8{0xef}, [_]u8{0xf0},
        [_]u8{0xf0}, [_]u8{0xf1}, [_]u8{0xf1},
        [_]u8{0xf2}, [_]u8{0xf2}, [_]u8{0xf3},
        [_]u8{0xf3}, [_]u8{0xf4}, [_]u8{0xf4},
        [_]u8{0xf5}, [_]u8{0xf5}, [_]u8{0xf6},
        [_]u8{0xf6}, [_]u8{0xf7}, [_]u8{0xf7},
        [_]u8{0xf8}, [_]u8{0xf8}, [_]u8{0xf9},
        [_]u8{0xf9}, [_]u8{0xfa}, [_]u8{0xfa},
        [_]u8{0xfb}, [_]u8{0xfb}, [_]u8{0xfc},
        [_]u8{0xfc}, [_]u8{0xfd}, [_]u8{0xfd},
        [_]u8{0xfe}, [_]u8{0xfe}, [_]u8{0xff},
        [_]u8{0xff}, [_]u8{0x0},
    };

    var incl = &try strings.StringReplacer.init(a, s);
    defer incl.deinit();

    var simple = &try strings.StringReplacer.init(a, [_][]const u8{
        "a", "1",
        "a", "2",
    });
    defer simple.deinit();

    var simple2 = &try strings.StringReplacer.init(a, [_][]const u8{
        "a", "11",
        "a", "22",
    });
    defer simple2.deinit();

    const s2 = @import("sample.zig").sample;
    var repeat = &try strings.StringReplacer.init(a, s2);
    defer repeat.deinit();

    try testReplacer(buf, html_escaper, "No changes", "No changes");
    try testReplacer(buf, html_escaper, "I <3 escaping & stuff", "I &lt;3 escaping &amp; stuff");
    try testReplacer(buf, html_escaper, "&&&", "&amp;&amp;&amp;");
    try testReplacer(buf, html_escaper, "", "");

    try testReplacer(buf, capital_letters, "brad", "BrAd");
    try testReplacer(buf, capital_letters, "", "");

    try testReplacer(buf, incl, "brad", "csbe");
    try testReplacer(buf, incl, "\x00\xff", "\x01\x00");
    try testReplacer(buf, incl, "", "");

    try testReplacer(buf, simple, "brad", "br1d");

    try testReplacer(buf, repeat, "brad", "bbrrrrrrrrrrrrrrrrrradddd");
    try testReplacer(buf, repeat, "abba", "abbbba");
    try testReplacer(buf, repeat, "", "");

    try testReplacer(buf, simple2, "brad", "br11d");

    // try testReplacer(buf, html_unescaper, "&amp;amp;", "&amp;");
}

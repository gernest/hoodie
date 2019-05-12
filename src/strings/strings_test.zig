const strings = @import("strings.zig");
const std = @import("std");
const math = std.math;
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

fn testReplacer(buf: *std.Buffer, r: *strings.StringReplacer, text: []const u8, final: []const u8) !void {
    try buf.resize(0);
    try r.replace(text, buf);
    if (!buf.eql(final)) {
        warn("expectt {x} got {x}\n", final, buf.toSlice());
    }
    testing.expect(buf.eql(final));
}

test "Replacer" {
    var da = std.heap.DirectAllocator.init();
    defer da.deinit();
    var a = &da.allocator;

    var html_escaper = &try strings.StringReplacer.init(a, [][]const u8{
        "&",  "&amp;",
        "<",  "&lt;",
        ">",  "&gt;",
        "\"", "&quot;",
        "'",  "&apos;",
    });
    defer html_escaper.deinit();

    var capital_letters = &try strings.StringReplacer.init(a, [][]const u8{
        "a", "A",
        "b", "B",
    });

    defer capital_letters.deinit();

    var buf = &try std.Buffer.init(a, "");
    defer buf.deinit();

    const s = [][]const u8{
        []const u8{0x0},  []const u8{0x1},  []const u8{0x1},
        []const u8{0x2},  []const u8{0x2},  []const u8{0x3},
        []const u8{0x3},  []const u8{0x4},  []const u8{0x4},
        []const u8{0x5},  []const u8{0x5},  []const u8{0x6},
        []const u8{0x6},  []const u8{0x7},  []const u8{0x7},
        []const u8{0x8},  []const u8{0x8},  []const u8{0x9},
        []const u8{0x9},  []const u8{0xa},  []const u8{0xa},
        []const u8{0xb},  []const u8{0xb},  []const u8{0xc},
        []const u8{0xc},  []const u8{0xd},  []const u8{0xd},
        []const u8{0xe},  []const u8{0xe},  []const u8{0xf},
        []const u8{0xf},  []const u8{0x10}, []const u8{0x10},
        []const u8{0x11}, []const u8{0x11}, []const u8{0x12},
        []const u8{0x12}, []const u8{0x13}, []const u8{0x13},
        []const u8{0x14}, []const u8{0x14}, []const u8{0x15},
        []const u8{0x15}, []const u8{0x16}, []const u8{0x16},
        []const u8{0x17}, []const u8{0x17}, []const u8{0x18},
        []const u8{0x18}, []const u8{0x19}, []const u8{0x19},
        []const u8{0x1a}, []const u8{0x1a}, []const u8{0x1b},
        []const u8{0x1b}, []const u8{0x1c}, []const u8{0x1c},
        []const u8{0x1d}, []const u8{0x1d}, []const u8{0x1e},
        []const u8{0x1e}, []const u8{0x1f}, []const u8{0x1f},
        []const u8{0x20}, []const u8{0x20}, []const u8{0x21},
        []const u8{0x21}, []const u8{0x22}, []const u8{0x22},
        []const u8{0x23}, []const u8{0x23}, []const u8{0x24},
        []const u8{0x24}, []const u8{0x25}, []const u8{0x25},
        []const u8{0x26}, []const u8{0x26}, []const u8{0x27},
        []const u8{0x27}, []const u8{0x28}, []const u8{0x28},
        []const u8{0x29}, []const u8{0x29}, []const u8{0x2a},
        []const u8{0x2a}, []const u8{0x2b}, []const u8{0x2b},
        []const u8{0x2c}, []const u8{0x2c}, []const u8{0x2d},
        []const u8{0x2d}, []const u8{0x2e}, []const u8{0x2e},
        []const u8{0x2f}, []const u8{0x2f}, []const u8{0x30},
        []const u8{0x30}, []const u8{0x31}, []const u8{0x31},
        []const u8{0x32}, []const u8{0x32}, []const u8{0x33},
        []const u8{0x33}, []const u8{0x34}, []const u8{0x34},
        []const u8{0x35}, []const u8{0x35}, []const u8{0x36},
        []const u8{0x36}, []const u8{0x37}, []const u8{0x37},
        []const u8{0x38}, []const u8{0x38}, []const u8{0x39},
        []const u8{0x39}, []const u8{0x3a}, []const u8{0x3a},
        []const u8{0x3b}, []const u8{0x3b}, []const u8{0x3c},
        []const u8{0x3c}, []const u8{0x3d}, []const u8{0x3d},
        []const u8{0x3e}, []const u8{0x3e}, []const u8{0x3f},
        []const u8{0x3f}, []const u8{0x40}, []const u8{0x40},
        []const u8{0x41}, []const u8{0x41}, []const u8{0x42},
        []const u8{0x42}, []const u8{0x43}, []const u8{0x43},
        []const u8{0x44}, []const u8{0x44}, []const u8{0x45},
        []const u8{0x45}, []const u8{0x46}, []const u8{0x46},
        []const u8{0x47}, []const u8{0x47}, []const u8{0x48},
        []const u8{0x48}, []const u8{0x49}, []const u8{0x49},
        []const u8{0x4a}, []const u8{0x4a}, []const u8{0x4b},
        []const u8{0x4b}, []const u8{0x4c}, []const u8{0x4c},
        []const u8{0x4d}, []const u8{0x4d}, []const u8{0x4e},
        []const u8{0x4e}, []const u8{0x4f}, []const u8{0x4f},
        []const u8{0x50}, []const u8{0x50}, []const u8{0x51},
        []const u8{0x51}, []const u8{0x52}, []const u8{0x52},
        []const u8{0x53}, []const u8{0x53}, []const u8{0x54},
        []const u8{0x54}, []const u8{0x55}, []const u8{0x55},
        []const u8{0x56}, []const u8{0x56}, []const u8{0x57},
        []const u8{0x57}, []const u8{0x58}, []const u8{0x58},
        []const u8{0x59}, []const u8{0x59}, []const u8{0x5a},
        []const u8{0x5a}, []const u8{0x5b}, []const u8{0x5b},
        []const u8{0x5c}, []const u8{0x5c}, []const u8{0x5d},
        []const u8{0x5d}, []const u8{0x5e}, []const u8{0x5e},
        []const u8{0x5f}, []const u8{0x5f}, []const u8{0x60},
        []const u8{0x60}, []const u8{0x61}, []const u8{0x61},
        []const u8{0x62}, []const u8{0x62}, []const u8{0x63},
        []const u8{0x63}, []const u8{0x64}, []const u8{0x64},
        []const u8{0x65}, []const u8{0x65}, []const u8{0x66},
        []const u8{0x66}, []const u8{0x67}, []const u8{0x67},
        []const u8{0x68}, []const u8{0x68}, []const u8{0x69},
        []const u8{0x69}, []const u8{0x6a}, []const u8{0x6a},
        []const u8{0x6b}, []const u8{0x6b}, []const u8{0x6c},
        []const u8{0x6c}, []const u8{0x6d}, []const u8{0x6d},
        []const u8{0x6e}, []const u8{0x6e}, []const u8{0x6f},
        []const u8{0x6f}, []const u8{0x70}, []const u8{0x70},
        []const u8{0x71}, []const u8{0x71}, []const u8{0x72},
        []const u8{0x72}, []const u8{0x73}, []const u8{0x73},
        []const u8{0x74}, []const u8{0x74}, []const u8{0x75},
        []const u8{0x75}, []const u8{0x76}, []const u8{0x76},
        []const u8{0x77}, []const u8{0x77}, []const u8{0x78},
        []const u8{0x78}, []const u8{0x79}, []const u8{0x79},
        []const u8{0x7a}, []const u8{0x7a}, []const u8{0x7b},
        []const u8{0x7b}, []const u8{0x7c}, []const u8{0x7c},
        []const u8{0x7d}, []const u8{0x7d}, []const u8{0x7e},
        []const u8{0x7e}, []const u8{0x7f}, []const u8{0x7f},
        []const u8{0x80}, []const u8{0x80}, []const u8{0x81},
        []const u8{0x81}, []const u8{0x82}, []const u8{0x82},
        []const u8{0x83}, []const u8{0x83}, []const u8{0x84},
        []const u8{0x84}, []const u8{0x85}, []const u8{0x85},
        []const u8{0x86}, []const u8{0x86}, []const u8{0x87},
        []const u8{0x87}, []const u8{0x88}, []const u8{0x88},
        []const u8{0x89}, []const u8{0x89}, []const u8{0x8a},
        []const u8{0x8a}, []const u8{0x8b}, []const u8{0x8b},
        []const u8{0x8c}, []const u8{0x8c}, []const u8{0x8d},
        []const u8{0x8d}, []const u8{0x8e}, []const u8{0x8e},
        []const u8{0x8f}, []const u8{0x8f}, []const u8{0x90},
        []const u8{0x90}, []const u8{0x91}, []const u8{0x91},
        []const u8{0x92}, []const u8{0x92}, []const u8{0x93},
        []const u8{0x93}, []const u8{0x94}, []const u8{0x94},
        []const u8{0x95}, []const u8{0x95}, []const u8{0x96},
        []const u8{0x96}, []const u8{0x97}, []const u8{0x97},
        []const u8{0x98}, []const u8{0x98}, []const u8{0x99},
        []const u8{0x99}, []const u8{0x9a}, []const u8{0x9a},
        []const u8{0x9b}, []const u8{0x9b}, []const u8{0x9c},
        []const u8{0x9c}, []const u8{0x9d}, []const u8{0x9d},
        []const u8{0x9e}, []const u8{0x9e}, []const u8{0x9f},
        []const u8{0x9f}, []const u8{0xa0}, []const u8{0xa0},
        []const u8{0xa1}, []const u8{0xa1}, []const u8{0xa2},
        []const u8{0xa2}, []const u8{0xa3}, []const u8{0xa3},
        []const u8{0xa4}, []const u8{0xa4}, []const u8{0xa5},
        []const u8{0xa5}, []const u8{0xa6}, []const u8{0xa6},
        []const u8{0xa7}, []const u8{0xa7}, []const u8{0xa8},
        []const u8{0xa8}, []const u8{0xa9}, []const u8{0xa9},
        []const u8{0xaa}, []const u8{0xaa}, []const u8{0xab},
        []const u8{0xab}, []const u8{0xac}, []const u8{0xac},
        []const u8{0xad}, []const u8{0xad}, []const u8{0xae},
        []const u8{0xae}, []const u8{0xaf}, []const u8{0xaf},
        []const u8{0xb0}, []const u8{0xb0}, []const u8{0xb1},
        []const u8{0xb1}, []const u8{0xb2}, []const u8{0xb2},
        []const u8{0xb3}, []const u8{0xb3}, []const u8{0xb4},
        []const u8{0xb4}, []const u8{0xb5}, []const u8{0xb5},
        []const u8{0xb6}, []const u8{0xb6}, []const u8{0xb7},
        []const u8{0xb7}, []const u8{0xb8}, []const u8{0xb8},
        []const u8{0xb9}, []const u8{0xb9}, []const u8{0xba},
        []const u8{0xba}, []const u8{0xbb}, []const u8{0xbb},
        []const u8{0xbc}, []const u8{0xbc}, []const u8{0xbd},
        []const u8{0xbd}, []const u8{0xbe}, []const u8{0xbe},
        []const u8{0xbf}, []const u8{0xbf}, []const u8{0xc0},
        []const u8{0xc0}, []const u8{0xc1}, []const u8{0xc1},
        []const u8{0xc2}, []const u8{0xc2}, []const u8{0xc3},
        []const u8{0xc3}, []const u8{0xc4}, []const u8{0xc4},
        []const u8{0xc5}, []const u8{0xc5}, []const u8{0xc6},
        []const u8{0xc6}, []const u8{0xc7}, []const u8{0xc7},
        []const u8{0xc8}, []const u8{0xc8}, []const u8{0xc9},
        []const u8{0xc9}, []const u8{0xca}, []const u8{0xca},
        []const u8{0xcb}, []const u8{0xcb}, []const u8{0xcc},
        []const u8{0xcc}, []const u8{0xcd}, []const u8{0xcd},
        []const u8{0xce}, []const u8{0xce}, []const u8{0xcf},
        []const u8{0xcf}, []const u8{0xd0}, []const u8{0xd0},
        []const u8{0xd1}, []const u8{0xd1}, []const u8{0xd2},
        []const u8{0xd2}, []const u8{0xd3}, []const u8{0xd3},
        []const u8{0xd4}, []const u8{0xd4}, []const u8{0xd5},
        []const u8{0xd5}, []const u8{0xd6}, []const u8{0xd6},
        []const u8{0xd7}, []const u8{0xd7}, []const u8{0xd8},
        []const u8{0xd8}, []const u8{0xd9}, []const u8{0xd9},
        []const u8{0xda}, []const u8{0xda}, []const u8{0xdb},
        []const u8{0xdb}, []const u8{0xdc}, []const u8{0xdc},
        []const u8{0xdd}, []const u8{0xdd}, []const u8{0xde},
        []const u8{0xde}, []const u8{0xdf}, []const u8{0xdf},
        []const u8{0xe0}, []const u8{0xe0}, []const u8{0xe1},
        []const u8{0xe1}, []const u8{0xe2}, []const u8{0xe2},
        []const u8{0xe3}, []const u8{0xe3}, []const u8{0xe4},
        []const u8{0xe4}, []const u8{0xe5}, []const u8{0xe5},
        []const u8{0xe6}, []const u8{0xe6}, []const u8{0xe7},
        []const u8{0xe7}, []const u8{0xe8}, []const u8{0xe8},
        []const u8{0xe9}, []const u8{0xe9}, []const u8{0xea},
        []const u8{0xea}, []const u8{0xeb}, []const u8{0xeb},
        []const u8{0xec}, []const u8{0xec}, []const u8{0xed},
        []const u8{0xed}, []const u8{0xee}, []const u8{0xee},
        []const u8{0xef}, []const u8{0xef}, []const u8{0xf0},
        []const u8{0xf0}, []const u8{0xf1}, []const u8{0xf1},
        []const u8{0xf2}, []const u8{0xf2}, []const u8{0xf3},
        []const u8{0xf3}, []const u8{0xf4}, []const u8{0xf4},
        []const u8{0xf5}, []const u8{0xf5}, []const u8{0xf6},
        []const u8{0xf6}, []const u8{0xf7}, []const u8{0xf7},
        []const u8{0xf8}, []const u8{0xf8}, []const u8{0xf9},
        []const u8{0xf9}, []const u8{0xfa}, []const u8{0xfa},
        []const u8{0xfb}, []const u8{0xfb}, []const u8{0xfc},
        []const u8{0xfc}, []const u8{0xfd}, []const u8{0xfd},
        []const u8{0xfe}, []const u8{0xfe}, []const u8{0xff},
        []const u8{0xff}, []const u8{0x0},
    };

    var incl = &try strings.StringReplacer.init(a, s);
    defer incl.deinit();

    var simple = &try strings.StringReplacer.init(a, [][]const u8{
        "a", "1",
        "a", "2",
    });
    defer simple.deinit();

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
}

const utf8 = @import("index.zig");
const unicode = @import("../unicode.zig");
const t = @import("../util/index.zig");
const std = @import("std");

test "init" {
    if (utf8.max_rune != unicode.tables.max_rune) {
        try t.terror("wrong utf8.max_rune");
    }
    if (utf8.rune_error != unicode.tables.replacement_char) {
        try t.terror("wrong utf8.rune_error");
    }
}

const Utf8Map = struct {
    r: i32,
    str: []const u8,

    fn init(r: i32, str: []const u8) Utf8Map {
        return Utf8Map{ .r = r, .str = str };
    }
};

const utf8_map = []Utf8Map{
    Utf8Map.init(0x0000, "\x00"),
    Utf8Map.init(0x0001, "\x01"),
    Utf8Map.init(0x007e, "\x7e"),
    Utf8Map.init(0x007f, "\x7f"),
    Utf8Map.init(0x0080, "\xc2\x80"),
    Utf8Map.init(0x0081, "\xc2\x81"),
    Utf8Map.init(0x00bf, "\xc2\xbf"),
    Utf8Map.init(0x00c0, "\xc3\x80"),
    Utf8Map.init(0x00c1, "\xc3\x81"),
    Utf8Map.init(0x00c8, "\xc3\x88"),
    Utf8Map.init(0x00d0, "\xc3\x90"),
    Utf8Map.init(0x00e0, "\xc3\xa0"),
    Utf8Map.init(0x00f0, "\xc3\xb0"),
    Utf8Map.init(0x00f8, "\xc3\xb8"),
    Utf8Map.init(0x00ff, "\xc3\xbf"),
    Utf8Map.init(0x0100, "\xc4\x80"),
    Utf8Map.init(0x07ff, "\xdf\xbf"),
    Utf8Map.init(0x0400, "\xd0\x80"),
    Utf8Map.init(0x0800, "\xe0\xa0\x80"),
    Utf8Map.init(0x0801, "\xe0\xa0\x81"),
    Utf8Map.init(0x1000, "\xe1\x80\x80"),
    Utf8Map.init(0xd000, "\xed\x80\x80"),
    Utf8Map.init(0xd7ff, "\xed\x9f\xbf"), // last code point before surrogate half.
    Utf8Map.init(0xe000, "\xee\x80\x80"), // first code point after surrogate half.
    Utf8Map.init(0xfffe, "\xef\xbf\xbe"),
    Utf8Map.init(0xffff, "\xef\xbf\xbf"),
    Utf8Map.init(0x10000, "\xf0\x90\x80\x80"),
    Utf8Map.init(0x10001, "\xf0\x90\x80\x81"),
    Utf8Map.init(0x40000, "\xf1\x80\x80\x80"),
    Utf8Map.init(0x10fffe, "\xf4\x8f\xbf\xbe"),
    Utf8Map.init(0x10ffff, "\xf4\x8f\xbf\xbf"),
    Utf8Map.init(0xFFFD, "\xef\xbf\xbd"),
};

const surrogete_map = []Utf8Map{
    Utf8Map.init(0xd800, "\xed\xa0\x80"),
    Utf8Map.init(0xdfff, "\xed\xbf\xbf"),
};

const test_strings = [][]const u8{
    "",
    "abcd",
    "☺☻☹",
    "日a本b語ç日ð本Ê語þ日¥本¼語i日©",
    "日a本b語ç日ð本Ê語þ日¥本¼語i日©日a本b語ç日ð本Ê語þ日¥本¼語i日©日a本b語ç日ð本Ê語þ日¥本¼語i日©",
    "\x80\x80\x80\x80",
};

test "fullRune" {
    for (utf8_map) |m| {
        if (!utf8.fullRune(m.str)) {
            try t.terrorf("expected {} to be full rune\n", m.str);
        }
    }
    const sample = [][]const u8{ "\xc0", "\xc1" };
    for (sample) |m| {
        if (!utf8.fullRune(m)) {
            try t.terrorf("expected {} to be full rune\n", m);
        }
    }
}

test "encodeRune" {
    for (utf8_map) |m, idx| {
        var buf = []u8{0} ** 10;
        const n = try utf8.encodeRune(buf[0..], m.r);
        const ok = std.mem.eql(u8, buf[0..n], m.str);
        if (!ok) {
            try t.terrorf("\nexpected {} got {} size={} idx={}\n", m.str, buf[0..n], n, idx);
        }
    }
}

test "decodeRune" {
    for (utf8_map) |m| {
        const r = try utf8.decodeRune(m.str);
        if (r.value != m.r) {
            try t.terror("got wrong rune");
        }
        if (r.size != m.str.len) {
            try t.terror("got wrong size");
        }
    }
}

test "surrogateRune" {
    for (surrogete_map) |m| {
        var has_error: bool = false;
        if (utf8.decodeRune(m.str)) {} else |err| switch (err) {
            error.RuneError => {
                has_error = true;
            },
            else => unreachable,
        }
        if (!has_error) {
            try t.terror("expected an error");
        }
    }
}

test "Iterator" {
    const source = "a,b,c";
    var iter = utf8.Iterator.init(source);
    var a = try iter.next();
    if (a == null) {
        try t.terror("expected a valid rune");
    }
    if (a.?.value != 'a') {
        const sa = []const u8{@intCast(u8, a.?.value)};
        try t.terrorf("expected a got {}\n", sa);
    }
    _ = try iter.next();

    a = try iter.next();
    if (a == null) {
        try t.terror("expected a valid rune");
    }
    if (a.?.value != 'b') {
        const sa = []const u8{@intCast(u8, a.?.value)};
        try t.terrorf("expected , got {}\n", sa);
    }
    _ = try iter.next();
    _ = try iter.next();
    a = try iter.next();
    if (a != null) {
        try t.terror("expected null");
    }

    iter.reset(0);
    a = try iter.peek();
    if (a == null) {
        try t.terror("expected not null");
    }

    const b = try iter.next();
    if (b == null) {
        try t.terror("expected not null");
    }
    if (a.?.value != b.?.value) {
        const sa = []const u8{@intCast(u8, a.?.value)};
        const sb = []const u8{@intCast(u8, b.?.value)};
        try t.terrorf("expected {} to equal {}", sa, sb);
    }
}

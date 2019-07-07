// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//
// Copyright 2018 Geofrey Ernest MIT LICENSE

const std = @import("std");
const time = @import("time.zig");

const April = time.Month.April;
const December = time.Month.December;
const January = time.Month.January;
const Location = time.Location;
const Monday = time.Weekday.Monday;
const Saturday = time.Weekday.Saturday;
const September = time.Month.September;
const Sunday = time.Weekday.Sunday;
const Thursday = time.Weekday.Thursday;
const Wednesday = time.Weekday.Wednesday;
const math = std.math;
const mem = std.mem;
const testing = std.testing;

const failed_test = error.Failed;

const parsedTime = struct {
    year: isize,
    month: time.Month,
    day: isize,
    hour: isize,
    minute: isize,
    second: isize,
    nanosecond: isize,
    weekday: time.Weekday,
    zone_offset: isize,
    zone: []const u8,

    fn init(year: isize, month: time.Month, day: isize, hour: isize, minute: isize, second: isize, nanosecond: isize, weekday: time.Weekday, zone_offset: isize, zone: []const u8) parsedTime {
        return parsedTime{
            .year = year,
            .month = month,
            .day = day,
            .hour = hour,
            .minute = minute,
            .second = second,
            .nanosecond = nanosecond,
            .weekday = weekday,
            .zone_offset = zone_offset,
            .zone = zone,
        };
    }
};

const TimeTest = struct {
    seconds: i64,
    golden: parsedTime,
};

const utc_tests = [_]TimeTest{
    TimeTest{ .seconds = 0, .golden = parsedTime.init(1970, January, 1, 0, 0, 0, 0, Thursday, 0, "UTC") },
    TimeTest{ .seconds = 1221681866, .golden = parsedTime.init(2008, September, 17, 20, 4, 26, 0, Wednesday, 0, "UTC") },
    TimeTest{ .seconds = -1221681866, .golden = parsedTime.init(1931, April, 16, 3, 55, 34, 0, Thursday, 0, "UTC") },
    TimeTest{ .seconds = -11644473600, .golden = parsedTime.init(1601, January, 1, 0, 0, 0, 0, Monday, 0, "UTC") },
    TimeTest{ .seconds = 599529660, .golden = parsedTime.init(1988, December, 31, 0, 1, 0, 0, Saturday, 0, "UTC") },
    TimeTest{ .seconds = 978220860, .golden = parsedTime.init(2000, December, 31, 0, 1, 0, 0, Sunday, 0, "UTC") },
};

const nano_tests = [_]TimeTest{
    TimeTest{ .seconds = 0, .golden = parsedTime.init(1970, January, 1, 0, 0, 0, 1e8, Thursday, 0, "UTC") },
    TimeTest{ .seconds = 1221681866, .golden = parsedTime.init(2008, September, 17, 20, 4, 26, 2e8, Wednesday, 0, "UTC") },
};

const local_tests = [_]TimeTest{
    TimeTest{ .seconds = 0, .golden = parsedTime.init(1969, December, 31, 16, 0, 0, 0, Wednesday, -8 * 60 * 60, "PST") },
    TimeTest{ .seconds = 1221681866, .golden = parsedTime.init(2008, September, 17, 13, 4, 26, 0, Wednesday, -7 * 60 * 60, "PDT") },
};

const nano_local_tests = [_]TimeTest{
    TimeTest{ .seconds = 0, .golden = parsedTime.init(1969, December, 31, 16, 0, 0, 0, Wednesday, -8 * 60 * 60, "PST") },
    TimeTest{ .seconds = 1221681866, .golden = parsedTime.init(2008, September, 17, 13, 4, 26, 3e8, Wednesday, -7 * 60 * 60, "PDT") },
};

fn same(t: time.Time, u: *parsedTime) bool {
    const date = t.date();
    const clock = t.clock();
    const zone = t.zone();
    const check = date.year != u.year or @enumToInt(date.month) != @enumToInt(u.month) or
        date.day != u.day or clock.hour != u.hour or clock.min != u.minute or clock.sec != u.second or
        !mem.eql(u8, zone.name, u.zone) or zone.offset != u.zone_offset;
    if (check) {
        return false;
    }
    return t.year() == u.year and
        @enumToInt(t.month()) == @enumToInt(u.month) and
        t.day() == u.day and
        t.hour() == u.hour and
        t.minute() == u.minute and
        t.second() == u.second and
        t.nanosecond() == u.nanosecond and
        @enumToInt(t.weekday()) == @enumToInt(u.weekday);
}

test "TestSecondsToUTC" {
    // try skip();
    for (utc_tests) |ts| {
        var tm = time.unix(ts.seconds, 0, &Location.utc_local);
        const ns = tm.unix();
        testing.expectEqual(ns, ts.seconds);
        var golden = ts.golden;
        testing.expect(same(tm, &golden));
    }
}

test "TestNanosecondsToUTC" {
    // try skip();
    for (nano_tests) |tv| {
        var golden = tv.golden;
        const nsec = tv.seconds * i64(1e9) + @intCast(i64, golden.nanosecond);
        var tm = time.unix(0, nsec, &Location.utc_local);
        const new_nsec = tm.unix() * i64(1e9) + @intCast(i64, tm.nanosecond());
        testing.expectEqual(new_nsec, nsec);
        testing.expect(same(tm, &golden));
    }
}

test "TestSecondsToLocalTime" {
    // try skip();
    var buf = try std.Buffer.init(std.debug.global_allocator, "");
    defer buf.deinit();
    var loc = try Location.load("US/Pacific");
    defer loc.deinit();
    for (local_tests) |tv| {
        var golden = tv.golden;
        const sec = tv.seconds;
        var tm = time.unix(sec, 0, &loc);
        const new_sec = tm.unix();
        testing.expectEqual(new_sec, sec);
        testing.expect(same(tm, &golden));
    }
}

test "TestNanosecondsToUTC" {
    // try skip();
    var loc = try Location.load("US/Pacific");
    defer loc.deinit();
    for (nano_local_tests) |tv| {
        var golden = tv.golden;
        const nsec = tv.seconds * i64(1e9) + @intCast(i64, golden.nanosecond);
        var tm = time.unix(0, nsec, &loc);
        const new_nsec = tm.unix() * i64(1e9) + @intCast(i64, tm.nanosecond());
        testing.expectEqual(new_nsec, nsec);
        testing.expect(same(tm, &golden));
    }
}

const formatTest = struct {
    name: []const u8,
    format: []const u8,
    result: []const u8,

    fn init(name: []const u8, format: []const u8, result: []const u8) formatTest {
        return formatTest{ .name = name, .format = format, .result = result };
    }
};

const format_tests = [_]formatTest{
    formatTest.init("ANSIC", time.ANSIC, "Wed Feb  4 21:00:57 2009"),
    formatTest.init("UnixDate", time.UnixDate, "Wed Feb  4 21:00:57 PST 2009"),
    formatTest.init("RubyDate", time.RubyDate, "Wed Feb 04 21:00:57 -0800 2009"),
    formatTest.init("RFC822", time.RFC822, "04 Feb 09 21:00 PST"),
    formatTest.init("RFC850", time.RFC850, "Wednesday, 04-Feb-09 21:00:57 PST"),
    formatTest.init("RFC1123", time.RFC1123, "Wed, 04 Feb 2009 21:00:57 PST"),
    formatTest.init("RFC1123Z", time.RFC1123Z, "Wed, 04 Feb 2009 21:00:57 -0800"),
    formatTest.init("RFC3339", time.RFC3339, "2009-02-04T21:00:57-08:00"),
    formatTest.init("RFC3339Nano", time.RFC3339Nano, "2009-02-04T21:00:57.0123456-08:00"),
    formatTest.init("Kitchen", time.Kitchen, "9:00PM"),
    formatTest.init("am/pm", "3pm", "9pm"),
    formatTest.init("AM/PM", "3PM", "9PM"),
    formatTest.init("two-digit year", "06 01 02", "09 02 04"),
    // Three-letter months and days must not be followed by lower-case letter.
    formatTest.init("Janet", "Hi Janet, the Month is January", "Hi Janet, the Month is February"),
    // Time stamps, Fractional seconds.
    formatTest.init("Stamp", time.Stamp, "Feb  4 21:00:57"),
    formatTest.init("StampMilli", time.StampMilli, "Feb  4 21:00:57.012"),
    formatTest.init("StampMicro", time.StampMicro, "Feb  4 21:00:57.012345"),
    formatTest.init("StampNano", time.StampNano, "Feb  4 21:00:57.012345600"),
};

test "TestFormat" {
    // try skip();
    var tz = try Location.load("US/Pacific");
    defer tz.deinit();
    var ts = time.unix(0, 1233810057012345600, &tz);
    var buf = try std.Buffer.init(std.debug.global_allocator, "");
    defer buf.deinit();
    for (format_tests) |value| {
        try ts.formatBuffer(&buf, value.format);
        const got = buf.toSlice();
        testing.expect(std.mem.eql(u8, got, value.result));
    }
}

test "calendar" {
    // try skip();
    time.Time.calendar();
}

fn skip() !void {
    return error.SkipZigTest;
}

test "TestFormatSingleDigits" {
    // try skip();
    var buf = &try std.Buffer.init(std.debug.global_allocator, "");
    defer buf.deinit();

    var tt = time.date(2001, 2, 3, 4, 5, 6, 700000000, &Location.utc_local);
    const ts = formatTest.init("single digit format", "3:4:5", "4:5:6");

    try tt.formatBuffer(buf, ts.format);
    testing.expect(buf.eql(ts.result));

    try buf.resize(0);

    var stream = &std.io.BufferOutStream.init(buf).stream;
    try stream.print("{}", tt);
    const want = "2001-02-03 04:05:06.7 +0000 UTC";
    testing.expect(buf.eql(want));
}

test "TestFormatShortYear" {
    // try skip();
    var buf = &try std.Buffer.init(std.debug.global_allocator, "");
    defer buf.deinit();

    var want = &try std.Buffer.init(std.debug.global_allocator, "");
    defer want.deinit();

    var stream = &std.io.BufferOutStream.init(want).stream;

    const years = [_]isize{
        -100001, -100000, -99999,
        -10001,  -10000,  -9999,
        -1001,   -1000,   -999,
        -101,    -100,    -99,
        -11,     -10,     -9,
        -1,      0,       1,
        9,       10,      11,
        99,      100,     101,
        999,     1000,    1001,
        9999,    10000,   10001,
        99999,   100000,  100001,
    };
    for (years) |y| {
        const m = @enumToInt(January);
        const x = @intCast(isize, m);
        var tt = time.date(y, x, 1, 0, 0, 0, 0, &Location.utc_local);
        try buf.resize(0);
        try tt.formatBuffer(buf, "2006.01.02");
        try want.resize(0);
        const day: usize = 1;
        const month: usize = 1;
        if (y < 0) {
            try stream.print("-{d:4}.{d:2}.{d:2}", math.absCast(y), month, day);
        } else {
            try stream.print("{d:4}.{d:2}.{d:2}", math.absCast(y), month, day);
        }
        if (!buf.eql(want.toSlice())) {
            std.debug.warn("case: {} expected {} got {}\n", y, want.toSlice(), buf.toSlice());
        }
    }
}

test "TestNextStdChunk" {
    const next_std_chunk_tests = [_][]const u8{
        "(2006)-(01)-(02)T(15):(04):(05)(Z07:00)",
        "(2006)-(01)-(02) (002) (15):(04):(05)",
        "(2006)-(01) (002) (15):(04):(05)",
        "(2006)-(002) (15):(04):(05)",
        "(2006)(002)(01) (15):(04):(05)",
        "(2006)(002)(04) (15):(04):(05)",
    };
    var buf = &try std.Buffer.init(std.debug.global_allocator, "");
    defer buf.deinit();
    for (next_std_chunk_tests) |marked, i| {
        try markChunk(buf, marked);
        testing.expect(buf.eql(marked));
    }
}

var tmp: [39]u8 = undefined;

fn removeParen(format: []const u8) []const u8 {
    var s = tmp[0..format.len];
    var i: usize = 0;
    var n = i;
    while (i < format.len) : (i += 1) {
        if (format[i] == '(' or format[i] == ')') {
            continue;
        }
        s[n] = format[i];
        n += 1;
    }
    return s[0..n];
}

fn markChunk(buf: *std.Buffer, format: []const u8) !void {
    try buf.resize(0);
    var s = removeParen(format);

    while (s.len > 0) {
        const ch = time.nextStdChunk(s);
        try buf.append(ch.prefix);
        if (ch.chunk != .none) {
            try buf.append("(");
            try buf.append(chunName(ch.chunk));
            try buf.append(")");
        }
        s = ch.suffix;
    }
}

fn chunName(ch: time.chunk) []const u8 {
    return switch (ch) {
        .none => "",
        .stdLongMonth => "January",
        .stdMonth => "Jan",
        .stdNumMonth => "1",
        .stdZeroMonth => "01",
        .stdLongWeekDay => "Monday",
        .stdWeekDay => "Mon",
        .stdDay => "2",
        .stdUnderDay => "_2",
        .stdZeroDay => "02",
        .stdUnderYearDay => "__2",
        .stdZeroYearDay => "002",
        .stdHour => "15",
        .stdHour12 => "3",
        .stdZeroHour12 => "03",
        .stdMinute => "4",
        .stdZeroMinute => "04",
        .stdSecond => "5",
        .stdZeroSecond => "05",
        .stdLongYear => "2006",
        .stdYear => "06",
        .stdPM => "PM",
        .stdpm => "pm",
        .stdTZ => "MST",
        .stdISO8601TZ => "Z0700",
        .stdISO8601SecondsTZ => "Z070000",
        .stdISO8601ShortTZ => "Z07",
        .stdISO8601ColonTZ => "Z07:00",
        .stdISO8601ColonSecondsTZ => "Z07:00:00",
        .stdNumTZ => "-0700",
        .stdNumSecondsTz => "-070000",
        .stdNumShortTZ => "-07",
        .stdNumColonTZ => "-07:00",
        .stdNumColonSecondsTZ => "-07:00:00",
        else => "unknown",
    };
}

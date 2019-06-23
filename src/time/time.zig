// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//
// Copyright 2018 Geofrey Ernest MIT LICENSE

const builtin = @import("builtin");
const std = @import("std");

const Os = builtin.Os;
const darwin = std.os.darwin;
const linux = std.os.linux;
const mem = std.mem;
const posix = std.os.posix;
const warn = std.debug.warn;

const windows = std.os.windows;

pub const Location = struct {
    name: []const u8,
    zone: ?[]zone,
    tx: ?[]ZoneTrans,
    // Most lookups will be for the current time.
    // To avoid the binary search through tx, keep a
    // static one-element cache that gives the correct
    // zone for the time when the Location was created.
    // if cacheStart <= t < cacheEnd,
    // lookup can return cacheZone.
    // The units for cacheStart and cacheEnd are seconds
    // since January 1, 1970 UTC, to match the argument
    // to lookup.
    cache_start: ?i64,
    cache_end: ?i64,
    cached_zone: ?*zone,

    arena: std.heap.ArenaAllocator,
    const alpha: i64 = -1 << 63;
    const omega: i64 = 1 << 63 - 1;
    const max_file_size: usize = 10 << 20;
    const initLocation = switch (builtin.os) {
        Os.linux => initLinux,
        Os.macosx, Os.ios => initDarwin,
        else => @compileError("Unsupported OS"),
    };
    pub var utc_local = Location.init(std.heap.direct_allocator, "UTC");
    var unix_sources = [_][]const u8{
        "/usr/share/zoneinfo/",
        "/usr/share/lib/zoneinfo/",
        "/usr/lib/locale/TZ/",
    };

    // readFile reads contents of a file with path and writes the read bytes to buf.

    const zone = struct {
        name: []const u8,
        offset: isize,
        is_dst: bool,
    };

    const ZoneTrans = struct {
        when: i64,
        index: usize,
        is_std: bool,
        is_utc: bool,
    };

    pub const zoneDetails = struct {
        name: []const u8,
        offset: isize,
        start: i64,
        end: i64,
    };

    // alpha and omega are the beginning and end of time for zone
    // transitions.

    const dataIO = struct {
        p: []u8,
        n: usize,

        fn init(p: []u8) dataIO {
            return dataIO{
                .p = p,
                .n = 0,
            };
        }

        fn read(d: *dataIO, p: []u8) usize {
            if (d.n >= d.p.len) {
                // end of stream
                return 0;
            }
            const pos = d.n;
            const offset = pos + p.len;
            while ((d.n < offset) and (d.n < d.p.len)) : (d.n += 1) {
                p[d.n - pos] = d.p[d.n];
            }
            return d.n - pos;
        }

        fn big4(d: *dataIO) !i32 {
            var p: [4]u8 = undefined;
            const size = d.read(p[0..]);
            if (size < 4) {
                return error.BadData;
            }
            const o = @intCast(i32, p[3]) | (@intCast(i32, p[2]) << 8) | (@intCast(i32, p[1]) << 16) | (@intCast(i32, p[0]) << 24);
            return o;
        }

        // advances the cursor by n. next read will start after skipping the n bytes.
        fn skip(d: *dataIO, n: usize) void {
            d.n += n;
        }

        fn byte(d: *dataIO) !u8 {
            if (d.n < d.p.len) {
                const u = d.p[d.n];
                d.n += 1;
                return u;
            }
            return error.EOF;
        }
    };

    fn init(a: *mem.Allocator, name: []const u8) Location {
        var arena = std.heap.ArenaAllocator.init(a);
        return Location{
            .name = name,
            .zone = null,
            .tx = null,
            .arena = arena,
            .cache_start = null,
            .cache_end = null,
            .cached_zone = null,
        };
    }

    fn deinit(self: *Location) void {
        self.arena.deinit();
    }

    /// getLocal returns local timezone.
    pub fn getLocal() Location {
        return initLocation();
    }

    /// firstZoneUsed returns whether the first zone is used by some
    /// transition.
    pub fn firstZoneUsed(self: *const Location) bool {
        if (self.tx) |tx| {
            for (tx) |value| {
                if (value.index == 0) {
                    return true;
                }
            }
        }
        return false;
    }

    // lookupFirstZone returns the index of the time zone to use for times
    // before the first transition time, or when there are no transition
    // times.
    //
    // The reference implementation in localtime.c from
    // https://www.iana.org/time-zones/repository/releases/tzcode2013g.tar.gz
    // implements the following algorithm for these cases:
    // 1) If the first zone is unused by the transitions, use it.
    // 2) Otherwise, if there are transition times, and the first
    //    transition is to a zone in daylight time, find the first
    //    non-daylight-time zone before and closest to the first transition
    //    zone.
    // 3) Otherwise, use the first zone that is not daylight time, if
    //    there is one.
    // 4) Otherwise, use the first zone.
    pub fn lookupFirstZone(self: *const Location) usize {
        // Case 1.
        if (!self.firstZoneUsed()) {
            return 0;
        }

        // Case 2.
        if (self.tx) |tx| {
            if (tx.len > 0 and self.zone.?[tx[0].index].is_dst) {
                var zi = @intCast(isize, tx[0].index);
                while (zi >= 0) : (zi -= 1) {
                    if (!self.zone.?[@intCast(usize, zi)].is_dst) {
                        return @intCast(usize, zi);
                    }
                }
            }
        }
        // Case 3.
        if (self.zone) |tzone| {
            for (tzone) |z, idx| {
                if (!z.is_dst) {
                    return idx;
                }
            }
        }
        // Case 4.
        return 0;
    }

    /// lookup returns information about the time zone in use at an
    /// instant in time expressed as seconds since January 1, 1970 00:00:00 UTC.
    ///
    /// The returned information gives the name of the zone (such as "CET"),
    /// the start and end times bracketing sec when that zone is in effect,
    /// the offset in seconds east of UTC (such as -5*60*60), and whether
    /// the daylight savings is being observed at that time.
    pub fn lookup(self: *const Location, sec: i64) zoneDetails {
        if (self.zone == null) {
            return zoneDetails{
                .name = "UTC",
                .offset = 0,
                .start = alpha,
                .end = omega,
            };
        }
        if (self.tx) |tx| {
            if (tx.len == 0 or sec < tx[0].when) {
                const tzone = &self.zone.?[self.lookupFirstZone()];
                var end: i64 = undefined;
                if (tx.len > 0) {
                    end = tx[0].when;
                } else {
                    end = omega;
                }
                return zoneDetails{
                    .name = tzone.name,
                    .offset = tzone.offset,
                    .start = alpha,
                    .end = end,
                };
            }
        }

        // Binary search for entry with largest time <= sec.
        // Not using sort.Search to avoid dependencies.
        var lo: usize = 0;
        var hi = self.tx.?.len;
        var end = omega;
        while ((hi - lo) > 1) {
            const m = lo + ((hi - lo) / 2);
            const lim = self.tx.?[m].when;
            if (sec < lim) {
                end = lim;
                hi = m;
            } else {
                lo = m;
            }
        }
        const tzone = &self.zone.?[self.tx.?[lo].index];
        return zoneDetails{
            .name = tzone.name,
            .offset = tzone.offset,
            .start = self.tx.?[lo].when,
            .end = end,
        };
    }

    /// lookupName returns information about the time zone with
    /// the given name (such as "EST") at the given pseudo-Unix time
    /// (what the given time of day would be in UTC).
    pub fn lookupName(self: *Location, name: []const u8, unix: i64) !isize {
        // First try for a zone with the right name that was actually
        // in effect at the given time. (In Sydney, Australia, both standard
        // and daylight-savings time are abbreviated "EST". Using the
        // offset helps us pick the right one for the given time.
        // It's not perfect: during the backward transition we might pick
        // either one.)
        if (self.zone) |zone| {
            for (zone) |*z| {
                if (mem.eql(u8, z.name, name)) {
                    const d = self.lookup(unix - @intCast(i64, z.offset));
                    if (mem.eql(d.name, z.name)) {
                        return d.offset;
                    }
                }
            }
        }

        // Otherwise fall back to an ordinary name match.
        if (self.zone) |zone| {
            for (zone) |*z| {
                if (mem.eql(u8, z.name, name)) {
                    return z.offset;
                }
            }
        }
        return error.ZoneNotFound;
    }

    pub fn loadLocationFromTZData(a: *mem.Allocator, name: []const u8, data: []u8) !Location {
        var arena = std.heap.ArenaAllocator.init(a);
        var arena_allocator = &arena.allocator;
        defer arena.deinit();
        errdefer arena.deinit();
        var d = &dataIO.init(data);
        var magic: [4]u8 = undefined;
        var size = d.read(magic[0..]);
        if (size != 4) {
            return error.BadData;
        }
        if (!mem.eql(u8, magic, "TZif")) {
            return error.BadData;
        }
        // 1-byte version, then 15 bytes of padding
        var p: [16]u8 = undefined;
        size = d.read(p[0..]);
        if (size != 16 or p[0] != 0 and p[0] != '2' and p[0] != '3') {
            return error.BadData;
        }
        // six big-endian 32-bit integers:
        //  number of UTC/local indicators
        //  number of standard/wall indicators
        //  number of leap seconds
        //  number of transition times
        //  number of local time zones
        //  number of characters of time zone abbrev strings
        const n_value = enum(usize) {
            UTCLocal,
            STDWall,
            Leap,
            Time,
            Zone,
            Char,
        };

        var n: [6]usize = undefined;
        var i: usize = 0;
        while (i < 6) : (i += 1) {
            const nn = try d.big4();
            n[i] = @intCast(usize, nn);
        }
        // Transition times.
        var tx_times = try arena_allocator.alloc(u8, n[@enumToInt(n_value.Time)] * 4);
        _ = d.read(tx_times);
        var tx_times_data = dataIO.init(tx_times);

        // Time zone indices for transition times.
        var tx_zone = try arena_allocator.alloc(u8, n[@enumToInt(n_value.Time)]);
        _ = d.read(tx_zone);
        var tx_zone_data = dataIO.init(tx_zone);

        // Zone info structures
        var zone_data_value = try arena_allocator.alloc(u8, n[@enumToInt(n_value.Zone)] * 6);
        _ = d.read(zone_data_value);
        var zone_data = dataIO.init(zone_data_value);

        // Time zone abbreviations.
        var abbrev = try arena_allocator.alloc(u8, n[@enumToInt(n_value.Char)]);
        _ = d.read(abbrev);

        // Leap-second time pairs
        d.skip(n[@enumToInt(n_value.Leap)] * 8);

        // Whether tx times associated with local time types
        // are specified as standard time or wall time.
        var isstd = try arena_allocator.alloc(u8, n[@enumToInt(n_value.STDWall)]);
        _ = d.read(isstd);

        var isutc = try arena_allocator.alloc(u8, n[@enumToInt(n_value.UTCLocal)]);
        size = d.read(isutc);
        if (size == 0) {
            return error.BadData;
        }

        // If version == 2 or 3, the entire file repeats, this time using
        // 8-byte ints for txtimes and leap seconds.
        // We won't need those until 2106.

        var loc = Location.init(a, name);
        errdefer loc.deinit();
        var zalloc = &loc.arena.allocator;

        // Now we can build up a useful data structure.
        // First the zone information.
        //utcoff[4] isdst[1] nameindex[1]
        i = 0;
        var zones = try zalloc.alloc(zone, n[@enumToInt(n_value.Zone)]);
        while (i < n[@enumToInt(n_value.Zone)]) : (i += 1) {
            const zn = try zone_data.big4();
            const b = try zone_data.byte();
            var z: zone = undefined;
            z.offset = @intCast(isize, zn);
            z.is_dst = b != 0;
            const b2 = try zone_data.byte();
            if (@intCast(usize, b2) >= abbrev.len) {
                return error.BadData;
            }
            const cn = byteString(abbrev[b2..]);
            // we copy the name and ensure it stay valid throughout location
            // lifetime.
            var znb = try zalloc.alloc(u8, cn.len);
            mem.copy(u8, znb, cn);
            z.name = znb;
            zones[i] = z;
        }
        loc.zone = zones;

        // Now the transition time info.
        i = 0;
        const tx_n = n[@enumToInt(n_value.Time)];
        var tx_list = try zalloc.alloc(ZoneTrans, tx_n);
        if (tx_n != 0) {
            while (i < n[@enumToInt(n_value.Time)]) : (i += 1) {
                var tx: ZoneTrans = undefined;
                const w = try tx_times_data.big4();
                tx.when = @intCast(i64, w);
                if (@intCast(usize, tx_zone[i]) >= zones.len) {
                    return error.BadData;
                }
                tx.index = @intCast(usize, tx_zone[i]);
                if (i < isstd.len) {
                    tx.is_std = isstd[i] != 0;
                }
                if (i < isutc.len) {
                    tx.is_utc = isutc[i] != 0;
                }
                tx_list[i] = tx;
            }
            loc.tx = tx_list;
        } else {
            var ls = [_]ZoneTrans{ZoneTrans{
                .when = alpha,
                .index = 0,
                .is_std = false,
                .is_utc = false,
            }};
            loc.tx = ls[0..];
        }
        return loc;
    }

    // darwin_sources directory to search for timezone files.
    fn readFile(path: []const u8, buf: *std.Buffer) !void {
        var file = try std.fs.File.openRead(path);
        defer file.close();
        var stream = &file.inStream().stream;
        try stream.readAllBuffer(buf, max_file_size);
    }

    fn loadLocationFile(name: []const u8, buf: *std.Buffer, sources: [][]const u8) !void {
        var tmp = try std.Buffer.init(buf.list.allocator, "");
        defer tmp.deinit();
        for (sources) |source| {
            try buf.resize(0);
            try tmp.append(source);
            try tmp.append("/");
            try tmp.append(name);
            if (readFile(tmp.toSliceConst(), buf)) {} else |err| {
                continue;
            }
            return;
        }
        return error.MissingZoneFile;
    }

    fn loadLocationFromTZFile(a: *mem.Allocator, name: []const u8, sources: [][]const u8) !Location {
        var buf = try std.Buffer.init(a, "");
        defer buf.deinit();
        try loadLocationFile(name, &buf, sources);
        return loadLocationFromTZData(a, name, buf.toSlice());
    }

    pub fn load(name: []const u8) !Location {
        return loadLocationFromTZFile(std.heap.direct_allocator, name, unix_sources[0..]);
    }

    fn initDarwin() Location {
        return initLinux();
    }

    fn initLinux() Location {
        var tz: ?[]const u8 = null;
        if (std.process.getEnvMap(std.heap.direct_allocator)) |value| {
            var env = value;
            defer env.deinit();
            tz = env.get("TZ");
        } else |err| {}
        if (tz) |name| {
            if (name.len != 0 and !mem.eql(u8, name, "UTC")) {
                if (loadLocationFromTZFile(std.heap.direct_allocator, name, unix_sources[0..])) |tzone| {
                    return tzone;
                } else |err| {}
            }
        } else {
            var etc = [_][]const u8{"/etc/"};
            if (loadLocationFromTZFile(std.heap.direct_allocator, "localtime", etc[0..])) |tzone| {
                var zz = tzone;
                zz.name = "local";
                return zz;
            } else |err| {}
        }
        return utc_local;
    }

    fn byteString(x: []u8) []u8 {
        for (x) |v, idx| {
            if (v == 0) {
                return x[0..idx];
            }
        }
        return x;
    }
};

const seconds_per_minute = 60;
const seconds_per_hour = 60 * seconds_per_minute;
const seconds_per_day = 24 * seconds_per_hour;
const seconds_per_week = 7 * seconds_per_day;
const days_per_400_years = 365 * 400 + 97;
const days_per_100_years = 365 * 100 + 24;
const days_per_4_years = 365 * 4 + 1;
// The unsigned zero year for internal calculations.
// Must be 1 mod 400, and times before it will not compute correctly,
// but otherwise can be changed at will.
const absolute_zero_year: i64 = -292277022399;

// The year of the zero Time.
// Assumed by the unix_to_internal computation below.
const internal_year: i64 = 1;

// Offsets to convert between internal and absolute or Unix times.
const absolute_to_internal: i64 = (absolute_zero_year - internal_year) * @floatToInt(i64, 365.2425 * @intToFloat(f64, seconds_per_day));
const internal_to_absolute = -absolute_to_internal;

const unix_to_internal: i64 = (1969 * 365 + 1969 / 4 - 1969 / 100 + 1969 / 400) * seconds_per_day;
const internal_to_unix: i64 = -unix_to_internal;

const wall_to_internal: i64 = (1884 * 365 + 1884 / 4 - 1884 / 100 + 1884 / 400) * seconds_per_day;
const internal_to_wall: i64 = -wall_to_internal;

const has_monotonic = 1 << 63;
const max_wall = wall_to_internal + ((1 << 33) - 1); // year 2157
const min_wall = wall_to_internal; // year 1885

const nsec_mask: u64 = (1 << 30) - 1;
const nsec_shift = 30;

const context = @This();

pub const Time = struct {
    wall: u64,
    ext: i64,
    loc: *Location,

    const short_days = [_][]const u8{
        "Sun",
        "Mon",
        "Tue",
        "Wed",
        "Thu",
        "Fri",
        "Sat",
    };

    const divResult = struct {
        qmod: isize,
        r: Duration,
    };

    // div divides self by d and returns the quotient parity and remainder.
    // We don't use the quotient parity anymore (round half up instead of round to even)
    // but it's still here in case we change our minds.

    fn nsec(self: Time) i32 {
        if (self.wall == 0) {
            return 0;
        }
        return @intCast(i32, self.wall & nsec_mask);
    }

    fn sec(self: Time) i64 {
        if ((self.wall & has_monotonic) != 0) {
            return wall_to_internal + @intCast(i64, self.wall << 1 >> (nsec_shift + 1));
        }
        return self.ext;
    }

    // unixSec returns the time's seconds since Jan 1 1970 (Unix time).
    fn unixSec(self: Time) i64 {
        return self.sec() + internal_to_unix;
    }

    pub fn unix(self: Time) i64 {
        return self.unixSec();
    }

    fn addSec(self: *Time, d: i64) void {
        if ((self.wall & has_monotonic) != 0) {
            const s = @intCast(i64, self.wall << 1 >> (nsec_shift + 1));
            const dsec = s + d;
            if (0 <= dsec and dsec <= (1 << 33) - 1) {
                self.wall = self.wall & nsec_mask | @intCast(u64, dsec) << nsec_shift | has_monotonic;
                return;
            }
            // Wall second now out of range for packed field.
            // Move to ext
            self.stripMono();
        }
        self.ext += d;
    }

    /// addDate returns the time corresponding to adding the
    /// given number of years, months, and days to t.
    /// For example, addDate(-1, 2, 3) applied to January 1, 2011
    /// returns March 4, 2010.
    ///
    /// addDate normalizes its result in the same way that Date does,
    /// so, for example, adding one month to October 31 yields
    /// December 1, the normalized form for November 31.
    pub fn addDate(self: Time, years: isize, number_of_months: isize, number_of_days: isize) Time {
        const d = self.date();
        const c = self.clock();
        const m = @intCast(isize, @enumToInt(d.month)) + number_of_months;
        return context.date(
            d.year + years,
            m,
            d.day + number_of_days,
            c.hour,
            c.min,
            c.sec,
            @intCast(isize, self.nsec()),
            self.loc,
        );
    }

    fn stripMono(self: *Time) void {
        if ((self.wall & has_monotonic) != 0) {
            self.ext = self.sec();
            self.wall &= nsec_mask;
        }
    }

    pub fn setLoc(self: *Time, l: *Location) void {
        self.stripMono();
        self.loc = l;
    }

    fn setMono(self: *Time, m: i64) void {
        if ((self.wall & has_monotonic) == 0) {
            const s = self.ext;
            if (s < min_wall or max_wall < s) {
                return;
            }
            self.wall |= has_monotonic | @intCast(u64, s - min_wall) << nsec_shift;
        }
        self.ext = m;
    }
    // mono returns t's monotonic clock reading.
    // It returns 0 for a missing reading.
    // This function is used only for testing,
    // so it's OK that technically 0 is a valid
    // monotonic clock reading as well.
    fn mono(self: *Time) i64 {
        if ((self.wall & has_monotonic) == 0) {
            return 0;
        }
        return self.ext;
    }

    pub fn isZero(self: Time) bool {
        return self.sec() == 0 and self.nsec() == 0;
    }

    /// returns true if time self is after time u.
    pub fn after(self: Time, u: Time) bool {
        const ts = self.sec();
        const us = u.sec();
        return ts > us or (ts == us and self.nsec() > u.nsec());
    }

    /// returns true if time self is before u.
    pub fn before(self: Time, u: Time) bool {
        return (self.sec() < u.sec()) or (self.sec() == u.sec() and self.nsec() < u.nsec());
    }

    /// reports whether self and u represent the same time instant.
    /// Two times can be equal even if they are in different locations.
    /// For example, 6:00 +0200 CEST and 4:00 UTC are Equal.
    /// See the documentation on the Time type for the pitfalls of using == with
    /// Time values; most code should use Equal instead.
    pub fn equal(self: Time, u: Time) bool {
        return self.sec() == u.sec() and self.nsec() == u.nsec();
    }

    /// abs returns the time t as an absolute time, adjusted by the zone offset.
    /// It is called when computing a presentation property like Month or Hour.
    fn abs(self: Time) u64 {
        var usec = self.unixSec();
        const d = self.loc.lookup(usec);
        usec += @intCast(i64, d.offset);
        var result: i64 = undefined;
        _ = @addWithOverflow(i64, usec, (unix_to_internal + internal_to_absolute), &result);
        return @bitCast(u64, result);
    }

    pub fn date(self: Time) DateDetail {
        return absDate(self.abs(), true);
    }

    pub fn year(self: Time) isize {
        const d = self.date();
        return d.year;
    }

    pub fn month(self: Time) Month {
        const d = self.date();
        return d.month;
    }

    pub fn day(self: Time) isize {
        const d = self.date();
        return d.day;
    }

    pub fn weekday(self: Time) Weekday {
        return absWeekday(self.abs());
    }

    /// isoWeek returns the ISO 8601 year and week number in which self occurs.
    /// Week ranges from 1 to 53. Jan 01 to Jan 03 of year n might belong to
    /// week 52 or 53 of year n-1, and Dec 29 to Dec 31 might belong to week 1
    /// of year n+1.
    pub fn isoWeek(self: Time) ISOWeek {
        var d = self.date();
        const wday = @mod(@intCast(isize, @enumToInt(self.weekday()) + 8), 7);
        const Mon: isize = 0;
        const Tue = Mon + 1;
        const Wed = Tue + 1;
        const Thu = Wed + 1;
        const Fri = Thu + 1;
        const Sat = Fri + 1;
        const Sun = Sat + 1;

        // Calculate week as number of Mondays in year up to
        // and including today, plus 1 because the first week is week 0.
        // Putting the + 1 inside the numerator as a + 7 keeps the
        // numerator from being negative, which would cause it to
        // round incorrectly.
        var week = @divTrunc(d.yday - wday + 7, 7);

        // The week number is now correct under the assumption
        // that the first Monday of the year is in week 1.
        // If Jan 1 is a Tuesday, Wednesday, or Thursday, the first Monday
        // is actually in week 2.
        const jan1wday = @mod((wday - d.yday + 7 * 53), 7);

        if (Tue <= jan1wday and jan1wday <= Thu) {
            week += 1;
        }
        if (week == 0) {
            d.year -= 1;
            week = 52;
        }

        // A year has 53 weeks when Jan 1 or Dec 31 is a Thursday,
        // meaning Jan 1 of the next year is a Friday
        // or it was a leap year and Jan 1 of the next year is a Saturday.
        if (jan1wday == Fri or (jan1wday == Sat) and isLeap(d.year)) {
            week += 1;
        }

        // December 29 to 31 are in week 1 of next year if
        // they are after the last Thursday of the year and
        // December 31 is a Monday, Tuesday, or Wednesday.
        if (@enumToInt(d.month) == @enumToInt(Month.December) and d.day >= 29 and wday < Thu) {
            const dec31wday = @mod((wday + 31 - d.day), 7);
            if (Mon <= dec31wday and dec31wday <= Wed) {
                d.year += 1;
                week = 1;
            }
        }
        return ISOWeek{ .year = d.year, .week = week };
    }

    /// clock returns the hour, minute, and second within the day specified by t.
    pub fn clock(self: Time) Clock {
        return Clock.absClock(self.abs());
    }

    /// hour returns the hour within the day specified by t, in the range [0, 23].
    pub fn hour(self: Time) isize {
        return @divTrunc(@intCast(isize, self.abs() % seconds_per_day), seconds_per_hour);
    }

    /// Minute returns the minute offset within the hour specified by t, in the
    /// range [0, 59].
    pub fn minute(self: Time) isize {
        return @divTrunc(@intCast(isize, self.abs() % seconds_per_hour), seconds_per_minute);
    }

    /// second returns the second offset within the minute specified by t, in the
    /// range [0, 59].
    pub fn second(self: Time) isize {
        return @intCast(isize, self.abs() % seconds_per_minute);
    }

    /// Nanosecond returns the nanosecond offset within the second specified by t,
    /// in the range [0, 999999999].
    pub fn nanosecond(self: Time) isize {
        return @intCast(isize, self.nsec());
    }

    /// yearDay returns the day of the year specified by t, in the range [1,365] for non-leap years,
    /// and [1,366] in leap years.
    pub fn yearDay(self: Time) isize {
        const d = absDate(self.abs(), false);
        return d.yday + 1;
    }

    /// zone computes the time zone in effect at time t, returning the abbreviated
    /// name of the zone (such as "CET") and its offset in seconds east of UTC.
    pub fn zone(self: Time) ZoneDetail {
        const zn = self.loc.lookup(self.unixSec());
        return ZoneDetail{
            .name = zn.name,
            .offset = zn.offset,
        };
    }

    /// utc returns time with the location set to UTC.
    fn utc(self: Time) Time {
        return Time{
            .wall = self.wall,
            .ext = self.ext,
            .loc = &Location.utc_local,
        };
    }

    fn string(self: Time, out: *std.Buffer) !void {
        try self.formatBuffer(out, DefaultFormat);
        // Format monotonic clock reading as m=±ddd.nnnnnnnnn.
        if ((self.wall & has_monotonic) != 0) {
            var stream = &std.io.BufferOutStream.init(out).stream;
            var m2 = @intCast(u64, self.ext);
            var sign: u8 = '+';
            if (self.ext < 0) {
                sign = '-';
                m2 = @intCast(u64, -self.ext);
            }
            var m1 = @divTrunc(m2, u64(1e9));
            m2 = @mod(m2, u64(1e9));
            var m0 = @divTrunc(m1, u64(1e9));
            m1 = @mod(m1, u64(1e9));
            try out.append("m=");
            try out.appendByte(sign);
            var wid: usize = 0;
            if (m0 != 0) {
                try appendInt(stream, @intCast(isize, m0), 0);
                wid = 9;
            }
            try appendInt(stream, @intCast(isize, m1), wid);
            try out.append(".");
            try appendInt(stream, @intCast(isize, m2), 9);
        }
    }

    pub fn format(
        self: Time,
        comptime fmt: []const u8,
        ctx: var,
        comptime Errors: type,
        output: fn (@typeOf(ctx), []const u8) Errors!void,
    ) Errors!void {
        var out: [DefaultFormat.len * 2]u8 = undefined;
        var a = &std.heap.FixedBufferAllocator.init(out[0..]).allocator;
        var buf = std.Buffer.init(a, "") catch return;
        self.string(&buf) catch return;
        try output(ctx, buf.toSlice());
    }

    /// formatBuffer returns a textual representation of the time value formatted
    /// according to layout, which defines the format by showing how the reference
    /// time, defined to be
    ///   Mon Jan 2 15:04:05 -0700 MST 2006
    /// would be displayed if it were the value; it serves as an example of the
    /// desired output. The same display rules will then be applied to the time
    /// value.
    ///
    /// A fractional second is represented by adding a period and zeros
    /// to the end of the seconds section of layout string, as in "15:04:05.000"
    /// to format a time stamp with millisecond precision.
    ///
    /// Predefined layouts ANSIC, UnixDate, RFC3339 and others describe standard
    /// and convenient representations of the reference time. For more information
    /// about the formats and the definition of the reference time, see the
    /// documentation for ANSIC and the other constants defined by this package.
    pub fn formatBuffer(self: Time, out: *std.Buffer, layout: []const u8) !void {
        try out.resize(0);
        var stream = std.io.BufferOutStream.init(out);
        return self.appendFormat(&stream.stream, layout);
    }

    fn appendInt(stream: var, x: isize, width: usize) !void {
        var u = std.math.absCast(x);
        if (x < 0) {
            try stream.write("-");
        }
        var buf: [20]u8 = undefined;
        var i = buf.len;
        while (u >= 10) {
            i -= 1;
            const q = @divTrunc(u, 10);
            buf[i] = @intCast(u8, '0' + u - q * 10);
            u = q;
        }
        i -= 1;
        buf[i] = '0' + @intCast(u8, u);
        var w = buf.len - i;
        while (w < width) : (w += 1) {
            try stream.write("0");
        }
        const v = buf[i..];
        try stream.write(v);
    }

    fn formatNano(stream: var, nanosec: usize, n: usize, trim: bool) !void {
        var u = nanosec;
        var buf = [_]u8{0} ** 9;
        var start = buf.len;
        while (start > 0) {
            start -= 1;
            buf[start] = @intCast(u8, @mod(u, 10) + '0');
            u /= 10;
        }
        var x = n;
        if (x > 9) {
            x = 9;
        }
        if (trim) {
            while (x > 0 and buf[x - 1] == '0') : (x -= 1) {}
            if (x == 0) {
                return;
            }
        }
        try stream.write(".");
        try stream.write(buf[0..x]);
    }

    /// appendFormat is like Format but appends the textual
    /// representation to b
    pub fn appendFormat(self: Time, stream: var, layout: []const u8) !void {
        const abs_value = self.abs();
        const tz = self.zone();
        const clock_value = self.clock();
        const ddate = self.date();
        var lay = layout;
        while (lay.len != 0) {
            const ctx = nextStdChunk(lay);
            if (ctx.prefix.len != 0) {
                try stream.print("{}", ctx.prefix);
            }
            lay = ctx.suffix;
            switch (ctx.chunk) {
                chunk.none => return,
                chunk.stdYear => {
                    var y = ddate.year;
                    if (y < 0) {
                        y = -y;
                    }
                    try appendInt(stream, @mod(y, 100), 2);
                },
                chunk.stdLongYear => {
                    try appendInt(stream, ddate.year, 4);
                },
                chunk.stdMonth => {
                    try stream.print("{}", ddate.month.string()[0..3]);
                },
                chunk.stdLongMonth => {
                    try stream.print("{}", ddate.month.string());
                },
                chunk.stdNumMonth => {
                    try appendInt(stream, @intCast(isize, @enumToInt(ddate.month)), 0);
                },
                chunk.stdZeroMonth => {
                    try appendInt(stream, @intCast(isize, @enumToInt(ddate.month)), 2);
                },
                chunk.stdWeekDay => {
                    const wk = self.weekday();
                    try stream.print("{}", wk.string()[0..3]);
                },
                chunk.stdLongWeekDay => {
                    const wk = self.weekday();
                    try stream.print("{}", wk.string());
                },
                chunk.stdDay => {
                    try appendInt(stream, ddate.day, 0);
                },
                chunk.stdUnderDay => {
                    if (ddate.day < 10) {
                        try stream.print("{}", " ");
                    }
                    try appendInt(stream, ddate.day, 0);
                },
                chunk.stdZeroDay => {
                    try appendInt(stream, ddate.day, 2);
                },
                chunk.stdHour => {
                    try appendInt(stream, clock_value.hour, 2);
                },
                chunk.stdHour12 => {
                    // Noon is 12PM, midnight is 12AM.
                    var hr = @mod(clock_value.hour, 12);
                    if (hr == 0) {
                        hr = 12;
                    }
                    try appendInt(stream, hr, 0);
                },
                chunk.stdZeroHour12 => {
                    // Noon is 12PM, midnight is 12AM.
                    var hr = @mod(clock_value.hour, 12);
                    if (hr == 0) {
                        hr = 12;
                    }
                    try appendInt(stream, hr, 2);
                },
                chunk.stdMinute => {
                    try appendInt(stream, clock_value.min, 0);
                },
                chunk.stdZeroMinute => {
                    try appendInt(stream, clock_value.min, 2);
                },
                chunk.stdSecond => {
                    try appendInt(stream, clock_value.sec, 0);
                },
                chunk.stdZeroSecond => {
                    try appendInt(stream, clock_value.sec, 2);
                },
                chunk.stdPM => {
                    if (clock_value.hour >= 12) {
                        try stream.print("{}", "PM");
                    } else {
                        try stream.print("{}", "AM");
                    }
                },
                chunk.stdpm => {
                    if (clock_value.hour >= 12) {
                        try stream.print("{}", "pm");
                    } else {
                        try stream.print("{}", "am");
                    }
                },
                chunk.stdISO8601TZ, chunk.stdISO8601ColonTZ, chunk.stdISO8601SecondsTZ, chunk.stdISO8601ShortTZ, chunk.stdISO8601ColonSecondsTZ, chunk.stdNumTZ, chunk.stdNumColonTZ, chunk.stdNumSecondsTz, chunk.stdNumShortTZ, chunk.stdNumColonSecondsTZ => {
                    // Ugly special case. We cheat and take the "Z" variants
                    // to mean "the time zone as formatted for ISO 8601".
                    const cond = tz.offset == 0 and (ctx.chunk.eql(chunk.stdISO8601TZ) or
                        ctx.chunk.eql(chunk.stdISO8601ColonTZ) or
                        ctx.chunk.eql(chunk.stdISO8601SecondsTZ) or
                        ctx.chunk.eql(chunk.stdISO8601ShortTZ) or
                        ctx.chunk.eql(chunk.stdISO8601ColonSecondsTZ));
                    if (cond) {
                        try stream.write("Z");
                    }
                    var z = @divTrunc(tz.offset, 60);
                    var abs_offset = tz.offset;
                    if (z < 0) {
                        try stream.write("-");
                        z = -z;
                        abs_offset = -abs_offset;
                    } else {
                        try stream.write("+");
                    }
                    try appendInt(stream, @divTrunc(z, 60), 2);
                    if (ctx.chunk.eql(chunk.stdISO8601ColonTZ) or
                        ctx.chunk.eql(chunk.stdNumColonTZ) or
                        ctx.chunk.eql(chunk.stdISO8601ColonSecondsTZ) or
                        ctx.chunk.eql(chunk.stdISO8601ColonSecondsTZ) or
                        ctx.chunk.eql(chunk.stdNumColonSecondsTZ))
                    {
                        try stream.write(":");
                    }
                    if (!ctx.chunk.eql(chunk.stdNumShortTZ) and !ctx.chunk.eql(chunk.stdISO8601ShortTZ)) {
                        try appendInt(stream, @mod(z, 60), 2);
                    }
                    if (ctx.chunk.eql(chunk.stdISO8601SecondsTZ) or
                        ctx.chunk.eql(chunk.stdNumSecondsTz) or
                        ctx.chunk.eql(chunk.stdNumColonSecondsTZ) or
                        ctx.chunk.eql(chunk.stdISO8601ColonSecondsTZ))
                    {
                        if (ctx.chunk.eql(chunk.stdNumColonSecondsTZ) or
                            ctx.chunk.eql(chunk.stdISO8601ColonSecondsTZ))
                        {
                            try stream.write(":");
                        }
                        try appendInt(stream, @mod(abs_offset, 60), 2);
                    }
                },
                chunk.stdTZ => {
                    if (tz.name.len != 0) {
                        try stream.print("{}", tz.name);
                        continue;
                    }
                    var z = @divTrunc(tz.offset, 60);
                    if (z < 0) {
                        try stream.write("-");
                        z = -z;
                    } else {
                        try stream.write("+");
                    }
                    try appendInt(stream, @divTrunc(z, 60), 2);
                    try appendInt(stream, @mod(z, 60), 2);
                },
                chunk.stdFracSecond0, chunk.stdFracSecond9 => {
                    try formatNano(stream, @intCast(usize, self.nanosecond()), ctx.args_shift.?, ctx.chunk.eql(chunk.stdFracSecond9));
                },
                else => unreachable,
            }
        }
    }

    pub fn parse(layout: []const u8, value: []const u8, default_location: *Location, local: *Location) !Time {
        return error.TODO;
    }

    /// add adds returns a new Time with duration added to self.
    pub fn add(self: Time, d: Duration) Time {
        var dsec = @divTrunc(d.value, i64(1e9));
        var nsec_value = self.nsec() + @intCast(i32, @mod(d.value, i64(1e9)));
        if (nsec_value >= i32(1e9)) {
            dsec += 1;
            nsec_value -= i32(1e9);
        } else if (nsec_value < 0) {
            dsec -= 1;
            nsec_value += i32(1e9);
        }
        var cp = self;
        var t = &cp;
        t.wall = (t.wall & ~nsec_mask) | @intCast(u64, nsec_value); // update nsec
        t.addSec(dsec);
        if (t.wall & has_monotonic != 0) {
            const te = t.ext + @intCast(i64, d.value);
            if (d.value < 0 and te > t.ext or d.value > 0 and te < t.ext) {
                t.stripMono();
            } else {
                t.ext = te;
            }
        }
        return cp;
    }

    /// sub returns the duration t-u. If the result exceeds the maximum (or minimum)
    /// value that can be stored in a Duration, the maximum (or minimum) duration
    /// will be returned.
    /// To compute t-d for a duration d, use self.add(-d).
    pub fn sub(self: Time, u: Time) Duration {
        if ((self.wall & u.wall & has_monotonic) != 0) {
            const te = self.ext;
            const ue = u.ext;
            var d = Duration.init(te - ue);
            if (d.value < 0 and te > ue) {
                return Duration.maxDuration;
            }
            if (d.value > 0 and te < ue) {
                return Duration.minDuration;
            }
            return d;
        }
        var d = Duration.init((self.sec() - u.sec()) * Duration.Second.value + (self.nsec() - u.nsec()));
        if (u.add(d).equal(self)) {
            return d; // d is correct
        } else if (self.before(u)) {
            return Duration.minDuration; // self - u is negative out of range
        }
        return Duration.maxDuration; // self - u is positive out of range
    }
    fn div(self: Time, d: Duration) divResult {
        var neg = false;
        var nsec_value = self.nsec();
        var sec_value = self.sec();
        if (sec_value < 0) {
            // Operate on absolute value.
            neg = true;
            sec_value = -sec_value;
            if (nsec_value < 0) {
                nsec_value += i32(1e9);
                sec_value -= 1;
            }
        }
        var res = divResult{ .qmod = 0, .r = Duration.init(0) };
        if (d.value < @mod(Duration.Second.value, d.value * 2)) {
            res.qmod = @intCast(isize, @divTrunc(nsec_value, @intCast(i32, d.value))) & 1;
            res.r = Duration.init(@intCast(i64, @mod(nsec_value, @intCast(i32, d.value))));
        } else if (@mod(d.value, Duration.Second.value) == 0) {
            const d1 = @divTrunc(d.value, Duration.Second.value);
            res.qmod = @intCast(isize, @divTrunc(sec_value, d1)) & 1;
            res.r = Duration.init(@mod(sec_value, d1) * Duration.Second.value + @intCast(i64, nsec_value));
        } else {
            var s = @intCast(u64, sec_value);
            var tmp = (s >> 32) * u64(1e9);
            var u_1 = tmp >> 32;
            var u_0 = tmp << 32;
            tmp = (s & 0xFFFFFFFF) * u64(1e9);
            var u_0x = u_0;
            u_0 = u_0 + tmp;
            if (u_0 < u_0x) {
                u_1 += 1;
            }
            u_0x = u_0;
            u_0 = u_0 + @intCast(u64, nsec_value);
            if (u_0 < u_0x) {
                u_1 += 1;
            }
            // Compute remainder by subtracting r<<k for decreasing k.
            // Quotient parity is whether we subtract on last round.
            var d1 = @intCast(u64, d.value);
            while ((d1 >> 63) != 1) {
                d1 <<= 1;
            }
            var d0 = u64(0);
            while (true) {
                res.qmod = 0;
                if (u_1 > d1 or u_1 == d1 and u_0 >= d0) {
                    res.qmod = 1;
                    u_0x = u_0;
                    u_0 = u_0 - d0;
                    if (u_0 > u_0x) {
                        u_1 -= 1;
                    }
                    u_1 -= d1;
                    if (d1 == 0 and d0 == @intCast(u64, d.value)) {
                        break;
                    }
                    d0 >>= 1;
                    d0 |= (d1 & 1) << 63;
                    d1 >>= 1;
                }
                res.r = Duration.init(@intCast(i64, u_0));
            }
            if (neg and res.r.value != 0) {
                // If input was negative and not an exact multiple of d, we computed q, r such that
                //  q*d + r = -t
                // But the right answers are given by -(q-1), d-r:
                //  q*d + r = -t
                //  -q*d - r = t
                //  -(q-1)*d + (d - r) = t
                res.qmod ^= 1;
                res.r = Duration.init(d.value - res.r.value);
            }
            return res;
        }
        return res;
    }

    // these are utility functions that I ported from
    // github.com/jinzhu/now

    pub fn beginningOfMinute(self: Time) Time {
        //TODO: this needs truncate to be implemented.
        return self;
    }

    pub fn beginningOfHour(self: Time) Time {
        const d = self.date();
        const c = self.clock();
        return context.date(
            d.year,
            @intCast(isize, @enumToInt(d.month)),
            d.day,
            c.hour,
            0,
            0,
            0,
            self.loc,
        );
    }

    pub fn beginningOfDay(self: Time) Time {
        const d = self.date();
        return context.date(
            d.year,
            @intCast(isize, @enumToInt(d.month)),
            d.day,
            0,
            0,
            0,
            0,
            self.loc,
        );
    }

    pub fn beginningOfWeek(self: Time) Time {
        var t = self.beginningOfDay();
        const week_day = @intCast(isize, @enumToInt(self.weekday()));
        return self.addDate(0, 0, -week_day);
    }

    pub fn beginningOfMonth(self: Time) Time {
        var d = self.date();
        return context.date(
            d.year,
            @intCast(isize, @enumToInt(d.month)),
            1,
            0,
            0,
            0,
            0,
            self.loc,
        );
    }

    pub fn endOfMonth(self: Time) Time {
        return self.beginningOfMonth().addDate(0, 1, 0).
            add(Duration.init(-Duration.Hour.value));
    }

    fn current_month() [4][7]usize {
        return [4][7]usize{
            [_]usize{0} ** 7,
            [_]usize{0} ** 7,
            [_]usize{0} ** 7,
            [_]usize{0} ** 7,
        };
    }

    pub fn calendar() void {
        var ma = [_][7]usize{
            [_]usize{0} ** 7,
            [_]usize{0} ** 7,
            [_]usize{0} ** 7,
            [_]usize{0} ** 7,
            [_]usize{0} ** 7,
            [_]usize{0} ** 7,
        };
        var m = ma[0..];
        var local = Location.getLocal();
        var current_time = now(&local);
        const today = current_time.day();
        var begin = current_time.beginningOfMonth();
        var end = current_time.endOfMonth();
        const x = begin.date();
        const y = end.date();
        var i: usize = 1;
        var at = @enumToInt(begin.weekday());
        var mx: usize = 0;
        var d: usize = 1;
        while (mx < m.len) : (mx += 1) {
            var a = m[mx][0..];
            while (at < a.len and d <= @intCast(usize, y.day)) : (at += 1) {
                a[at] = d;
                d += 1;
            }
            at = 0;
        }
        warn("\n");
        for (short_days) |ds| {
            warn("{} |", ds);
        }
        warn("\n");
        for (m) |mv, idx| {
            for (mv) |dv, vx| {
                if (idx != 0 and vx == 0 and dv == 0) {
                    // The pre allocated month buffer is lage enough to span 7
                    // weeks.
                    //
                    // we know for a fact at the first week must have at least 1
                    // date,any other week that start with 0 date means we are
                    // past the end of the calendar so no need to keep printing.
                    return;
                }
                if (dv == 0) {
                    warn("    |");
                    continue;
                }
                if (dv == @intCast(usize, today)) {
                    if (dv < 10) {
                        warn(" *{} |", dv);
                    } else {
                        warn("*{} |", dv);
                    }
                } else {
                    if (dv < 10) {
                        warn("  {} |", dv);
                    } else {
                        warn(" {} |", dv);
                    }
                }
            }
            warn("\n");
        }
        warn("\n");
    }
};

const ZoneDetail = struct {
    name: []const u8,
    offset: isize,
};

pub const Duration = struct {
    value: i64,

    pub const Nanosecond = init(1);
    pub const Microsecond = init(1000 * Nanosecond.value);
    pub const Millisecond = init(1000 * Microsecond.value);
    pub const Second = init(1000 * Millisecond.value);
    pub const Minute = init(60 * Second.value);
    pub const Hour = init(60 * Minute.value);

    const minDuration = init(-1 << 63);
    const maxDuration = init((1 << 63) - 1);

    const fracRes = struct {
        nw: usize,
        nv: u64,
    };

    // fmtFrac formats the fraction of v/10**prec (e.g., ".12345") into the
    // tail of buf, omitting trailing zeros. It omits the decimal
    // point too when the fraction is 0. It returns the index where the
    // output bytes begin and the value v/10**prec.

    pub fn init(v: i64) Duration {
        return Duration{ .value = v };
    }
    fn fmtFrac(buf: []u8, value: u64, prec: usize) fracRes {
        // Omit trailing zeros up to and including decimal point.
        var w = buf.len;
        var v = value;
        var i: usize = 0;
        var print: bool = false;
        while (i < prec) : (i += 1) {
            const digit = @mod(v, 10);
            print = print or digit != 0;
            if (print) {
                w -= 1;
                buf[w] = @intCast(u8, digit) + '0';
            }
            v /= 10;
        }
        if (print) {
            w -= 1;
            buf[w] = '.';
        }
        return fracRes{ .nw = w, .nv = v };
    }

    fn fmtInt(buf: []u8, value: u64) usize {
        var w = buf.len;
        var v = value;
        if (v == 0) {
            w -= 1;
            buf[w] = '0';
        } else {
            while (v > 0) {
                w -= 1;
                buf[w] = @intCast(u8, @mod(v, 10)) + '0';
                v /= 10;
            }
        }
        return w;
    }

    pub fn string(self: Duration) []const u8 {
        var buf: [32]u8 = undefined;
        var w = buf.len;
        var u = @intCast(u64, self.value);
        const neg = self.value < 0;
        if (neg) {
            u = @intCast(u64, -self.value);
        }
        if (u < @intCast(u64, Second.value)) {
            // Special case: if duration is smaller than a second,
            // use smaller units, like 1.2ms
            var prec: usize = 0;
            w -= 1;
            buf[w] = 's';
            w -= 1;
            if (u == 0) {
                const s = "0s";
                return s[0..];
            } else if (u < @intCast(u64, Microsecond.value)) {
                // print nanoseconds
                prec = 0;
                buf[w] = 'n';
            } else if (u < @intCast(u64, Millisecond.value)) {
                // print microseconds
                prec = 3;
                // U+00B5 'µ' micro sign == 0xC2 0xB5
                w -= 1;
                mem.copy(u8, buf[w..], "µ");
            } else {
                prec = 6;
                buf[w] = 'm';
            }
            const r = fmtFrac(buf[0..w], u, prec);
            w = r.nw;
            u = r.nv;
            w = fmtInt(buf[0..w], u);
        } else {
            w -= 1;
            buf[w] = 's';
            const r = fmtFrac(buf[0..w], u, 9);
            w = r.nw;
            u = r.nv;
            w = fmtInt(buf[0..w], @mod(u, 60));
            u /= 60;
            // u is now integer minutes
            if (u > 0) {
                w -= 1;
                buf[w] = 'm';
                w = fmtInt(buf[0..w], @mod(u, 60));
                u /= 60;
                // u is now integer hours
                // Stop at hours because days can be different lengths.
                if (u > 0) {
                    w -= 1;
                    buf[w] = 'h';
                    w = fmtInt(buf[0..w], u);
                }
            }
        }
        if (neg) {
            w -= 1;
            buf[w] = '-';
        }
        return buf[w..];
    }

    /// nanoseconds returns the duration as an integer nanosecond count.
    pub fn nanoseconds(self: Duration) i64 {
        return self.value;
    }

    // These methods return float64 because the dominant
    // use case is for printing a floating point number like 1.5s, and
    // a truncation to integer would make them not useful in those cases.
    // Splitting the integer and fraction ourselves guarantees that
    // converting the returned float64 to an integer rounds the same
    // way that a pure integer conversion would have, even in cases
    // where, say, float64(d.Nanoseconds())/1e9 would have rounded
    // differently.

    /// Seconds returns the duration as a floating point number of seconds.
    pub fn seconds(self: Duration) f64 {
        const sec = @divTrunc(self.value, Second.value);
        const nsec = @mod(self.value, Second.value);
        return @intToFloat(f64, sec) + @intToFloat(f64, nsec) / 1e9;
    }

    /// Minutes returns the duration as a floating point number of minutes.
    pub fn minutes(self: Duration) f64 {
        const min = @divTrunc(self.value, Minute.value);
        const nsec = @mod(self.value, Minute.value);
        return @intToFloat(f64, min) + @intToFloat(f64, nsec) / (60 * 1e9);
    }

    // Hours returns the duration as a floating point number of hours.
    pub fn hours(self: Duration) f64 {
        const hour = @divTrunc(self.value, Hour.value);
        const nsec = @mod(self.value, Hour.value);
        return @intToFloat(f64, hour) + @intToFloat(f64, nsec) / (60 * 60 * 1e9);
    }

    /// Truncate returns the result of rounding d toward zero to a multiple of m.
    /// If m <= 0, Truncate returns d unchanged.
    pub fn truncate(self: Duration, m: Duration) Duration {
        if (m.value <= 0) {
            return self;
        }
        return init(self.value - @mod(d.value, m.value));
    }

    // lessThanHalf reports whether x+x < y but avoids overflow,
    // assuming x and y are both positive (Duration is signed).
    fn lessThanHalf(self: Duration, m: Duration) bool {
        const x = @intCast(u64, self.value);
        return x + x < @intCast(u64, m.value);
    }

    // Round returns the result of rounding d to the nearest multiple of m.
    // The rounding behavior for halfway values is to round away from zero.
    // If the result exceeds the maximum (or minimum)
    // value that can be stored in a Duration,
    // Round returns the maximum (or minimum) duration.
    // If m <= 0, Round returns d unchanged.
    pub fn round(self: Duration, m: Duration) Duration {
        if (v.value <= 0) {
            return d;
        }
        var r = init(@mod(self.value, m.value));
        if (self.value < 0) {
            r.value = -r.value;
            if (r.lessThanHalf(m)) {
                return init(self.value + r.value);
            }
            const d = self.value - m.value + r.value;
            if (d < self.value) {
                return init(d);
            }
            return init(minDuration);
        }

        if (r.lessThanHalf(m)) {
            return init(self.value - r.value);
        }
        const d = self.value + m.value - r.value;
        if (d > self.value) {
            return init(d);
        }
        return init(maxDuration);
    }
};

const normRes = struct {
    hi: isize,
    lo: isize,
};

// norm returns nhi, nlo such that
//  hi * base + lo == nhi * base + nlo
//  0 <= nlo < base

fn norm(i: isize, o: isize, base: isize) normRes {
    var hi = i;
    var lo = o;
    if (lo < 0) {
        const n = @divTrunc(-lo - 1, base) + 1;
        hi -= n;
        lo += (n * base);
    }
    if (lo >= base) {
        const n = @divTrunc(lo, base);
        hi += n;
        lo -= (n * base);
    }
    return normRes{ .hi = hi, .lo = lo };
}

/// date returns the Time corresponding to
///  yyyy-mm-dd hh:mm:ss + nsec nanoseconds
/// in the appropriate zone for that time in the given location.
///
/// The month, day, hour, min, sec, and nsec values may be outside
/// their usual ranges and will be normalized during the conversion.
/// For example, October 32 converts to November 1.
///
/// A daylight savings time transition skips or repeats times.
/// For example, in the United States, March 13, 2011 2:15am never occurred,
/// while November 6, 2011 1:15am occurred twice. In such cases, the
/// choice of time zone, and therefore the time, is not well-defined.
/// Date returns a time that is correct in one of the two zones involved
/// in the transition, but it does not guarantee which.
///
/// Date panics if loc is nil.
pub fn date(
    year: isize,
    month: isize,
    day: isize,
    hour: isize,
    min: isize,
    sec: isize,
    nsec: isize,
    loc: *Location,
) Time {
    var v_year = year;
    var v_day = day;
    var v_hour = hour;
    var v_min = min;
    var v_sec = sec;
    var v_nsec = nsec;
    var v_loc = loc;

    // Normalize month, overflowing into year
    var m = month - 1;
    var r = norm(v_year, m, 12);
    v_year = r.hi;
    m = r.lo;
    var v_month = @intToEnum(Month, @intCast(usize, m) + 1);

    // Normalize nsec, sec, min, hour, overflowing into day.
    r = norm(sec, v_nsec, 1e9);
    v_sec = r.hi;
    v_nsec = r.lo;
    r = norm(min, v_sec, 60);
    v_min = r.hi;
    v_sec = r.lo;
    r = norm(v_hour, v_min, 60);
    v_hour = r.hi;
    v_min = r.lo;
    r = norm(v_day, v_hour, 24);
    v_day = r.hi;
    v_hour = r.lo;

    var y = @intCast(u64, @intCast(i64, v_year) - absolute_zero_year);

    // Compute days since the absolute epoch.

    // Add in days from 400-year cycles.
    var n = @divTrunc(y, 400);
    y -= (400 * n);
    var d = days_per_400_years * n;

    // Add in 100-year cycles.
    n = @divTrunc(y, 100);
    y -= 100 * n;
    d += days_per_100_years * n;

    // Add in 4-year cycles.
    n = @divTrunc(y, 4);
    y -= 4 * n;
    d += days_per_4_years * n;

    // Add in non-leap years.
    n = y;
    d += 365 * n;

    // Add in days before this month.
    d += @intCast(u64, daysBefore[@enumToInt(v_month) - 1]);
    if (isLeap(v_year) and @enumToInt(v_month) >= @enumToInt(Month.March)) {
        d += 1; // February 29
    }

    // Add in days before today.
    d += @intCast(u64, v_day - 1);

    // Add in time elapsed today.
    var abs = d * seconds_per_day;

    abs += @intCast(u64, hour * seconds_per_hour + min * seconds_per_minute + sec);
    var unix_value: i64 = undefined;
    _ = @addWithOverflow(i64, @intCast(i64, abs), (absolute_to_internal + internal_to_unix), &unix_value);
    // Look for zone offset for t, so we can adjust to UTC.
    // The lookup function expects UTC, so we pass t in the
    // hope that it will not be too close to a zone transition,
    // and then adjust if it is.
    var zn = loc.lookup(unix_value);
    if (zn.offset != 0) {
        const utc_value = unix_value - @intCast(i64, zn.offset);
        if (utc_value < zn.start) {
            zn = loc.lookup(zn.start - 1);
        } else if (utc_value >= zn.end) {
            zn = loc.lookup(zn.end);
        }
        unix_value -= @intCast(i64, zn.offset);
    }
    return unixTimeWithLoc(unix_value, @intCast(i32, v_nsec), loc);
}

/// ISO 8601 year and week number
pub const ISOWeek = struct {
    year: isize,
    week: isize,
};

pub const Clock = struct {
    hour: isize,
    min: isize,
    sec: isize,

    fn absClock(abs: u64) Clock {
        var sec = @intCast(isize, abs % seconds_per_day);
        var hour = @divTrunc(sec, seconds_per_hour);
        sec -= (hour * seconds_per_hour);
        var min = @divTrunc(sec, seconds_per_minute);
        sec -= (min * seconds_per_minute);
        return Clock{ .hour = hour, .min = min, .sec = sec };
    }
};

fn absWeekday(abs: u64) Weekday {
    const s = @mod(abs + @intCast(u64, @enumToInt(Weekday.Monday)) * seconds_per_day, seconds_per_week);
    const w = s / seconds_per_day;
    return @intToEnum(Weekday, @intCast(usize, w));
}

pub const Month = enum(usize) {
    January = 1,
    February = 2,
    March = 3,
    April = 4,
    May = 5,
    June = 6,
    July = 7,
    August = 8,
    September = 9,
    October = 10,
    November = 11,
    December = 12,

    pub fn string(self: Month) []const u8 {
        const m = @enumToInt(self);
        if (@enumToInt(Month.January) <= m and m <= @enumToInt(Month.December)) {
            return months[m - 1];
        }
        unreachable;
    }

    pub fn format(
        self: Month,
        comptime fmt: []const u8,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        try output(context, self.string());
    }
};

pub const DateDetail = struct {
    year: isize,
    month: Month,
    day: isize,
    yday: isize,
};

fn absDate(abs: u64, full: bool) DateDetail {
    var details: DateDetail = undefined;
    // Split into time and day.
    var d = abs / seconds_per_day;

    // Account for 400 year cycles.
    var n = d / days_per_400_years;
    var y = 400 * n;
    d -= days_per_400_years * n;

    // Cut off 100-year cycles.
    // The last cycle has one extra leap year, so on the last day
    // of that year, day / days_per_100_years will be 4 instead of 3.
    // Cut it back down to 3 by subtracting n>>2.
    n = d / days_per_100_years;
    n -= n >> 2;
    y += 100 * n;
    d -= days_per_100_years * n;

    // Cut off 4-year cycles.
    // The last cycle has a missing leap year, which does not
    // affect the computation.
    n = d / days_per_4_years;
    y += 4 * n;
    d -= days_per_4_years * n;

    // Cut off years within a 4-year cycle.
    // The last year is a leap year, so on the last day of that year,
    // day / 365 will be 4 instead of 3. Cut it back down to 3
    // by subtracting n>>2.
    n = d / 365;
    n -= n >> 2;
    y += n;
    d -= 365 * n;
    details.year = @intCast(isize, @intCast(i64, y) + absolute_zero_year);
    details.yday = @intCast(isize, d);
    if (!full) {
        return details;
    }
    details.day = details.yday;
    if (isLeap(details.year)) {
        if (details.day > (31 + 29 - 1)) {
            // After leap day; pretend it wasn't there.
            details.day -= 1;
        } else if (details.day == (31 + 29 - 1)) {
            // Leap day.
            details.month = Month.February;
            details.day = 29;
            return details;
        }
    }

    // Estimate month on assumption that every month has 31 days.
    // The estimate may be too low by at most one month, so adjust.
    var month = @intCast(usize, details.day) / usize(31);
    const end = daysBefore[month + 1];
    var begin: isize = 0;
    if (details.day >= end) {
        month += 1;
        begin = end;
    } else {
        begin = daysBefore[month];
    }
    month += 1;
    details.day = details.day - begin + 1;
    details.month = @intToEnum(Month, month);
    return details;
}

// daysBefore[m] counts the number of days in a non-leap year
// before month m begins. There is an entry for m=12, counting
// the number of days before January of next year (365).

const daysBefore = [_]isize{
    0,
    31,
    31 + 28,
    31 + 28 + 31,
    31 + 28 + 31 + 30,
    31 + 28 + 31 + 30 + 31,
    31 + 28 + 31 + 30 + 31 + 30,
    31 + 28 + 31 + 30 + 31 + 30 + 31,
    31 + 28 + 31 + 30 + 31 + 30 + 31 + 31,
    31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30,
    31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31,
    31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30,
    31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30 + 31,
};

fn isLeap(year: isize) bool {
    return @mod(year, 4) == 0 and (@mod(year, 100) != 0 or @mod(year, 100) == 0);
}

const months = [_][]const u8{
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
};

pub const Weekday = enum(usize) {
    Sunday,
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday,

    pub fn string(self: Weekday) []const u8 {
        const d = @enumToInt(self);
        if (@enumToInt(Weekday.Sunday) <= d and d <= @enumToInt(Weekday.Saturday)) {
            return days[d];
        }
        unreachable;
    }

    pub fn format(
        self: Weekday,
        comptime fmt: []const u8,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        try output(context, self.string());
    }
};

const days = [_][]const u8{
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
};

/// now returns the current local time and assigns the retuned time to use
/// local as location data.
pub fn now(local: *Location) Time {
    const bt = timeNow();
    const sec = (bt.sec + unix_to_internal) - min_wall;
    if ((@intCast(u64, sec) >> 33) != 0) {
        return Time{
            .wall = @intCast(u64, bt.nsec),
            .ext = sec + min_wall,
            .loc = local,
        };
    }
    return Time{
        .wall = has_monotonic | (@intCast(u64, sec) << nsec_shift) | @intCast(u64, bt.nsec),
        .ext = @intCast(i64, bt.mono),
        .loc = local,
    };
}

fn unixTime(sec: i64, nsec: i32) Time {
    var local = getLocal();
    return unixTimeWithLoc(sec, nsec, local);
}

fn unixTimeWithLoc(sec: i64, nsec: i32, loc: *Location) Time {
    return Time{
        .wall = @intCast(u64, nsec),
        .ext = sec + unix_to_internal,
        .loc = loc,
    };
}

pub fn unix(sec: i64, nsec: i64, local: *Location) Time {
    var x = sec;
    var y = nsec;
    if (nsec < 0 or nsec >= i64(1e9)) {
        const n = @divTrunc(nsec, i64(1e9));
        x += n;
        y -= (n * i64(1e9));
        if (y < 0) {
            y += i64(1e9);
            x -= 1;
        }
    }
    return unixTimeWithLoc(x, @intCast(i32, y), local);
}

const bintime = struct {
    sec: isize,
    nsec: isize,
    mono: u64,
};

fn timeNow() bintime {
    switch (builtin.os) {
        Os.linux => {
            var ts: posix.timespec = undefined;
            const err = posix.clock_gettime(posix.CLOCK_REALTIME, &ts);
            std.debug.assert(err == 0);
            return bintime{ .sec = ts.tv_sec, .nsec = ts.tv_nsec, .mono = clockNative() };
        },
        Os.macosx, Os.ios => {
            var tv: darwin.timeval = undefined;
            var err = darwin.gettimeofday(&tv, null);
            std.debug.assert(err == 0);
            return bintime{ .sec = tv.tv_sec, .nsec = tv.tv_usec, .mono = clockNative() };
        },
        else => @compileError("Unsupported OS"),
    }
}

const clockNative = switch (builtin.os) {
    Os.windows => clockWindows,
    Os.linux => clockLinux,
    Os.macosx, Os.ios => clockDarwin,
    else => @compileError("Unsupported OS"),
};

fn clockWindows() u64 {
    var result: i64 = undefined;
    var err = windows.QueryPerformanceCounter(&result);
    debug.assert(err != windows.FALSE);
    return @intCast(u64, result);
}

fn clockDarwin() u64 {
    return darwin.mach_absolute_time();
}

fn clockLinux() u64 {
    var ts: posix.timespec = undefined;
    var result = posix.clock_gettime(monotonic_clock_id, &ts);
    debug.assert(posix.getErrno(result) == 0);
    return @intCast(u64, ts.tv_sec) * u64(1000000000) + @intCast(u64, ts.tv_nsec);
}

// These are predefined layouts for use in Time.Format and time.Parse.
// The reference time used in the layouts is the specific time:
//  Mon Jan 2 15:04:05 MST 2006
// which is Unix time 1136239445. Since MST is GMT-0700,
// the reference time can be thought of as
//  01/02 03:04:05PM '06 -0700
// To define your own format, write down what the reference time would look
// like formatted your way; see the values of constants like ANSIC,
// StampMicro or Kitchen for examples. The model is to demonstrate what the
// reference time looks like so that the Format and Parse methods can apply
// the same transformation to a general time value.
//
// Some valid layouts are invalid time values for time.Parse, due to formats
// such as _ for space padding and Z for zone information.
//
// Within the format string, an underscore _ represents a space that may be
// replaced by a digit if the following number (a day) has two digits; for
// compatibility with fixed-width Unix time formats.
//
// A decimal point followed by one or more zeros represents a fractional
// second, printed to the given number of decimal places. A decimal point
// followed by one or more nines represents a fractional second, printed to
// the given number of decimal places, with trailing zeros removed.
// When parsing (only), the input may contain a fractional second
// field immediately after the seconds field, even if the layout does not
// signify its presence. In that case a decimal point followed by a maximal
// series of digits is parsed as a fractional second.
//
// Numeric time zone offsets format as follows:
//  -0700  ±hhmm
//  -07:00 ±hh:mm
//  -07    ±hh
// Replacing the sign in the format with a Z triggers
// the ISO 8601 behavior of printing Z instead of an
// offset for the UTC zone. Thus:
//  Z0700  Z or ±hhmm
//  Z07:00 Z or ±hh:mm
//  Z07    Z or ±hh
//
// The recognized day of week formats are "Mon" and "Monday".
// The recognized month formats are "Jan" and "January".
//
// Text in the format string that is not recognized as part of the reference
// time is echoed verbatim during Format and expected to appear verbatim
// in the input to Parse.
//
// The executable example for Time.Format demonstrates the working
// of the layout string in detail and is a good reference.
//
// Note that the RFC822, RFC850, and RFC1123 formats should be applied
// only to local times. Applying them to UTC times will use "UTC" as the
// time zone abbreviation, while strictly speaking those RFCs require the
// use of "GMT" in that case.
// In general RFC1123Z should be used instead of RFC1123 for servers
// that insist on that format, and RFC3339 should be preferred for new protocols.
// RFC3339, RFC822, RFC822Z, RFC1123, and RFC1123Z are useful for formatting;
// when used with time.Parse they do not accept all the time formats
// permitted by the RFCs.
// The RFC3339Nano format removes trailing zeros from the seconds field
// and thus may not sort correctly once formatted.

pub const ANSIC = "Mon Jan _2 15:04:05 2006";
pub const UnixDate = "Mon Jan _2 15:04:05 MST 2006";
pub const RubyDate = "Mon Jan 02 15:04:05 -0700 2006";
pub const RFC822 = "02 Jan 06 15:04 MST";
pub const RFC822Z = "02 Jan 06 15:04 -0700"; // RFC822 with numeric zone
pub const RFC850 = "Monday, 02-Jan-06 15:04:05 MST";
pub const RFC1123 = "Mon, 02 Jan 2006 15:04:05 MST";
pub const RFC1123Z = "Mon, 02 Jan 2006 15:04:05 -0700"; // RFC1123 with numeric zone
pub const RFC3339 = "2006-01-02T15:04:05Z07:00";
pub const RFC3339Nano = "2006-01-02T15:04:05.999999999Z07:00";
pub const Kitchen = "3:04PM";
// Handy time stamps.
pub const Stamp = "Jan _2 15:04:05";
pub const StampMilli = "Jan _2 15:04:05.000";
pub const StampMicro = "Jan _2 15:04:05.000000";
pub const StampNano = "Jan _2 15:04:05.000000000";

pub const DefaultFormat = "2006-01-02 15:04:05.999999999 -0700 MST";

pub const chunk = enum {
    none,
    stdLongMonth, // "January"
    stdMonth, // "Jan"
    stdNumMonth, // "1"
    stdZeroMonth, // "01"
    stdLongWeekDay, // "Monday"
    stdWeekDay, // "Mon"
    stdDay, // "2"
    stdUnderDay, // "_2"
    stdZeroDay, // "02"
    stdHour, // "15"
    stdHour12, // "3"
    stdZeroHour12, // "03"
    stdMinute, // "4"
    stdZeroMinute, // "04"
    stdSecond, // "5"
    stdZeroSecond, // "05"
    stdLongYear, // "2006"
    stdYear, // "06"
    stdPM, // "PM"
    stdpm, // "pm"
    stdTZ, // "MST"
    stdISO8601TZ, // "Z0700"  // prints Z for UTC
    stdISO8601SecondsTZ, // "Z070000"
    stdISO8601ShortTZ, // "Z07"
    stdISO8601ColonTZ, // "Z07:00" // prints Z for UTC
    stdISO8601ColonSecondsTZ, // "Z07:00:00"
    stdNumTZ, // "-0700"  // always numeric
    stdNumSecondsTz, // "-070000"
    stdNumShortTZ, // "-07"    // always numeric
    stdNumColonTZ, // "-07:00" // always numeric
    stdNumColonSecondsTZ, // "-07:00:00"
    stdFracSecond0, // ".0", ".00", ... , trailing zeros included
    stdFracSecond9, // ".9", ".99", ..., trailing zeros omitted

    stdNeedDate, // need month, day, year
    stdNeedClock, // need hour, minute, second
    stdArgShift, // extra argument in high bits, above low stdArgShift

    fn eql(self: chunk, other: chunk) bool {
        return @enumToInt(self) == @enumToInt(other);
    }
};

// startsWithLowerCase reports whether the string has a lower-case letter at the beginning.
// Its purpose is to prevent matching strings like "Month" when looking for "Mon".

fn startsWithLowerCase(str: []const u8) bool {
    if (str.len == 0) {
        return false;
    }
    const c = str[0];
    return 'a' <= c and c <= 'z';
}

const chunkResult = struct {
    prefix: []const u8,
    suffix: []const u8,
    chunk: chunk,
    args_shift: ?usize,
};

const std0x = [_]chunk{
    chunk.stdZeroMonth,
    chunk.stdZeroDay,
    chunk.stdZeroHour12,
    chunk.stdZeroMinute,
    chunk.stdZeroSecond,
    chunk.stdYear,
};

fn nextStdChunk(layout: []const u8) chunkResult {
    var i: usize = 0;
    while (i < layout.len) : (i += 1) {
        switch (layout[i]) {
            'J' => { // January, Jan
                if ((layout.len >= i + 3) and mem.eql(u8, layout[i .. i + 3], "Jan")) {
                    if ((layout.len >= i + 7) and mem.eql(u8, layout[i .. i + 7], "January")) {
                        return chunkResult{
                            .prefix = layout[0..i],
                            .chunk = chunk.stdLongMonth,
                            .suffix = layout[i + 7 ..],
                            .args_shift = null,
                        };
                    }
                    if (!startsWithLowerCase(layout[i + 3 ..])) {
                        return chunkResult{
                            .prefix = layout[0..i],
                            .chunk = chunk.stdMonth,
                            .suffix = layout[i + 3 ..],
                            .args_shift = null,
                        };
                    }
                }
            },
            'M' => { // Monday, Mon, MST
                if (layout.len >= 1 + 3) {
                    if (mem.eql(u8, layout[i .. i + 3], "Mon")) {
                        if ((layout.len >= i + 6) and mem.eql(u8, layout[i .. i + 6], "Monday")) {
                            return chunkResult{
                                .prefix = layout[0..i],
                                .chunk = chunk.stdLongWeekDay,
                                .suffix = layout[i + 6 ..],
                                .args_shift = null,
                            };
                        }
                        if (!startsWithLowerCase(layout[i + 3 ..])) {
                            return chunkResult{
                                .prefix = layout[0..i],
                                .chunk = chunk.stdWeekDay,
                                .suffix = layout[i + 3 ..],
                                .args_shift = null,
                            };
                        }
                    }
                    if (mem.eql(u8, layout[i .. i + 3], "MST")) {
                        return chunkResult{
                            .prefix = layout[0..i],
                            .chunk = chunk.stdTZ,
                            .suffix = layout[i + 3 ..],
                            .args_shift = null,
                        };
                    }
                }
            },
            '0' => {
                if (layout.len >= i + 2 and '1' <= layout[i + 1] and layout[i + 1] <= '6') {
                    const x = layout[i + 1] - '1';
                    return chunkResult{
                        .prefix = layout[0..i],
                        .chunk = std0x[x],
                        .suffix = layout[i + 2 ..],
                        .args_shift = null,
                    };
                }
            },
            '1' => { // 15, 1
                if (layout.len >= i + 2 and layout[i + 1] == '5') {
                    return chunkResult{
                        .prefix = layout[0..i],
                        .chunk = chunk.stdHour,
                        .suffix = layout[i + 2 ..],
                        .args_shift = null,
                    };
                }
                return chunkResult{
                    .prefix = layout[0..i],
                    .chunk = chunk.stdNumMonth,
                    .suffix = layout[i + 1 ..],
                    .args_shift = null,
                };
            },
            '2' => { // 2006, 2
                if (layout.len >= i + 4 and mem.eql(u8, layout[i .. i + 4], "2006")) {
                    return chunkResult{
                        .prefix = layout[0..i],
                        .chunk = chunk.stdLongYear,
                        .suffix = layout[i + 4 ..],
                        .args_shift = null,
                    };
                }
                return chunkResult{
                    .prefix = layout[0..i],
                    .chunk = chunk.stdDay,
                    .suffix = layout[i + 1 ..],
                    .args_shift = null,
                };
            },
            '_' => { // _2, _2006
                if (layout.len >= i + 4 and layout[i + 1] == '2') {
                    //_2006 is really a literal _, followed by stdLongYear
                    if (layout.len >= i + 5 and mem.eql(u8, layout[i + 1 .. i + 5], "2006")) {
                        return chunkResult{
                            .prefix = layout[0..i],
                            .chunk = chunk.stdLongYear,
                            .suffix = layout[i + 5 ..],
                            .args_shift = null,
                        };
                    }
                    return chunkResult{
                        .prefix = layout[0..i],
                        .chunk = chunk.stdUnderDay,
                        .suffix = layout[i + 2 ..],
                        .args_shift = null,
                    };
                }
            },
            '3' => {
                return chunkResult{
                    .prefix = layout[0..i],
                    .chunk = chunk.stdHour12,
                    .suffix = layout[i + 1 ..],
                    .args_shift = null,
                };
            },
            '4' => {
                return chunkResult{
                    .prefix = layout[0..i],
                    .chunk = chunk.stdMinute,
                    .suffix = layout[i + 1 ..],
                    .args_shift = null,
                };
            },
            '5' => {
                return chunkResult{
                    .prefix = layout[0..i],
                    .chunk = chunk.stdSecond,
                    .suffix = layout[i + 1 ..],
                    .args_shift = null,
                };
            },
            'P' => { // PM
                if (layout.len >= i + 2 and layout[i + 1] == 'M') {
                    return chunkResult{
                        .prefix = layout[0..i],
                        .chunk = chunk.stdPM,
                        .suffix = layout[i + 2 ..],
                        .args_shift = null,
                    };
                }
            },
            'p' => { // pm
                if (layout.len >= i + 2 and layout[i + 1] == 'm') {
                    return chunkResult{
                        .prefix = layout[0..i],
                        .chunk = chunk.stdpm,
                        .suffix = layout[i + 2 ..],
                        .args_shift = null,
                    };
                }
            },
            '-' => {
                if (layout.len >= i + 7 and mem.eql(u8, layout[i .. i + 7], "-070000")) {
                    return chunkResult{
                        .prefix = layout[0..i],
                        .chunk = chunk.stdNumSecondsTz,
                        .suffix = layout[i + 7 ..],
                        .args_shift = null,
                    };
                }
                if (layout.len >= i + 9 and mem.eql(u8, layout[i .. i + 9], "-07:00:00")) {
                    return chunkResult{
                        .prefix = layout[0..i],
                        .chunk = chunk.stdNumColonSecondsTZ,
                        .suffix = layout[i + 9 ..],
                        .args_shift = null,
                    };
                }
                if (layout.len >= i + 5 and mem.eql(u8, layout[i .. i + 5], "-0700")) {
                    return chunkResult{
                        .prefix = layout[0..i],
                        .chunk = chunk.stdNumTZ,
                        .suffix = layout[i + 5 ..],
                        .args_shift = null,
                    };
                }
                if (layout.len >= i + 6 and mem.eql(u8, layout[i .. i + 6], "-07:00")) {
                    return chunkResult{
                        .prefix = layout[0..i],
                        .chunk = chunk.stdNumColonTZ,
                        .suffix = layout[i + 6 ..],
                        .args_shift = null,
                    };
                }
                if (layout.len >= i + 3 and mem.eql(u8, layout[i .. i + 3], "-07")) {
                    return chunkResult{
                        .prefix = layout[0..i],
                        .chunk = chunk.stdNumShortTZ,
                        .suffix = layout[i + 3 ..],
                        .args_shift = null,
                    };
                }
            },
            'Z' => { // Z070000, Z07:00:00, Z0700, Z07:00,
                if (layout.len >= i + 7 and mem.eql(u8, layout[i .. i + 7], "Z070000")) {
                    return chunkResult{
                        .prefix = layout[0..i],
                        .chunk = chunk.stdISO8601SecondsTZ,
                        .suffix = layout[i + 7 ..],
                        .args_shift = null,
                    };
                }
                if (layout.len >= i + 9 and mem.eql(u8, layout[i .. i + 9], "Z07:00:00")) {
                    return chunkResult{
                        .prefix = layout[0..i],
                        .chunk = chunk.stdISO8601ColonSecondsTZ,
                        .suffix = layout[i + 9 ..],
                        .args_shift = null,
                    };
                }
                if (layout.len >= i + 5 and mem.eql(u8, layout[i .. i + 5], "Z0700")) {
                    return chunkResult{
                        .prefix = layout[0..i],
                        .chunk = chunk.stdISO8601TZ,
                        .suffix = layout[i + 5 ..],
                        .args_shift = null,
                    };
                }
                if (layout.len >= i + 6 and mem.eql(u8, layout[i .. i + 6], "Z07:00")) {
                    return chunkResult{
                        .prefix = layout[0..i],
                        .chunk = chunk.stdISO8601ColonTZ,
                        .suffix = layout[i + 6 ..],
                        .args_shift = null,
                    };
                }
                if (layout.len >= i + 3 and mem.eql(u8, layout[i .. i + 3], "Z07")) {
                    return chunkResult{
                        .prefix = layout[0..i],
                        .chunk = chunk.stdISO8601ShortTZ,
                        .suffix = layout[i + 6 ..],
                        .args_shift = null,
                    };
                }
            },
            '.' => { // .000 or .999 - repeated digits for fractional seconds.
                if (i + 1 < layout.len and (layout[i + 1] == '0' or layout[i + 1] == '9')) {
                    const ch = layout[i + 1];
                    var j = i + 1;
                    while (j < layout.len and layout[j] == ch) : (j += 1) {}
                    if (!isDigit(layout, j)) {
                        var st = chunk.stdFracSecond0;
                        if (layout[i + 1] == '9') {
                            st = chunk.stdFracSecond9;
                        }
                        return chunkResult{
                            .prefix = layout[0..i],
                            .chunk = st,
                            .suffix = layout[j..],
                            .args_shift = j - (i + 1),
                        };
                    }
                }
            },
            else => {},
        }
    }

    return chunkResult{
        .prefix = layout,
        .chunk = chunk.none,
        .suffix = "",
        .args_shift = null,
    };
}

fn isDigit(s: []const u8, i: usize) bool {
    if (s.len <= i) {
        return false;
    }
    const c = s[i];
    return '0' <= c and c <= '9';
}

const long_day_names = [][]const u8{
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
};

const short_day_names = [][]const u8{
    "Sun",
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
};

const short_month_names = [][]const u8{
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
};

const long_month_names = [][]const u8{
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
};

// match reports whether s1 and s2 match ignoring case.
// It is assumed s1 and s2 are the same length.

fn match(s1: []const u8, s2: []const u8) bool {
    if (s1.len != s2.len) {
        return false;
    }
    var i: usize = 0;
    while (i < s1.len) : (i += 1) {
        var c1 = s1[i];
        var c2 = s2[i];
        if (c1 != c2) {
            c1 |= ('a' - 'A');
            c2 |= ('a' - 'A');
            if (c1 != c2 or c1 < 'a' or c1 > 'z') {
                return false;
            }
        }
    }
    return true;
}

fn lookup(tab: [][]const u8, val: []const u8) !usize {
    for (tab) |v, i| {
        if (val.len >= v.len and match(val[0..v.len], v)) {
            return i;
        }
    }
    return error.BadValue;
}

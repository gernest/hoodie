const std = @import("std");
const unicode = std.unicode;
const mem = std.mem;
const warn = std.debug.warn;

pub const MatchError = error{BadPattern};

pub fn match(pattern_string: []const u8, name_string: []const u8) MatchError!bool {
    var pattern = pattern_string;
    var name = name_string;
    PATTERN: while (pattern.len > 0) {
        const s = scanChunk(pattern);
        var star = s.star;
        var chunk = s.chunk;
        pattern = s.rest;
        if (star and chunk.len == 0) {
            return !contains(name, "/");
        }
        const c = try matchChunk(chunk, name);
        if (c.ok and (c.rest.len == 0 or pattern.len > 0)) {
            name = c.rest;
            continue;
        }
        if (star) {
            var i: usize = 0;
            while (i < name.len and name[i] != '/') : (i += 1) {
                const cc = try matchChunk(chunk, name[i + 1 ..]);
                if (cc.ok) {
                    if (pattern.len == 0 and cc.rest.len > 0) {
                        continue;
                    }
                    name = cc.rest;
                    continue :PATTERN;
                }
            }
        }
        return false;
    }
    return name.len == 0;
}

const ScanChunkResult = struct {
    star: bool,
    chunk: []const u8,
    rest: []const u8,
};

fn scanChunk(pattern_string: []const u8) ScanChunkResult {
    var pattern = pattern_string;
    var star = false;
    while (pattern.len > 0 and pattern[0] == '*') {
        pattern = pattern[1..];
        star = true;
    }
    var in_range = false;
    var i: usize = 0;
    scan: while (i < pattern.len) : (i += 1) {
        switch (pattern[i]) {
            '\\' => {
                if (i + 1 < pattern.len) {
                    i += 1;
                }
            },
            '[' => {
                in_range = true;
            },
            ']' => {
                in_range = false;
            },
            '*' => {
                if (in_range) {
                    break :scan;
                }
            },
            else => {},
        }
    }
    return ScanChunkResult{
        .star = star,
        .chunk = pattern[0..i],
        .rest = pattern[i..],
    };
}
const MatchChunkResult = struct {
    rest: []const u8,
    ok: bool,
};

fn matchChunk(chunks: []const u8, src: []const u8) MatchError!MatchChunkResult {
    var chunk = chunks;
    var s = src;
    while (chunk.len > 0) {
        if (s.len == 0) {
            return MatchChunkResult{ .rest = "", .ok = false };
        }
        switch (chunk[0]) {
            '[' => {
                const r = unicode.utf8Decode(s) catch |err| {
                    return error.BadPattern;
                };
                const n = runeLength(r) catch |e| {
                    return error.BadPattern;
                };
                s = s[n..];
                chunk = chunk[1..];
                var not_negated = true;
                if (chunk.len > 0 and chunk[0] == '^') {
                    not_negated = false;
                    chunk = chunk[1..];
                }
                var matched = false;
                var mrange: usize = 0;
                while (true) {
                    if (chunk.len > 0 and chunk[0] == ']' and mrange > 0) {
                        chunk = chunk[1..];
                        break;
                    }
                    const e = try getEsc(chunk);
                    var lo = e.rune;
                    chunk = e.chunk;
                    var hi = lo;
                    if (chunk[0] == '-') {
                        const ee = try getEsc(chunk[1..]);
                        hi = ee.rune;
                        chunk = ee.chunk;
                    }
                    if (lo <= r and r <= hi) {
                        matched = true;
                    }
                    mrange += 1;
                }
                if (matched != not_negated) {
                    return MatchChunkResult{ .rest = "", .ok = false };
                }
            },
            '?' => {
                if (s[0] == '/') {
                    return MatchChunkResult{ .rest = "", .ok = false };
                }
                const r = unicode.utf8Decode(s) catch |err| {
                    return error.BadPattern;
                };
                const n = runeLength(r) catch |e| {
                    return error.BadPattern;
                };
                s = s[n..];
                chunk = chunk[1..];
            },
            '\\' => {
                chunk = chunk[1..];
                if (chunk.len == 0) {
                    return error.BadPattern;
                }
                if (chunk[0] != s[0]) {
                    return MatchChunkResult{ .rest = "", .ok = false };
                }
                s = s[1..];
                chunk = chunk[1..];
            },
            else => {
                if (chunk[0] != s[0]) {
                    return MatchChunkResult{ .rest = "", .ok = false };
                }
                s = s[1..];
                chunk = chunk[1..];
            },
        }
    }
    return MatchChunkResult{ .rest = s, .ok = true };
}

const EscapeResult = struct {
    rune: u32,
    chunk: []const u8,
};

fn getEsc(chunk: []const u8) !EscapeResult {
    if (chunk.len == 0 or chunk[0] == '-' or chunk[0] == ']') {
        return error.BadPattern;
    }
    var e = EscapeResult{ .rune = 0, .chunk = chunk };
    if (chunk[0] == '\\') {
        e.chunk = chunk[1..];
        if (e.chunk.len == 0) {
            return error.BadPattern;
        }
    }
    const r = unicode.utf8Decode(e.chunk) catch |err| {
        return error.BadPattern;
    };
    const n = runeLength(r) catch |err| {
        return error.BadPattern;
    };
    e.chunk = e.chunk[n..];
    if (e.chunk.len == 0) {
        return error.BadPattern;
    }
    e.rune = r;
    return e;
}

fn runeLength(rune: u32) !usize {
    return @intCast(usize, try unicode.utf8CodepointSequenceLength(rune));
}

fn contains(s: []const u8, needle: []const u8) bool {
    return mem.indexOf(u8, s, needle) == null;
}

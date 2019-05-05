const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const utf8 = @import("../unicode/utf8/index.zig");

pub fn lastIndexFunc(input: []const u8, f: fn (rune: i32) bool) anyerror!?usize {
    return lastIndexFuncInternal(input, f, true);
}

fn lastIndexFuncInternal(input: []const u8, f: fn (rune: i32) bool, truthy: bool) anyerror!?usize {
    var idx = @intCast(isize, input.len);
    while (idx > 0) {
        const r = try utf8.decodeLastRune(input[0..@intCast(usize, idx)]);
        idx -= @intCast(isize, r.size);
        if (f(r.value) == truthy) {
            return @intCast(usize, idx);
        }
    }
    return null;
}

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

    pub fn init(a: *Allocator, pattern: []const u8) !Self {
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

    pub fn deinit(self: *Self) void {
        if (self.pattern.len > 0) {
            self.a.free(self.good_suffix_skip);
        }
    }

    pub fn next(self: *Self, text: []const u8) ?usize {
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

pub const SingleReplacer = struct {
    find: StringFinder,
    old: []const u8,
    new: []const u8,

    replacer: Replacer,

    pub fn init(a: *Allocator, old: []const u8, new: []const u8) !SingleReplacer {
        return SingleReplacer{
            .old = old,
            .new = new,
            .find = try StringFinder.init(a, old),
            .replacer = Replacer{ .replaceFn = replaceFn },
        };
    }

    pub fn deinit(self: *SingleReplacer) void {
        self.find.deinit();
    }

    pub fn replaceFn(replace_ctx: *Replacer, s: []const u8, buf: *std.Buffer) anyerror!void {
        const self = @fieldParentPtr(SingleReplacer, "replacer", replace_ctx);
        var i: usize = 0;
        var matched = false;
        top: while (true) {
            if ((&self.find).next(s[i..])) |match| {
                matched = true;
                try buf.append(s[i .. i + match]);
                try buf.append(self.new);
                i += match + self.old.len;
                continue :top;
            }
            break;
        }
        if (!matched) {
            try buf.append(s);
        } else {
            try buf.append(s[i..]);
        }
    }
};

pub const Replacer = struct {
    replaceFn: fn (*Replacer, []const u8, *std.Buffer) anyerror!void,

    pub fn replace(self: *Replacer, s: []const u8, out: *std.Buffer) anyerror!void {
        return self.replaceFn(self, s, out);
    }
};

pub const StringReplacer = struct {
    impl: ReplaceImpl,

    const ReplaceImpl = union {
        Single: SingleReplacer,
        Generic: GenericReplacer,
    };

    pub fn init(a: *Allocator, old_new: [][]const u8) !StringReplacer {
        if (old_new.len == 2 and old_new[0].len > 1) {
            return StringReplacer{
                .impl = ReplaceImpl{
                    .Single = try SingleReplacer.init(a, old_new[0], old_new[1]),
                },
            };
        }
        return error.NotImplemenedYet;
    }

    fn replace(self: *StringReplacer, s: []const u8, out: *std.Buffer) anyerror!void {
        switch (self.impl) {
            ReplaceImpl.Single => |*value| {
                const r = &value.replacer;
                return try r.replace(s, out);
            },
            ReplaceImpl.Generic => |*value| {
                const r = &value.replacer;
                return try r.replace(s, out);
            },
            else => unreachable,
        }
    }
};

pub const GenericReplacer = struct {};

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

pub const ByteReplacer = struct {
    matrix: [256]usize,
    replacer: Replacer,

    pub fn init(old_new: [][]const u8) ByteReplacer {
        var r: [256]u8 = undefined;
        for (r) |*v, i| {
            v.* = @intCast(u8, i);
        }
        var i = old_new.len - 2;
        while (i > 0) {
            const o = old_new[i][0];
            const n = old_new[i + 1][0];
            r[o] = n;
        }
        return ByteReplacer{
            .matrix = r,
            .replacer = Replacer{ .replaceFn = replaceFn },
        };
    }

    pub fn replaceFn(replace_ctx: *Replacer, s: []const u8, buf: *std.Buffer) anyerror!void {
        const self = @fieldParentPtr(ByteReplacer, "replacer", replace_ctx);
        var i: usize = 0;
        while (i < s.len) : (i += 1) {
            const b = s[i];
            if (self.matrix[b] != b) {
                try buf.appendByte(self.matrix[b]);
            } else {
                try buf.appendByte(b);
            }
        }
    }
};

pub const ByteStringReplacer = struct {
    replacements: [256]?[]const u8,
    replacer: Replacer,

    pub fn init(old_new: [][]const u8) ByteStringReplacer {
        var r: [356]?[]const u8 = undefined;
        var i = old_new.len - 2;
        while (i >= 0) {
            const o = old_new[i][0];
            r[o] = old_new[i + 1];
            if (i != 0) {
                i -= 1;
            }
        }

        return ByteStringReplacer{
            .replacements = r,
            .replacer = Replacer{ .replaceFn = replaceFn },
        };
    }

    pub fn replaceFn(replace_ctx: *Replacer, s: []const u8, buf: *std.Buffer) anyerror!void {
        const self = @fieldParentPtr(ByteReplacer, "replacer", replace_ctx);
        var new_size = s.len;
        var any_changes = false;
        var i: usize = 0;
        while (i < s.len) : (i += 1) {
            const b = s[i];
            if (self.replacements[b]) |value| {
                new_size += value.len - 1;
                any_changes = true;
            }
        }
        if (!any_changes) {
            return buf.append(s);
        }
        try buf.resize(new_size);
        var out = buf.toSlice();
        var j: usize = 0;
        i = 0;
        while (i < s.len) : (i += 1) {
            const b = s[i];
            if (self.replacements[b]) |value| {
                mem.copy(u8, out[j..], value);
                j += value.len;
            } else {
                out[j] = b;
                j += 1;
            }
        }
    }
};

pub const GenericReplacer = struct {
    root: TrieNode,
    table_size: usize,
    mapping: [256]usize,
    a: *Allocator,

    pub fn init(a: *Allocator, old_new: [][]const u8) GenericReplacer {}

    const TrieNode = struct {
        value: []const u8,
        priority: usize,
        prefix: []const u8,
        next: ?*TrieNode,
        table: Table,
        const Table = ArrayList(*TrieNode);

        fn add(self: *TrieNode, key: []const u8, value: []const u8, r: *GenericReplacer) !void {
            if (key.len == 0) {
                if (self.priority == 0) {
                    self.value = value;
                    self.priority = priority;
                }
                return;
            }
            if (self.prefix.len > 0) {
                const p = self.prefix;
                var n: usize = 0;
                while (n < p.len and n < key.len) : (n += 1) {
                    if (p[n] != key[n]) {
                        break;
                    }
                }
                if (n == p.len) {
                    try self.next.add(key[n..], value, priority);
                } else if (n == 0) {
                    var prefix_node: *TrieNode = undefined;
                    if (p.len == 1) {
                        prefix_node = self.next;
                    } else {
                        prefix_node = r.createNode();
                        prefix_node.prefix = p[1..];
                        prefix_node.next = self.next;
                    }
                    var key_node = r.createNode();
                    self.table = Table.init(r.a);
                    var ta = &self.table;
                    try ta.resize(r.table_size);
                    try ta.set(r.mapping[p[0]], prefix_node);
                    try ta.set(r.mapping[key[0]], key_node);
                    self.prefix = "";
                    self.next = null;
                    try key_node.add(key[1..], value, priority, r);
                } else {
                    const nxt = r.createNode();
                    nxt.prefix = p[n..];
                    nxt.next = self.next;
                    self.prefix = p[n..];
                    self.next = nxt;
                    try nxt.add(key[n..], value, priority, r);
                }
            } else if (self.table != null) {
                var ta = &self.table.?;
                const m = r.mapping[key[0]];
                var n: *TrieNode = undefined;
                if (ta.toSlice()[m] == undefined) {
                    n = r.createNode();
                    a.set(m, n);
                } else {
                    n = ta.toSlice()[m];
                }
                try n.add(key[1..], value, priority, r);
            } else {
                self.prefix = key;
                self.next = r.createNode();
                try self.next.add("", value, priority, r);
            }
        }
    };

    fn createNode(self: *GenericReplacer) !TrieNode {
        var n = self.a.createNode(TrieNode);
        n.* = TrieNode{
            .prefix = null,
            .next = undefined,
            .priority = undefined,
            .value = undefined,
            .table = null,
        };
        return n;
    }
};

const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const utf8 = @import("../unicode/utf8/index.zig");
const mem = std.mem;

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
        Byte: ByteReplacer,
        ByteString: ByteStringReplacer,
    };

    pub fn init(a: *Allocator, old_new: [][]const u8) !StringReplacer {
        if (old_new.len == 2 and old_new[0].len > 1) {
            return StringReplacer{
                .impl = ReplaceImpl{
                    .Single = try SingleReplacer.init(a, old_new[0], old_new[1]),
                },
            };
        }
        var all_new_bytes = true;
        var i: usize = 0;
        while (i < old_new.len) : (i += 2) {
            if (old_new[i].len != 1) {
                return StringReplacer{
                    .impl = ReplaceImpl{
                        .Generic = try GenericReplacer.init(a, old_new),
                    },
                };
            }
            if (old_new[i + 1].len != 1) {
                all_new_bytes = false;
            }
        }
        if (all_new_bytes) {
            return StringReplacer{
                .impl = ReplaceImpl{
                    .Byte = ByteReplacer.init(old_new),
                },
            };
        }
        return StringReplacer{
            .impl = ReplaceImpl{
                .Byte = ByteReplacer.init(old_new),
            },
        };
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
            ReplaceImpl.Byte => |*value| {
                const r = &value.replacer;
                return try r.replace(s, out);
            },
            ReplaceImpl.ByteString => |*value| {
                const r = &value.replacer;
                return try r.replace(s, out);
            },
            else => unreachable,
        }
    }

    pub fn deinit(self: *StringReplacer) void {
        switch (self.impl) {
            ReplaceImpl.Single => |*value| {
                value.deinit();
            },
            ReplaceImpl.Generic => |*value| {
                value.deinit();
            },
            ReplaceImpl.Byte => {},
            ReplaceImpl.ByteString => |*value| {
                value.deinit();
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
        const self = @fieldParentPtr(ByteStringReplacer, "replacer", replace_ctx);
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
    root: *TrieNode,
    table_size: usize,
    mapping: [256]usize,
    a: *Allocator,
    nodes_list: ArrayList(*TrieNode),
    replacer: Replacer,
    pub fn init(a: *Allocator, old_new: []const []const u8) !GenericReplacer {
        var g: GenericReplacer = undefined;
        g.nodes_list = ArrayList(*TrieNode).init(a);
        g.mapping = []usize{0} ** 256;
        g.replacer = Replacer{ .replaceFn = replaceFn };
        var i: usize = 0;
        while (i < old_new.len) : (i += 2) {
            var j: usize = 0;
            const key = old_new[i];
            while (j < key.len) : (j += 1) {
                g.mapping[key[j]] = 1;
            }
        }
        for (g.mapping) |value| {
            g.table_size += value;
        }
        var index: usize = 0;
        for (g.mapping) |*value| {
            if (value.* == 0) {
                value.* = g.table_size;
            } else {
                value.* = index;
                index += 1;
            }
        }
        g.a = a;
        g.root = try g.createNode();
        g.root.table = ArrayList(?*TrieNode).init(a);
        try (&g.root.table.?).resize(g.table_size);

        // We need to be able to check if the index has a value set yet. So we
        // set all values of the initialized array to null.
        //
        // This allows us to do table[i]==null to check if there is a tie node
        // there, I havent mastered pointer magic yet so no idea if there is a
        // mbetter way that wont necessarity reqire using a hash table.
        for ((&g.root.table.?).toSlice()) |*value| {
            value.* = null;
        }

        i = 0;
        while (i < old_new.len) : (i += 2) {
            try g.root.add(old_new[i], old_new[i + 1], old_new.len - i, &g);
        }
        return g;
    }

    const TrieNode = struct {
        value: []const u8,
        priority: usize,
        prefix: []const u8,
        next: ?*TrieNode,
        table: ?Table,
        const Table = ArrayList(?*TrieNode);

        fn add(self: *TrieNode, key: []const u8, value: []const u8, priority: usize, r: *GenericReplacer) anyerror!void {
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
                    try self.next.?.add(key[n..], value, priority, r);
                } else if (n == 0) {
                    var prefix_node: ?*TrieNode = null;
                    if (p.len == 1) {
                        prefix_node = self.next;
                    } else {
                        prefix_node = try r.createNode();
                        prefix_node.?.prefix = p[1..];
                        prefix_node.?.next = self.next;
                    }
                    var key_node = try r.createNode();
                    self.table = Table.init(r.a);
                    var ta = &self.table.?;
                    try ta.resize(r.table_size);
                    ta.set(r.mapping[p[0]], prefix_node.?);
                    ta.set(r.mapping[key[0]], key_node);
                    self.prefix = "";
                    self.next = null;
                    try key_node.add(key[1..], value, priority, r);
                } else {
                    const nxt = try r.createNode();
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
                if (ta.toSlice()[m] == null) {
                    n = try r.createNode();
                    ta.set(m, n);
                } else {
                    n = ta.toSlice()[m].?;
                }
                try n.add(key[1..], value, priority, r);
            } else {
                self.prefix = key;
                self.next = try r.createNode();
                try self.next.?.add("", value, priority, r);
            }
        }
    };

    fn createNode(self: *GenericReplacer) !*TrieNode {
        var n = try self.a.create(TrieNode);
        n.* = TrieNode{
            .prefix = "",
            .next = undefined,
            .priority = undefined,
            .value = undefined,
            .table = null,
        };
        try (&self.nodes_list).append(n);
        return n;
    }

    fn deinit(self: *GenericReplacer) void {
        for (self.node_list) |value| {
            self.a.destroy(value);
        }
        (&self.node_list).deinit();
    }

    const LookupRes = struct {
        value: []const u8,
        key_len: usize,
        found: bool,
    };

    fn lookup(self: *GenericReplacer, src: []const u8, ignore_root: bool) anyerror!LookupRes {
        var best_priority: usize = 0;
        var current_node: ?*TrieNode = self.root;
        var n: usize = 0;
        var result = LookupRes{
            .value = "",
            .key_len = 0,
            .found = false,
        };
        var s = src;
        while (current_node) |node| {
            if (node.priority > best_priority and !(ignore_root and node == self.root)) {
                best_priority = node.priority;
                result.value = node.value;
                result.key_len = n;
            }
            if (mem.eql(u8, s, "")) {
                break;
            }
            if (node.table) |table| {
                const index = self.mapping[s[0]];
                if (index == self.table_size) {
                    break;
                }
                current_node = table.toSlice()[index];
                s = s[1..];
                n += 1;
            } else if (!mem.eql(u8, node.prefix, "") and hasPrefix(s, node.prefix)) {
                n += node.prefix.len;
                s = s[node.prefix.len..];
                current_node = node.next;
            } else {
                break;
            }
        }
        return result;
    }

    pub fn replaceFn(replace_ctx: *Replacer, s: []const u8, buf: *std.Buffer) anyerror!void {
        const self = @fieldParentPtr(GenericReplacer, "replacer", replace_ctx);
        var last: usize = 0;
        var sw: usize = 0;
        var prev_match_empty = false;
        var i: usize = 0;
        while (i < s.len) {
            if (i != s.len and self.root.priority == 0) {
                const index = self.mapping[s[i]];
                if (index == self.table_size or self.root.table.?.at(index) == null) {
                    i += 1;
                    continue;
                }
                const lk = try self.lookup(s[i..], prev_match_empty);
                prev_match_empty = lk.found and lk.key_len == 0;
                if (lk.found) {
                    try buf.append(s[last..i]);
                    try buf.append(lk.value);
                    i += lk.key_len;
                    last = i;
                    continue;
                }
                i += 1;
            }
        }
        if (last != s.len) {
            try buf.append(s[last..]);
        }
    }
};

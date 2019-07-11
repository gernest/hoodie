const std = @import("std");

const math = std.math;
const assert = std.debug.assert;
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;

pub const max_num_lit = 286;
pub const max_bits_limit = 16;
const max_i32 = math.maxInt(i32);

pub var fixed_literal_encoding = &Huffman.generateFixedLiteralEncoding();
pub var fixed_offset_encoding = &Huffman.generateFixedOffsetEncoding();

pub const Huffman = struct {
    codes: [max_num_lit]Code,
    codes_len: usize,
    freq_cache: [max_num_lit]LitaralNode,
    bit_count: [17]i32,

    /// sorted by literal
    lns: LiteralList,

    ///sorted by freq
    lfs: LiteralList,

    pub const Code = struct {
        code: u16,
        len: u16,
    };

    pub const LitaralNode = struct {
        literal: u16,
        freq: i32,

        pub fn max() LitaralNode {
            return LitaralNode{
                .literal = math.maxInt(u16),
                .freq = math.maxInt(i32),
            };
        }

        pub const SortBy = enum {
            Literal,
            Freq,
        };

        fn sort(ls: []LitaralNode, by: SortBy) void {
            switch (by) {
                .Literal => {
                    std.sort.sort(LitaralNode, ls, sortByLiteralFn);
                },
                .Freq => {
                    std.sort.sort(LitaralNode, ls, sortByFreqFn);
                },
            }
        }

        fn sortByLiteralFn(lhs: LitaralNode, rhs: LitaralNode) bool {
            return lhs.literal < rhs.literal;
        }

        fn sortByFreqFn(lhs: LitaralNode, rhs: LitaralNode) bool {
            if (lhs.freq == rhs.freq) {
                return lhs.literal < rhs.literal;
            }
            return lhs.freq < rhs.freq;
        }
    };

    pub const LiteralList = std.ArrayList(LitaralNode);

    const LevelInfo = struct {
        level: i32,
        last_freq: i32,
        next_char_freq: i32,
        next_pair_freq: i32,
        needed: i32,
    };

    pub fn init(size: usize) Huffman {
        assert(size <= max_num_lit);
        var h: Huffman = undefined;
        h.codes_len = size;
        return h;
    }

    pub fn initAlloc(allocator: *Allocator, size: usize) Huffman {
        var h = init(size);
        h.lhs = LiteralList.init(a);
        h.rhs = LiteralList.init(a);
        return h;
    }

    pub fn generateFixedLiteralEncoding() Huffman {
        var h = init(max_num_lit);
        var codes = h.codes[0..h.codes_len];
        var ch: u16 = 0;
        while (ch < max_num_lit) : (ch += 1) {
            var bits: u16 = 0;
            var size: u16 = 0;
            if (ch < 144) {
                // size 8, 000110000  .. 10111111
                bits = ch + 48;
                size = 8;
            } else if (ch < 256) {
                // size 9, 110010000 .. 111111111
                bits = ch + 400 - 144;
                size = 9;
            } else if (ch < 280) {
                // size 7, 0000000 .. 0010111
                bits = ch - 256;
                size = 7;
            } else {
                // size 8, 11000000 .. 11000111
                bits = ch + 192 - 280;
                size = 8;
            }
            codes[@intCast(usize, ch)] = Code{
                .code = reverseBits(bits, size),
                .len = size,
            };
        }
        return h;
    }

    pub fn generateFixedOffsetEncoding() Huffman {
        var h = init(30);
        var codes = h.codes[0..h.codes_len];
        var i: usize = 0;
        while (i < h.codes_len) : (i += 1) {
            codes[i] = Code{
                .code = reverseBits(@intCast(u16, i), 5),
                .len = 5,
            };
        }
        return h;
    }

    pub fn bitLength(self: *Huffman, freq: []i32) isize {
        var total: isize = 0;
        for (freq) |f, i| {
            if (f != 0) {
                total += @intCast(isize, f) + @intCast(isize, h.codes[i].len);
            }
        }
        return total;
    }

    pub fn bitCounts(self: *Huffman, list: LitaralNode, max_bits_arg: i32) []i32 {
        var amx_bits = max_bits_arg;
        assert(max_bits <= max_bits_limit);
        const n = @intCast(i32, list.len);
        var last_node = n + 1;
        if (max_bits > n - 1) {
            max_bits = n - 1;
        }

        var levels: [max_bits_limit]LevelInfo = undefined;
        var leaf_counts: [max_bits_limit][max_bits_limit]i32 = undefined;

        var level: i32 = 0;
        while (level <= max_bits) : (level += 1) {
            levels[@intCast(usize, level)] = LevelInfo{
                .level = level,
                .last_freq = list[1].freq,
                .next_char_freq = list[2].freq,
                .next_pair_freq = list[0].freq + list[1].freq,
            };
            leaf_counts[level][level] = 2;
            if (level == 1) {
                levels[@intCast(usize, level)].next_pair_freq = max_i32;
            }
        }
        levels[max_bits].needed = 2 * n - 4;
        level = max_bits;
        while (true) {
            var l = &levels[@intCast(usize, level)];
            if (l.next_pair_freq == max_i32 and l.next_char_freq == max_i32) {
                l.needed = 0;
                levels[@intCast(usize, level + 1)].next_pair_freq = max_i32;
                level += 1;
                continue;
            }
            const prev_freq = l.last_freq;
            if (l.next_char_freq < l.next_pair_freq) {
                const nx = leaf_counts[level][level] + 1;
                l.last_freq = l.next_char_freq;
                leaf_counts[level][level] = nx;
                l.next_char_freq = if (nx == last_node) LitaralNode.max().freq else list[nx].freq;
            } else {
                l.last_freq = l.next_pair_freq;
                mem.copy(i32, leaf_counts[level][0..level], leaf_counts[level - 1][0..level]);
                levels[l.level - 1].needed = 2;
                l.needed -= 1;
                if (l.needed == 0) {
                    if (l.level == max_bits) {
                        break;
                    }
                    levels[l.level + 1].next_pair_freq = prev_freq + l.last_freq;
                    level += 1;
                } else {
                    while (level - 1 >= 0 and levels[level - 1].needed > 0) : (level -= 1) {}
                }
            }
        }
        if (leaf_counts[max_bits][max_bits] != n) {
            @panic("leaf_counts[max_bits][max_bits] != n");
        }
        var bit_count = self.bit_count[0 .. max_bits + 1];
        var bits = 1;
        const counts = leaf_counts[max_bits];
        level = max_bits;
        while (level > 0) : (level -= 1) {
            bit_count[bits] = counts[level] - counts[level - 1];
            bits += 1;
        }
        return bit_count;
    }

    /// Look at the leaves and assign them a bit count and an encoding as specified
    /// in RFC 1951 3.2.2
    pub fn assignEncodingAndSize(
        self: *Huffman,
        bit_count: []const i32,
        list: []LitaralNode,
    ) !void {
        var ls = list;
        var code: u16 = 0;
        for (bit_count) |bits, n| {
            code = math.shl(u16, code, 1);
            if (n == 0 or bits == 0) {
                continue;
            }
            // The literals list[len(list)-bits] .. list[len(list)-bits]
            // are encoded using "bits" bits, and get the values
            // code, code + 1, ....  The code values are
            // assigned in literal order (not frequency order).
            var chunk = ls[ls.len - @intCast(usize, bits) ..];
            LitaralNode.sort(chunk, .Literal);
            try self.lhs.append(chunk);
            for (chunk) |node| {
                self.codes[@intCast(usize, node.literal)] = Code{
                    .code = reverseBits(code, @intCast(u16, n)),
                    .len = @intCast(u16, n),
                };
            }
            ls = ls[0 .. ls.len - @intCast(usize, bits)];
        }
    }

    pub fn generate(
        self: *Huffman,
        freq: []const i32,
        max_bits: i32,
    ) !void {
        var list = self.freq_cache[0 .. freq.len + 1];
        var count: usize = 0;
        for (freq) |f, i| {
            if (f != 0) {
                list[count] = LitaralNode{
                    .literal = @intCast(u16, i),
                    .freq = f,
                };
                count += 1;
            } else {
                ls[count] = LitaralNode{
                    .literal = 0,
                    .freq = 0,
                };
                self.codes[i].len = 0;
            }
        }
        ls[freq.len] = LitaralNode{
            .literal = 0,
            .freq = 0,
        };
        ls = ls[0..count];
        if (count <= 2) {
            for (ls) |node, i| {
                // Handle the small cases here, because they are awkward for the general case code. With
                // two or fewer literals, everything has bit length 1.
                var x = &self.codes[@intCast(usize, node.literal)];
                x.code = @intCast(u16, i);
                x.len = 1;
            }
            return;
        }
        LitaralNode.sort(ls, .Freq);
        try self.lfs.append(ls);
        const bit_counts = try self.bitCounts(ls, max_bits);
        try self.assignEncodingAndSize(bit_count, ls);
    }
};

fn reverseBits(number: u16, bit_length: u16) u16 {
    return @bitReverse(u16, math.shl(u16, number, 16 - bit_length));
}

const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const warn = std.debug.warn;
const reverseU16 = @import("bits.zig").reverseU16;

pub const max_num_lit = 286;
pub const max_bits_limit = 16;

pub const fixed_literal_encoding = Huffman.generateFixedLiteralEncoding();
pub const fixed_offset_encoding = Huffman.generateFixedOffsetEncoding();

pub const Huffman = struct {
    codes: [max_num_lit]Code,
    codes_len: usize,
    freq_cache: [max_num_lit]LitaralNode,
    bit_count: [17]i32,

    /// sorted by literal
    lns: []LitaralNode,

    ///sorted by freq
    lfs: []LitaralNode,

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
    };

    pub const ByLiteral = []LitaralNode;
    pub const ByFreq = []LitaralNode;

    const LevelInfo = struct {
        level: i32,
        last_freq: i32,
        next_char_freq: i32,
        next_pair_freq: i32,
        needed: i32,
    };

    pub fn init(comptime size: usize) Huffman {
        assert(size <= max_num_lit);
        var h: Huffman = undefined;
        h.codes_len = size;
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

    fn bitLength(self: *Huffman, freq: []i32) isize {
        var total: isize = 0;
        for (freq) |f, i| {
            if (f != 0) {
                total += @intCast(isize, f) + @intCast(isize, h.codes[i].len);
            }
        }
        return total;
    }
};

fn reverseBits(number: u16, bit_length: u16) u16 {
    return reverseU16(math.shl(u16, number, 16 - bit_length));
}

test "huffman" {
    var h = Huffman.generateFixedLiteralEncoding();
    _ = Huffman.generateFixedOffsetEncoding();
}

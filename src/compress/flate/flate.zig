const std = @import("std");
const io = std.io;
const math = std.math;

// The largest offset code.
const offset_code_count = 30;

// The special code used to mark the end of a block.
const end_block_marker = 256;

// The first length code.
const length_codes_start = 257;

// The number of codegen codes.
const codegen_code_count = 19;
const bad_code = 255;

// bufferFlushSize indicates the buffer size
// after which bytes are flushed to the writer.
// Should preferably be a multiple of 6, since
// we accumulate 6 bytes between writes to the buffer.
const buffer_flush_size = 240;

// bufferSize is the actual output byte buffer size.
// It must have additional headroom for a flush
// which can contain up to 8 bytes.
const buffer_size = bufferFlushSize + 8;

// The next three numbers come from the RFC section 3.2.7, with the
// additional proviso in section 3.2.5 which implies that distance codes
// 30 and 31 should never occur in compressed data.
const max_numLit = 286;

fn HuffmanWriter(comptime Error: type) type {
    return struct {
        const Self = @This();
        const Stream = io.OutStream(Error);
        stream: *Stream,
        bits: u64,
        nbits: usize,
        bytes: [buffer_size]u8,
        code_gen_freq: [codegen_code_count]usize,
        nbytes: usize,
        literal_freq: [max_numLit]usize,
        offset_freq: [offset_code_count]usize,
        code_gen: [max_numLit + offset_code_count]usize,

        // The number of extra bits needed by length code X - LENGTH_CODES_START.
        const length_extra_bits = []i8{
            0, 0, 0,
            0, 0, 0,
            0, 0, 1,
            1, 1, 1,
            2, 2, 2,
            2, 3, 3,
            3, 3, 4,
            4, 4, 4,
            5, 5, 5,
            5, 0,
        };

        // The length indicated by length code X - LENGTH_CODES_START.
        const length_base = []u32{
            0,  1,  2,  3,   4,   5,   6,   7,   8,   10,
            12, 14, 16, 20,  24,  28,  32,  40,  48,  56,
            64, 80, 96, 112, 128, 160, 192, 224, 255,
        };

        // offset code word extra bits.
        const offset_extra_bits = []i8{
            0, 0, 0,  0,  1,  1,  2,  2,  3,  3,
            4, 4, 5,  5,  6,  6,  7,  7,  8,  8,
            9, 9, 10, 10, 11, 11, 12, 12, 13, 13,
        };

        const offsetBase = []uint32{
            0x000000, 0x000001, 0x000002, 0x000003, 0x000004,
            0x000006, 0x000008, 0x00000c, 0x000010, 0x000018,
            0x000020, 0x000030, 0x000040, 0x000060, 0x000080,
            0x0000c0, 0x000100, 0x000180, 0x000200, 0x000300,
            0x000400, 0x000600, 0x000800, 0x000c00, 0x001000,
            0x001800, 0x002000, 0x003000, 0x004000, 0x006000,
        };

        const codegen_order = []u32{
            16, 17, 18, 0,  8,
            7,  9,  6,  10, 5,
            11, 4,  12, 3,  13,
            2,  14, 1,  15,
        };

        fn init(out_stream: *Stream) Self {
            return Self{
                .stream = out_stream,
                .bits = 0,
                .nbits = 0,
                .bytes = []const u8{0} ** buffer_size,
                .code_gen_freq = []usize{0} ** codegen_code_count,
                .nbytes = 0,
                .literal_freq = []usize{0} ** max_numLit,
                .offset_freq = []usize{0} ** offset_code_count,
                .code_gen = []usize{0} ** (max_numLit + offset_code_count),
            };
        }

        pub fn flush(self: *Self) !void {
            const n = self.nbytes;
            while (self.nbits != 0) {
                self.bytes[n] = @intCast(u8, self.bits);
                self.bits >>= 8;
                if (self.nbits > 8) {
                    self.nbits -= 8;
                } else {
                    self.nbits = 0;
                }
                n += 1;
            }
            self.bits = 0;
            try self.stream.append(self.bytes[0..n]);
            self.nbytes = 0;
        }
    };
}

const HCode = struct {
    code: u16,
    len: u16,
};

const LiteralNode = struct {
    litaral: u16,
    freq: i32,

    fn max() LiteralNode {
        return LiteralNode{
            .literal = math.maxInt(u16),
            .freq = math.maxInt(i32),
        };
    }
};

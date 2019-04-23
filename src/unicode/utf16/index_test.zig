const unicode = @import("../unicode.zig");
const utf16 = @import("index.zig");
const t = @import("../util/index.zig");
const std = @import("std");
const mem = std.mem;

test "constants" {
    if (utf16.max_rune != unicode.tables.max_rune) {
        try t.terror("utf16.max_rune is wrong");
    }
}

const encodeTest = struct {
    in: []const i32,
    out: []const u16,
};

const encode_tests = []encodeTest{
    encodeTest{ .in = []i32{ 1, 2, 3, 4 }, .out = []u16{ 1, 2, 3, 4 } },
    encodeTest{
        .in = []i32{ 0xffff, 0x10000, 0x10001, 0x12345, 0x10ffff },
        .out = []u16{ 0xffff, 0xd800, 0xdc00, 0xd800, 0xdc01, 0xd808, 0xdf45, 0xdbff, 0xdfff },
    },
    encodeTest{
        .in = []i32{ 'a', 'b', 0xd7ff, 0xd800, 0xdfff, 0xe000, 0x110000, -1 },
        .out = []u16{ 'a', 'b', 0xd7ff, 0xfffd, 0xfffd, 0xe000, 0xfffd, 0xfffd },
    },
};

test "encode" {
    var a = std.debug.global_allocator;
    for (encode_tests) |ts, i| {
        const value = try utf16.encode(a, ts.in);
        if (!mem.eql(u16, ts.out, value.toSliceConst())) {
            try t.terrorf("mismatch encoding at {}\n", i);
        }
        value.deinit();
    }
}

test "encodeRune" {
    for (encode_tests) |tt, i| {
        var j: usize = 0;
        for (tt.in) |r| {
            const pair = utf16.encodeRune(r);
            if (r < 0x10000 or r > unicode.tables.max_rune) {
                if (j >= tt.out.len) {
                    try t.terrorf("#{} ran out of tt.out \n", i);
                }
                if (pair.r1 != unicode.tables.replacement_char or pair.r2 != unicode.tables.replacement_char) {
                    try t.terrorf("encodeRune(0x{x})= 0x{x}, 0x{x} want 0xfffd, 0xfffd\n", r, pair.r1, pair.r2);
                }
                j += 1;
            } else {
                if (j >= tt.out.len) {
                    try t.terrorf("#{} ran out of tt.out \n", i);
                }
                if (pair.r1 != @intCast(i32, tt.out[j]) or pair.r2 != @intCast(i32, tt.out[j + 1])) {
                    try t.terrorf("encodeRune(0x{x})= 0x{x}, 0x{x} want 0x{x}, 0x{x}\n", r, pair.r1, pair.r2, tt.out[j], tt.out[j + 1]);
                }
                j += 2;
                const dec = utf16.decodeRune(pair.r1, pair.r2);
                if (dec != r) {
                    try t.terrorf("#{} decodeRune(0x{x},0x{x})= 0x{x} want 0x{x}\n", i, pair.r1, pair.r2, dec, r);
                }
            }
        }
    }
}

const std = @import("std");
const coding = @import("huffman.zig");

const Huffman = coding.Huffman;

test "huffman" {
    var h = Huffman.generateFixedLiteralEncoding();
    _ = Huffman.generateFixedOffsetEncoding();
}

const std = @import("std");
const io = std.io;
const mem = std.mem;

pub const Offset = enum {
    Startup,
    Base,
};

// Writer wraps a Buffer and allows writing postgres wired values
pub const Writer = struct {
    buf: *std.Buffer,
    writer: io.BufferOutStream,

    pub fn init(buf: *std.Buffer) Writer {
        return Writer{
            .buf = buf,
            .writer = io.BufferOutStream.init(buf),
        };
    }

    pub fn writeByte(self: *Writer, b: u8) !void {
        try self.buf.appendByte(b);
    }

    pub fn write(self: *Writer, b: []const u8) !void {
        try self.buf.append(b);
    }

    pub fn writeString(self: *Writer, b: []const u8) !void {
        try self.buf.append(b);
        try self.buf.appendByte(0x00);
    }

    pub fn writeInt32(self: *Writer, b: i32) !void {
        var stream = &self.writer.stream;
        try stream.writeIntBig(u32, @intCast(u32, b));
    }

    pub fn writeInt16(self: *Writer, b: i16) !void {
        var stream = &self.writer.stream;
        try stream.writeIntBig(u16, @intCast(u16, b));
    }

    pub fn resetLength(self: *Writer, offset: Offset) void {
        var b = self.buf.toSlice();
        var s = b[@enumToInt(offset)..];
        var bytes: [(u32.bit_count + 7) / 8]u8 = undefined;
        mem.writeIntBig(u32, &bytes, @intCast(u32, s.len));
        mem.copy(u8, s, bytes[0..]);
    }
};

test "write" {
    var a = std.debug.global_allocator;
    var buf = &try std.Buffer.init(a, "");
    var w = &Writer.init(buf);
    try w.writeInt32(0);
    try w.writeInt32(1);
    try w.writeInt32(2);
    w.resetLength(.Base);
    std.debug.warn("size {}\n", buf.len());
}

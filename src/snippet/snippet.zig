const std = @import("std");
const strings = @import("../strings/strings.zig");
const warn = std.debug.warn;

pub const Builder = struct {
    buf: *std.Buffer,
    replacer: strings.StringReplacer,
    choice_replacer: strings.StringReplacer,
    a: *std.mem.Allocator,
    current_tab_stop: usize,

    pub fn init(a: *std.mem.Allocator, buf: *std.Buffer) !Builder {
        return Builder{
            .buf = buf,
            .replacer = try strings.StringReplacer.init(
                a,
                [][]const u8{
                    []const u8{0x5c}, []const u8{ 0x5c, 0x5c },
                    []const u8{0x7d}, []const u8{ 0x5c, 0x7d },
                    []const u8{0x24}, []const u8{ 0x5c, 0x24 },
                },
            ),
            .choice_replacer = try strings.StringReplacer.init(
                a,
                [][]const u8{
                    []const u8{0x5c}, []const u8{ 0x5c, 0x5c },
                    []const u8{0x7d}, []const u8{ 0x5c, 0x7d },
                    []const u8{0x24}, []const u8{ 0x5c, 0x24 },
                    []const u8{0x7c}, []const u8{ 0x5c, 0x7c },
                    []const u8{0x2c}, []const u8{ 0x5c, 0x2c },
                },
            ),
            .a = a,
            .current_tab_stop = 0,
        };
    }

    pub fn writeChoice(self: *Builder, choices: []const []const u8) !void {
        var stream = &std.io.BufferOutStream.init(self.buf).stream;
        try stream.write("${");
        try stream.print("{}|", self.nextTabStop());
        var tmp = &try std.Buffer.init(self.a, "");
        defer tmp.deinit();
        for (choices) |choice, i| {
            if (i != 0) {
                try stream.writeByte(',');
            }
            try tmp.resize(0);
            try (&self.choice_replacer).replace(choice, tmp);
            try stream.write(tmp.toSlice());
        }
        try stream.write("|}");
    }

    fn nextTabStop(self: *Builder) usize {
        self.current_tab_stop += 1;
        return self.current_tab_stop;
    }

    fn writeText(self: *Builder, text: []const u8) !void {
        var tmp = &try std.Buffer.init(self.a, "");
        defer tmp.deinit();
        try (&self.replacer).replace(text, tmp);
        try self.buf.append(tmp.toSlice());
    }

    fn reset(self: *Builder) !void {
        try self.buf.resize(0);
        self.current_tab_stop = 0;
    }

    fn writePlaceholder(self: *Builder, cb: ?fn (*Builder) anyerror!void) !void {
        var stream = &std.io.BufferOutStream.init(self.buf).stream;
        try stream.write("${");
        try stream.print("{}", self.nextTabStop());
        if (cb) |f| {
            try stream.writeByte(':');
            try f(self);
        }
        try stream.writeByte('}');
    }

    pub fn toSliceConst(self: *Builder) []const u8 {
        return self.buf.toSliceConst();
    }
};

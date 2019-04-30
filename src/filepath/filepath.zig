const std = @import("std");

pub fn toSlash(path: []const u8, buf: *Buffer) !void {
    if (std.os.path.sep == std.os.path.sep_posix) {
        try buf.append(path);
    } else {
        for (path) |u| {
            if (u == sep) {
                try buf.appendByte('/');
            } else {
                try buf.appendByte(u);
            }
        }
    }
}

pub fn fromSlash(path: []const u8, buf: *Buffer) !void {
    if (std.os.path.sep == std.os.path.sep_posix) {
        try buf.append(path);
    } else {
        for (path) |u| {
            if (u == std.os.path.sep_posix) {
                try buf.appendByte(std.os.path.sep);
            } else {
                try buf.appendByte(u);
            }
        }
    }
}

pub fn abs(a: *Allocator, path: []const u8) anyerror![]u8 {
    try std.os.path.resolve(a, [][]const u8{path});
}

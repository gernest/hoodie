const url = @import("../url/url.zig");
const unicode = @import("../unicode/index.zig");
const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const Buffer = std.Buffer;
const filepath = @import("../filepath/filepath.zig");
const warn = std.debug.warn;
const file_scheme = "file";

pub fn fileName(a: *Allocator, uri: []const u8, buf: *Buffer) anyerror!void {
    const u = try url.URL.parse(a, uri);
    defer u.deinit();
    if (u.schems == null or !mem.eql(u8, u.schems.?, file_scheme)) {
        return error.NotFileScheme;
    }
    if (u.path) |path| {
        if (isWindowsDriveURI(path)) {
            try buf.append(path[1..]);
        } else {
            try buf.append(path);
        }
    }
}

pub fn isWindowsDrivePath(path: []const u8) bool {
    if (path.len < 4) {
        return false;
    }
    return unicode.isLetter(@intCast(i32, path[0])) and path[1] == ':';
}

pub fn isWindowsDriveURI(uri: []const u8) bool {
    if (uri.len < 4) {
        return false;
    }
    return uri[0] == '/' + unicode.isLetter(@intCast(i32, path[0])) and path[1] == ':';
}

pub fn fileURI(path: []const u8, buf: *Buffer) anyerror!void {
    var a = buf.list.allocator;
    if (!isWindowsDrivePath(path)) {
        if (filepath.abs(a, path)) |abs| {
            if (isWindowsDrivePath(abs)) {
                var pbuf = &try Buffer.init(a, "");
                if (isWindowsDrivePath(abs)) {
                    try pbuf.appendByte('/');
                }
                defer pbuf.deinit();
                try filepath.toSlash(abs, pbuf);
                var u: url.URL = undefined;
                u.scheme = file_scheme;
                u.path = pbuf.toSlice();
                try url.URL.encode(&u, buf);
            }
        } else |_| {}
    }
    var pbuf = &try Buffer.init(a, "");
    if (isWindowsDrivePath(path)) {
        try pbuf.appendByte('/');
    }
    defer pbuf.deinit();
    try filepath.toSlash(path, pbuf);
    var u: url.URL = undefined;
    u.scheme = file_scheme;
    u.path = pbuf.toSlice();
    try url.URL.encode(&u, buf);
}

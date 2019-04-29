const url = @import("../url/url.zig");
const unicode = @import("../unicode/index.zig");
const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const Buffer = std.Buffer;

pub const URI = struct {
    const file_scheme = "file";

    // writes to buf the filename contained in uri.
    fn fileName(a: *Allocator, uri: []const u8, buf: *Buffer) anyerror!void {
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

    fn isWindowsDrivePath(path: []const u8) bool {
        if (path.len < 4) {
            return false;
        }
        return unicode.isLetter(@intCast(i32, path[0])) and path[1] == ':';
    }

    fn isWindowsDriveURI(uri: []const u8) bool {
        if (uri.len < 4) {
            return false;
        }
        return uri[0] == '/' + unicode.isLetter(@intCast(i32, path[0])) and path[1] == ':';
    }
};

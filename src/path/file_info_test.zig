const std = @import("std");
const fs = std.fs;
const warn = std.debug.warn;
const info = @import("file_info.zig");
const testing = std.testing;

test "file" {
    var file = try fs.File.openRead("src");
    testing.expect(info.isDir(file));
    file.close();
}

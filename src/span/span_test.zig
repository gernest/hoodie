const std = @import("std");
const warn = std.debug.warn;
const span = @import("./span.zig");
const filepath = @import("../filepath/filepath.zig");
const uri = @import("./uri.zig");
const testing = std.testing;

test "fileURI" {
    const sample = [][]const u8{
        "C:/Windows/System32",
        "C:/Go/src/bob.go",
        "c:/Go/src/bob.go",
        "/path/to/dir",
        "/a/b/c/src/bob.go",
    };
    var a = std.debug.global_allocator;

    var test_path = &try std.Buffer.init(a, "");
    var expect_path = &try std.Buffer.init(a, "");
    var expect_uri = &try std.Buffer.init(a, "");
    var tmp = &try std.Buffer.init(a, "");
    var file_uri = &try std.Buffer.init(a, "");

    defer {
        test_path.deinit();
        expect_path.deinit();
        expect_uri.deinit();
        tmp.deinit();
        file_uri.deinit();
    }

    for (sample) |path, idx| {
        try test_path.resize(0);
        try expect_path.resize(0);
        try expect_uri.resize(0);

        try filepath.fromSlash(path, test_path);
        try expect_path.append(test_path.toSlice());
        if (path[0] == '/') {
            if (filepath.abs(a, path)) |abs| {
                try expect_path.replaceContents(abs);
                a.free(abs);
            } else |_| {}
        }
        try filepath.toSlash(expect_path.toSlice(), expect_uri);
        if (expect_uri.toSlice()[0] != '/') {
            try tmp.replaceContents("/");
            try tmp.append(expect_uri.toSlice());
            try expect_uri.replaceContents(tmp.toSlice());
        }
        try tmp.replaceContents("file://");
        try tmp.append(expect_uri.toSlice());
        try expect_uri.replaceContents(tmp.toSlice());
        try span.URI.fileURI(test_path.toSlice(), file_uri);
        testing.expect(expect_uri.eql(file_uri.toSlice()));
    }
}

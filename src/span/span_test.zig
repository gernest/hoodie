const std = @import("std");
const warn = std.debug.warn;
const span = @import("./span.zig");
const filepath = @import("../filepath/filepath.zig");
const url = @import("../url/url.zig");
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
        try file_uri.resize(0);

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
        var got_uri = try span.URI.fromFile(a, test_path.toSlice());
        testing.expect(expect_uri.eql(got_uri.data));
        got_uri.deinit();
    }
}

test "parse" {
    const sample = [][3][]const u8{
        [][]const u8{ "C:/file_a", "C:/file_a", "file:///C:/file_a:1:1#0" },
        [][]const u8{ "C:/file_b:1:2", "C:/file_b:#1", "file:///C:/file_b:1:2#1" },
        [][]const u8{ "C:/file_c:1000", "C:/file_c:#9990", "file:///C:/file_c:1000:1#9990" },
        [][]const u8{ "C:/file_d:14:9", "C:/file_d:#138", "file:///C:/file_d:14:9#138" },
        [][]const u8{ "C:/file_e:1:2-7", "C:/file_e:#1-#6", "file:///C:/file_e:1:2#1-1:7#6" },
        [][]const u8{ "C:/file_f:500-502", "C:/file_f:#4990-#5010", "file:///C:/file_f:500:1#4990-502:1#5010" },
        [][]const u8{ "C:/file_g:3:7-8", "C:/file_g:#26-#27", "file:///C:/file_g:3:7#26-3:8#27" },
        [][]const u8{ "C:/file_h:3:7-4:8", "C:/file_h:#26-#37", "file:///C:/file_h:3:7#26-4:8#37" },
    };
    var a = std.debug.global_allocator;
    for (sample) |ts| {
        for (ts) |ti| {
            var s = try span.parse(a, ti);
            s.deinit();
        }
    }
}

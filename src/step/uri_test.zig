const std = @import("std");
const filepath = @import("../filepath/filepath.zig");

test "uri" {
    const sample = [][]const u8{
        "C:/Windows/System32",
        "C:/Go/src/bob.go",
        "c:/Go/src/bob.go",
        "/path/to/dir",
        "/a/b/c/src/bob.go",
    };
    for (sample) |path| {}
}

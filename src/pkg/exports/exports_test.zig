const std = @import("std");

const testing = std.testing;
const warn = std.debug.warn;
const exports = @import("exports.zig");
const path = std.fs.path;

test "export" {
    testing.expect(exports.fileExists("dummy") == false);
    var a = std.debug.global_allocator;

    const test_dir = try path.resolve(a, [_][]const u8{"./fixture/exports"});
    defer a.free(test_dir);

    const build_file = try path.join(a, [_][]const u8{
        test_dir,
        "build.zig",
    });
    defer a.free(build_file);
    testing.expect(exports.fileExists(build_file) == true);

    const test_src = try path.join(a, [_][]const u8{
        test_dir,
        "src",
    });
    defer a.free(test_src);
    warn("\n");
    var exp = &exports.Export.init(a, test_dir);
    try exp.dir(test_src);
    defer exp.deinit();
    try exp.dump();
}

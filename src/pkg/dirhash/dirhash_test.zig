const std = @import("std");
const dirhash = @import("dirhash.zig");
const path = std.fs.path;
const testing = std.testing;
const warn = std.debug.warn;
test "hashdir" {
    var a = std.debug.global_allocator;
    var buf = &try std.Buffer.init(a, "");
    defer buf.deinit();

    const test_dir = try path.resolve(a, [_][]const u8{"./fixture/test-project"});
    try dirhash.hashDir(a, buf, test_dir);
    const want = "Jh74wmxCsVTMM7HpisUPoaT5F5ADvPKKEcHpN89Oo6c=";
    testing.expect(buf.eql(want));
}

const std = @import("std");
const ignore = @import("ignore.zig");
const warn = std.debug.warn;
const testing = std.testing;
const FileInfo = @import("path/file_info").FileInfo;

test "parse" {
    const rules =
        \\#ignore
        \\#ignore
        \\foo
        \\bar/*
        \\baz/bar/foo.txt
        \\one/more
    ;

    var a = std.debug.global_allocator;
    var rule = try ignore.parseString(a, rules);
    defer rule.deinit();

    testing.expectEqual(rule.patterns.len, 4);
    const expects = [_][]const u8{
        "foo", "bar/*", "baz/bar/foo.txt", "one/more",
    };
    for (rule.patterns.toSlice()) |p, i| {
        testing.expectEqualSlices(u8, p.raw, expects[i]);
    }
}
const Fixture = struct {
    pattern: []const u8,
    name: []const u8,
    expect: bool,
    is_dir: bool,

    const Self = @This();
    fn init(
        pattern: []const u8,
        name: []const u8,
        expect: bool,
        is_dir: bool,
    ) Self {
        return Self{
            .pattern = pattern,
            .name = name,
            .expect = expect,
            .is_dir = is_dir,
        };
    }
};
test "ignore" {
    var a = std.debug.global_allocator;
    const sample = [_]Fixture{
        Fixture.init("helm.txt", "helm.txt", true, false),
        Fixture.init("helm.*", "helm.txt", true, false),
        Fixture.init("helm.*", "rudder.txt", false, false),
        Fixture.init("*.txt", "tiller.txt", true, false),
        Fixture.init("*.txt", "cargo/a.txt", true, false),
        Fixture.init("cargo/*.txt", "cargo/a.txt", true, false),
        Fixture.init("cargo/*.*", "cargo/a.txt", true, false),
        Fixture.init("cargo/*.txt", "mast/a.txt", false, false),
        Fixture.init("ru[c-e]?er.txt", "rudder.txt", true, false),
        Fixture.init("templates/.?*", "templates/.dotfile", true, false),
        // "." should never get ignored. https://github.com/kubernetes/helm/issues/1776
        Fixture.init(".*", ".", false, false),
        Fixture.init(".*", "./", false, false),
        Fixture.init(".*", ".joonix", true, false),
        Fixture.init(".*", "helm.txt", false, false),
        Fixture.init(".*", "", false, false),

        // Directory tests
        Fixture.init("cargo/", "cargo", true, true),
        Fixture.init("cargo/", "cargo/", true, true),
        Fixture.init("cargo/", "mast/", false, true),
        Fixture.init("helm.txt/", "helm.txt", false, false),

        // Negation tests
        Fixture.init("!helm.txt", "helm.txt", false, false),
        Fixture.init("!helm.txt", "tiller.txt", true, false),
        Fixture.init("!*.txt", "cargo", true, true),
        Fixture.init("!cargo/", "mast/", true, true),

        // Absolute path tests
        Fixture.init("/a.txt", "a.txt", true, false),
        Fixture.init("/a.txt", "cargo/a.txt", false, false),
        Fixture.init("/cargo/a.txt", "cargo/a.txt", true, false),
    };

    for (sample) |ts| {
        try testIngore(a, ts);
    }
}

fn testIngore(a: *std.mem.Allocator, fx: Fixture) !void {
    var rule = try ignore.parseString(a, fx.pattern);
    defer rule.deinit();
    const got = rule.ignore(fx.name, FileInfo{ .is_dir = fx.is_dir });
    if (got != fx.expect) {
        warn("{}  -- expected {} got {}\n", fx, fx.expect, got);
    }
}

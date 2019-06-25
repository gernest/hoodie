const Dump = @import("../json/json.zig").Dump;
const outline = @import("../outline/outline.zig");
const std = @import("std");

const cli = @import("flags");
const Command = cli.Command;
const Context = cli.Context;
const Flag = cli.Flag;

const json = std.json;
const parse = std.zig.parse;

/// taken from https://github.com/Hejsil/zig-clap
const max_src_size = 2 * 1024 * 1024 * 1024; // 2 GiB

pub const command = Command{
    .name = "outline",
    .flags = [_]Flag{Flag{
        .name = "modified",
        .desc = "reads text to be outlined from stdin",
        .kind = .Bool,
    }},
    .action = outlineCmd,
    .sub_commands = null,
};

fn renderJson(a: *std.mem.Allocator, ls: *outline.Declaration.List, stream: var) !void {
    var values = std.ArrayList(json.Value).init(a);
    defer values.deinit();
    for (ls.toSlice()) |decl| {
        var v = try decl.encode(a);
        try values.append(v);
    }
    var v = json.Value{ .Array = values };
    var dump = &try Dump.init(a);
    defer dump.deinit();
    try dump.dump(v, stream);
}

fn exec(a: *std.mem.Allocator, src: []const u8, stream: var) anyerror!void {
    var tree = try parse(a, src);
    defer tree.deinit();
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    var ls = &try outline.outlineDecls(&arena.allocator, tree);
    defer ls.deinit();
    try renderJson(a, ls, stream);
}

fn outlineCmd(
    ctx: *const Context,
) anyerror!void {
    if (ctx.boolean("modified")) {
        const source_code = try ctx.stdin.?.readAllAlloc(ctx.allocator, max_src_size);
        defer ctx.allocator.free(source_code);
        return exec(ctx.allocator, source_code, ctx.stdout.?);
    }
}

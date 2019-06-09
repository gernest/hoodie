const Dump = @import("../json/json.zig").Dump;
const outline = @import("../outline/outline.zig");
const std = @import("std");

const json = std.json;
const parse = std.zig.parse;

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

pub fn exec(a: *std.mem.Allocator, src: []const u8, stream: var) anyerror!void {
    var tree = try parse(a, src);
    defer tree.deinit();
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    var ls = &try outline.outlineDecls(&arena.allocator, tree);
    defer ls.deinit();
    try renderJson(a, ls, stream);
}

const std = @import("std");
const std = @import("std");

const Template = struct {
    command: *Command,
};

const Command = struct {
    exec: fn (self: *Command, ctx: var, out: *std.Buffer) anyerror!void,
};

fn compile(a: *mem.Allocator, text: []const u8) !Template {}

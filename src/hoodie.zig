const builtin = @import("builtin");
const std = @import("std");
const app = @import("cmd/commands.zig").app;
const Args = cli.Args;
const Cli = cli.Cli;
const Command = cli.Command;
const Context = cli.Context;
const Flag = cli.Flag;
const FlagItem = cli.FlagSet.FlagItem;
const debug = std.debug;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const mem = std.mem;
const os = std.os;
const process = std.process;
const testing = std.testing;
const warn = std.debug.warn;

pub fn main() anyerror!void {
    const allocator = std.heap.direct_allocator;
    const arg = try std.process.argsAlloc(allocator);
    defer allocator.free(arg);

    var stdin_file = try io.getStdIn();
    var stdin = &stdin_file.inStream().stream;

    var stdout_file = try io.getStdOut();
    var stdout = &stdout_file.outStream().stream;

    var stderr_file = try io.getStdErr();
    var stderr = &stderr_file.outStream().stream;
    try app.run(allocator, arg[1..], stdin, stdout, stderr);
}

fn lspCmd(
    ctx: *const Context,
) anyerror!void {}

fn showArgs(
    ctx: *const Context,
) anyerror!void {
    var it = &ctx.getArgs();
    while (it.next()) |arg| {
        try ctx.stdout.?.print(" [{}]", arg);
    }
}

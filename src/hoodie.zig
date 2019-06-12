const builtin = @import("builtin");
const cli = @import("flags/cli.zig");
const format = @import("cmd/fmt.zig");
const lsp = @import("cmd/lsp.zig").run;
const outline = @import("cmd/outline.zig").exec;
const std = @import("std");

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

/// taken from https://github.com/Hejsil/zig-clap
const max_src_size = 2 * 1024 * 1024 * 1024; // 2 GiB

const app = Cli{
    .name = "hoodie",
    .flags = null,
    .commands = [_]Command{
        Command{
            .name = "fmt",
            .flags = [_]Flag{
                Flag{
                    .name = "f",
                    .kind = .Bool,
                },
                Flag{
                    .name = "stdin",
                    .kind = .Bool,
                },
            },
            .action = formatCmd,
            .sub_commands = null,
        },
        Command{
            .name = "outline",
            .flags = [_]Flag{Flag{
                .name = "modified",
                .kind = .Bool,
            }},
            .action = outlineCmd,
            .sub_commands = null,
        },
        Command{
            .name = "lsp",
            .flags = null,
            .action = lspCmd,
            .sub_commands = null,
        },
    },
    .action = null,
};

var stdout_file: fs.File = undefined;
var stdout_file_out_stream: fs.File.OutStream = undefined;
var stdout_stream: ?*io.OutStream(fs.File.WriteError) = null;

pub fn main() anyerror!void {
    var direct_allocator = std.heap.DirectAllocator.init();
    const allocator = &direct_allocator.allocator;
    defer direct_allocator.deinit();
    const arg = try std.process.argsAlloc(allocator);
    defer allocator.free(arg);
    try app.run(allocator, arg[1..]);
}

pub fn getStdoutStream() !*io.OutStream(fs.File.WriteError) {
    if (stdout_stream) |st| {
        return st;
    } else {
        stdout_file = try io.getStdOut();
        stdout_file_out_stream = stdout_file.outStream();
        const st = &stdout_file_out_stream.stream;
        stdout_stream = st;
        return st;
    }
}

fn formatCmd(
    ctx: *const Context,
) anyerror!void {
    const stdout = try getStdoutStream();
    return format.format(ctx.allocator, stdout);
}

fn outlineCmd(
    ctx: *const Context,
) anyerror!void {
    var stdin_file = try io.getStdIn();
    var stdin = &stdin_file.inStream().stream;
    const stdout = try getStdoutStream();
    if (ctx.boolean("modified")) {
        const source_code = try stdin.readAllAlloc(ctx.allocator, max_src_size);
        defer ctx.allocator.free(source_code);
        return outline(ctx.allocator, source_code, stdout);
    }
}

fn lspCmd(
    ctx: *const Context,
) anyerror!void {}

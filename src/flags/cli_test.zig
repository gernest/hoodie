const cli = @import("cli.zig");
const std = @import("std");

const Args = cli.Args;
const Cli = cli.Cli;
const Command = cli.Command;
const Context = cli.Context;
const Flag = cli.Flag;
const FlagItem = cli.FlagSet.FlagItem;
const testing = std.testing;
const warn = std.debug.warn;

test "command" {
    var a = std.debug.global_allocator;

    const app = Cli{
        .name = "hoodie",
        .flags = null,
        .commands = [_]Command{
            Command{
                .name = "fmt",
                .flags = [_]Flag{Flag{
                    .name = "f",
                    .kind = .Bool,
                }},
                .action = nothing,
                .sub_commands = null,
            },
            Command{
                .name = "outline",
                .flags = [_]Flag{Flag{
                    .name = "modified",
                    .kind = .Bool,
                }},
                .action = nothing,
                .sub_commands = null,
            },
        },
        .action = nothing,
    };

    // check for correct commands
    const TestCase = struct {
        src: []const []const u8,
        command: ?[]const u8,
        mode: Context.Mode,
        flags: ?[]const FlagItem,
    };

    const cases = [_]TestCase{
        TestCase{
            .src = [_][]const u8{},
            .command = null,
            .mode = .Global,
            .flags = null,
        },
        TestCase{
            .src = [_][]const u8{"fmt"},
            .command = "fmt",
            .mode = .Local,
            .flags = null,
        },
        TestCase{
            .src = [_][]const u8{"outline"},
            .command = "outline",
            .mode = .Local,
            .flags = null,
        },
        TestCase{
            .src = [_][]const u8{ "outline", "some", "args" },
            .command = "outline",
            .mode = .Local,
            .flags = null,
        },
        TestCase{
            .src = [_][]const u8{ "outline", "--modified", "args" },
            .command = "outline",
            .mode = .Local,
            .flags = [_]FlagItem{FlagItem{
                .flag = Flag{
                    .name = "modified",
                    .kind = .Bool,
                },
                .index = 1,
            }},
        },
    };

    for (cases) |ts| {
        var args = &try Args.initList(a, ts.src);
        var ctx = &try app.parse(a, args);
        testing.expectEqual(ts.mode, ctx.mode);
        if (ts.command) |cmd| {
            testing.expectEqual(ctx.command.?.name, cmd);
        }
        if (ts.flags) |flags| {
            switch (ctx.mode) {
                .Local => {
                    for (flags) |flag, idx| {
                        const got = ctx.local_flags.list.at(idx);
                        testing.expectEqual(flag, got);
                    }
                },
                .Global => {},
                else => unreachable,
            }
        }
        args.deinit();
    }
}

fn nothing(
    ctx: *const Context,
) anyerror!void {}

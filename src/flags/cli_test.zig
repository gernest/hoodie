const cli = @import("cli.zig");
const std = @import("std");

const Args = cli.Args;

const Cli = cli.Cli;
const Command = cli.Command;
const Context = cli.Context;
const Flag = cli.Flag;
const testing = std.testing;

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
    };

    const cases = [_]TestCase{
        TestCase{
            .src = [_][]const u8{},
            .command = null,
            .mode = .Global,
        },
        TestCase{
            .src = [_][]const u8{"fmt"},
            .command = null,
            .mode = .Local,
        },
    };

    for (cases) |ts| {
        var args = &try Args.initList(a, ts.src);
        var ctx = &try app.parse(a, args);
        testing.expectEqual(ts.mode, ctx.mode);
        args.deinit();
    }
}

fn nothing(
    ctx: *const Context,
) anyerror!void {}

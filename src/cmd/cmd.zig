const std = @import("std");
const format = @import("fmt.zig");
const outline = @import("outline.zig");
const lsp = @import("lsp.zig");
const pkg = @import("pkg.zig");

const cli = @import("../flags/cli.zig");
const Args = cli.Args;
const Cli = cli.Cli;
const Command = cli.Command;
const Context = cli.Context;
const Flag = cli.Flag;

pub const app = Cli{
    .name = "hoodie",
    .flags = null,
    .commands = [_]Command{
        format.command,
        outline.command,
        lsp.command,
        pkg.command,
    },
    .action = null,
};

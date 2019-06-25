const std = @import("std");
const format = @import("cmd/fmt");
const outline = @import("cmd/outline");
const lsp = @import("cmd/lsp");
const pkg = @import("cmd/packages");

const cli = @import("flags");

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

const std = @import("std");
const exports = @import("../pkg/exports/exports.zig");
const flags = @import("../flags/cli.zig");

const Command = flags.Command;
const Flag = flags.Flag;
const Context = flags.Context;

pub const command = Command{
    .name = "exports",
    .flags = null,
    .action = null,
};

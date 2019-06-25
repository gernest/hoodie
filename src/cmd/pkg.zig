const std = @import("std");
const flags = @import("flags");

const exports = @import("pkg/exports.zig");
const Command = flags.Command;
const Flag = flags.Flag;
const Context = flags.Context;

pub const command = Command{
    .name = "pkg",
    .flags = null,
    .action = null,
    .sub_commands = [_]Command{exports.command},
};

const std = @import("std");

const ast = std.zig.ast;
const render = std.zig.render;
const io = std.io;
const mem = std.mem;
const os = std.os;

const cli = @import("flags");
const Command = cli.Command;
const Context = cli.Context;
const Flag = cli.Flag;

/// taken from https://github.com/Hejsil/zig-clap
const max_src_size = 2 * 1024 * 1024 * 1024; // 2 GiB

pub const command = Command{
    .name = "fmt",
    .flags = [_]Flag{
        Flag{
            .name = "f",
            .desc = "filename to be formated",
            .kind = .String,
        },
        Flag{
            .name = "stdin",
            .desc = "reads text to format from stdin",
            .kind = .Bool,
        },
    },
    .action = formatCmd,
    .sub_commands = null,
};

pub fn format(allocator: *mem.Allocator, source_code: []const u8, stdout: var) !void {
    var tree = std.zig.parse(allocator, source_code) catch |err| {
        std.debug.warn("error parsing stdin: {}\n", err);
        os.exit(1);
    };
    defer tree.deinit();
    if (tree.errors.count() > 0) {
        var stderr = try std.debug.getStderrStream();
        var error_it = tree.errors.iterator(0);
        while (error_it.next()) |parse_error| {
            try renderError(
                allocator,
                "<stdin>",
                tree,
                parse_error,
                stderr,
            );
        }
        os.exit(1);
    }
    _ = try render(allocator, stdout, tree);
}

fn renderError(
    a: *mem.Allocator,
    file_path: []const u8,
    tree: *ast.Tree,
    parse_error: *const ast.Error,
    stream: var,
) !void {
    const loc = parse_error.loc();
    const loc_token = parse_error.loc();
    var text_buf = try std.Buffer.initSize(a, 0);
    defer text_buf.deinit();
    var out_stream = &std.io.BufferOutStream.init(&text_buf).stream;
    try parse_error.render(&tree.tokens, out_stream);
    const first_token = tree.tokens.at(loc);
    const start_loc = tree.tokenLocationPtr(0, first_token);
    try stream.print(
        "{}:{}:{}: error: {}\n",
        file_path,
        start_loc.line + 1,
        start_loc.column + 1,
        text_buf.toSlice(),
    );
}

fn formatCmd(
    ctx: *const Context,
) anyerror!void {
    const source_code = try ctx.stdin.?.readAllAlloc(ctx.allocator, max_src_size);
    defer ctx.allocator.free(source_code);
    if (ctx.boolean("stdin")) {
        return format(ctx.allocator, source_code, ctx.stdout.?);
    }
}

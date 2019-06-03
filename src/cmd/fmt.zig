const render = @import("imports.zig").render;
const std = @import("std");

const ast = std.zig.ast;

const io = std.io;
const mem = std.mem;
const os = std.os;

const max_src_size = 2 * 1024 * 1024 * 1024; // 2 GiB

pub fn format(allocator: *mem.Allocator, stdout: var) !void {
    var stdin_file = try io.getStdIn();
    var stdin = stdin_file.inStream();

    const source_code = try stdin.stream.readAllAlloc(allocator, max_src_size);
    defer allocator.free(source_code);

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

pub fn formatFile(allocator: *mem.Allocator, file_path: []const u8, stdout: var) !void {
    const source_code = try std.io.readFileAlloc(allocator, file_path);
    defer allocator.free(source_code);

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
                file_path,
                tree,
                parse_error,
                stderr,
            );
        }
        os.exit(1);
    }
    const baf = try io.BufferedAtomicFile.create(allocator, file_path);
    defer baf.destroy();
    _ = try render(allocator, baf.stream(), tree);
    try baf.finish();
}

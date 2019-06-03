const jsonrpc2 = @import("../lsp/jsonrpc2/jsonrpc2.zig");
const std = @import("std");

const Conn = jsonrpc2.Conn;
const Context = jsonrpc2.Context;
const Loop = std.event.Loop;

fn echo(h: *const Conn.Handler, ctx: *Context) anyerror!void {
    ctx.response.result = ctx.request.params;
}

const echo_handler = Conn.Handler{ .handleFn = echo };

pub fn run(
    a: *std.mem.Allocator,
    in_stream: var,
    out_stream: var,
) anyerror!void {
    var loop: Loop = undefined;
    try loop.initSingleThreaded(a);
    defer loop.deinit();
    var conn = Conn.init(a, &echo_handler);
    try conn.serve(&loop, in_stream, out_stream);
}

const std = @import("std");
const io = std.io;
const rpc = @import("jsonrpc2.zig");
const warn = std.debug.warn;
const testing = std.testing;

test "Conn.readRequestData" {
    const src = "Content-Length: 43\r\n\r\n{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"example\"}";
    var stream = &io.SliceInStream.init(src).stream;
    var a = std.debug.global_allocator;
    var buf = &try std.Buffer.init(a, "");
    defer buf.deinit();
    try rpc.RPC.Conn.readRequestData(buf, stream);
    const message =
        \\{"jsonrpc":"2.0","id":1,"method":"example"}
    ;
    testing.expect(buf.eql(message));
}

const std = @import("std");
const io = std.io;
const rpc = @import("jsonrpc2.zig");
const warn = std.debug.warn;
const testing = std.testing;
const Buffer = std.Buffer;
const json = std.json;
const mem = std.mem;
const Dump = @import("../json/json.zig").Dump;

test "Conn.readRequestData" {
    const src = "Content-Length: 43\r\n\r\n{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"example\"}";
    var stream = &io.SliceInStream.init(src).stream;
    var a = std.debug.global_allocator;
    var buf = &try std.Buffer.init(a, "");
    defer buf.deinit();
    try rpc.Conn.readRequestData(buf, stream);
    const message =
        \\{"jsonrpc":"2.0","id":1,"method":"example"}
    ;
    testing.expect(buf.eql(message));
}

fn testEncode(buf: *Buffer, object: var, want: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(buf.list.allocator);
    defer arena.deinit();
    var alloc = &arena.allocator;
    var dump = &try Dump.init(alloc);

    try buf.resize(0);
    var stream = &std.io.BufferOutStream.init(buf).stream;
    var v = object.encode(alloc);
    try dump.dump(v, stream);
    // warn("{}\n", buf.toSlice());
    // warn("{}\n", buf.eql(want));
    testing.expect(buf.eql(want));
}

fn testEncodeErr(buf: *Buffer, object: var, want: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(buf.list.allocator);
    defer arena.deinit();
    var alloc = &arena.allocator;
    var dump = &try Dump.init(alloc);
    try buf.resize(0);
    var stream = &std.io.BufferOutStream.init(buf).stream;
    var v = try object.encode(alloc);
    try dump.dump(v, stream);
    // warn("\n{}\n", buf.toSlice());
}

test "rpc.ID" {
    var a = std.debug.global_allocator;
    var buf = &try std.Buffer.init(a, "");
    defer buf.deinit();

    var name_id = rpc.ID{ .Name = "id" };
    try testEncode(buf, name_id,
        \\"id"
    );

    var number_id = rpc.ID{ .Number = 1 };
    try testEncode(buf, number_id,
        \\1
    );

    var id: rpc.ID = undefined;
    try (&id).decode(json.Value{ .Integer = 1 });
    testing.expectEqual(id.Number, 1);

    try (&id).decode(json.Value{ .String = "id" });
    testing.expect(mem.eql(u8, id.Name, "id"));
}

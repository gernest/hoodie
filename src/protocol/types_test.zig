const std = @import("std");
const types = @import("types.zig");
const dump = @import("../json/json.zig").dump;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

test "encode" {
    const ts = types.ImplementationClientCapabilities;

    var da = std.heap.DirectAllocator.init();
    defer da.deinit();
    var a = &da.allocator;

    try testEncode(types.ImplementationClientCapabilities, &da.allocator, ts{
        .textDocument = ts.TextDocumentImpl{
            .implementation = ts.TextDocumentImpl.Implementation{
                .dynamicRegistration = true,
                .linkSupport = true,
            },
        },
    },
        \\{"textDocument":{"implementation":{"dynamicRegistration":true,"linkSupport":true}}}
    );

    try testEncode(types.ImplementationServerCapabilities, &da.allocator, types.ImplementationServerCapabilities{
        .implementationProvider = true,
    },
        \\{"implementationProvider":true}
    );
}

fn testEncode(comptime T: type, a: *Allocator, value: T, out: []const u8) !void {
    var buf = &try std.Buffer.init(a, "");
    defer buf.deinit();
    var arena = &std.heap.ArenaAllocator.init(a);
    defer arena.deinit();

    var v = try value.encode(&arena.allocator);
    var stream = std.io.BufferOutStream.init(buf);
    try dump(v, &stream.stream);
    expect(buf.eql(out));
}

const std = @import("std");
const types = @import("types.zig");
const dump = @import("../json/json.zig").dump;
const expect = std.testing.expect;

test "ImplementationClientCapabilities" {
    const ts = types.ImplementationClientCapabilities;
    const s = ts{
        .textDocument = ts.TextDocumentImpl{
            .implementation = ts.TextDocumentImpl.Implementation{
                .dynamicRegistration = true,
                .linkSupport = true,
            },
        },
    };

    var da = std.heap.DirectAllocator.init();
    defer da.deinit();
    var a = &da.allocator;
    var arena = &std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    var buf = &try std.Buffer.init(a, "");
    defer buf.deinit();
    var stream = std.io.BufferOutStream.init(buf);

    var v = try (&s).encode(&arena.allocator);
    const expect_json =
        \\{"textDocument":{"implementation":{"dynamicRegistration":true,"linkSupport":true}}}
    ;
    try dump(v, &stream.stream);
    expect(buf.eql(expect_json));
}

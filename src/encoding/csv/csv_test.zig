const csv = @import("csv.zig");
const std = @import("std");

const io = std.io;
const warn = std.debug.warn;
const testing = std.testing;

const WriterTest = struct {
    input: []const []const u8,
    output: []const u8,
    use_crlf: bool,
    comma: u8,

    fn init(
        input: []const []const u8,
        output: []const u8,
        use_crlf: bool,
        comma: u8,
    ) WriterTest {
        return WriterTest{
            .input = input,
            .output = output,
            .use_crlf = use_crlf,
            .comma = comma,
        };
    }
};

const writer_test_list = [_]WriterTest{
    WriterTest.init([_][]const u8{"abc"}, "abc\n", false, 0),
    WriterTest.init([_][]const u8{"abc"}, "abc\r\n", true, 0),
    WriterTest.init([_][]const u8{"\"abc\""}, "\"\"\"abc\"\"\"\n", false, 0),
    WriterTest.init([_][]const u8{"a\"b"}, "\"a\"\"b\"\n", false, 0),
    WriterTest.init([_][]const u8{"\"a\"b\""}, "\"\"\"a\"\"b\"\"\"\n", false, 0),
    WriterTest.init([_][]const u8{" abc"}, "\" abc\"\n", false, 0),
    WriterTest.init([_][]const u8{"abc,def"}, "\"abc,def\"\n", false, 0),
    WriterTest.init([_][]const u8{ "abc", "def" }, "abc,def\n", false, 0),
};

test "csv.Writer" {
    var buf = &try std.Buffer.init(std.debug.global_allocator, "");
    defer buf.deinit();
    var buffer_stream = io.BufferOutStream.init(buf);
    var w = &csv.Writer.init(&buffer_stream.stream);
    for (writer_test_list) |ts, id| {
        w.use_crlf = false;
        if (ts.use_crlf) {
            w.use_crlf = true;
        }
        try buf.resize(0);
        try w.write(ts.input);
        try w.flush();
        testing.expect(buf.eql(ts.output));
    }
}

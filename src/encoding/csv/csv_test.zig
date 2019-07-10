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
    WriterTest.init([_][]const u8{"abc\ndef"}, "\"abc\ndef\"\n", false, 0),
    WriterTest.init([_][]const u8{"abc\ndef"}, "\"abc\r\ndef\"\r\n", true, 0),
    WriterTest.init([_][]const u8{"abc\rdef"}, "\"abcdef\"\r\n", true, 0),
    WriterTest.init([_][]const u8{"abc\rdef"}, "\"abc\rdef\"\n", false, 0),
    WriterTest.init([_][]const u8{""}, "\n", false, 0),
    WriterTest.init([_][]const u8{ "", "" }, ",\n", false, 0),
    WriterTest.init([_][]const u8{ "", "", "" }, ",,\n", false, 0),
    WriterTest.init([_][]const u8{ "", "", "a" }, ",,a\n", false, 0),
    WriterTest.init([_][]const u8{ "", "a", "" }, ",a,\n", false, 0),
    WriterTest.init([_][]const u8{ "", "a", "a" }, ",a,a\n", false, 0),
    WriterTest.init([_][]const u8{ "a", "", "" }, "a,,\n", false, 0),
    WriterTest.init([_][]const u8{ "a", "", "a" }, "a,,a\n", false, 0),
    WriterTest.init([_][]const u8{ "a", "a", "" }, "a,a,\n", false, 0),
    WriterTest.init([_][]const u8{ "a", "a", "a" }, "a,a,a\n", false, 0),
    WriterTest.init([_][]const u8{"\\."}, "\"\\.\"\n", false, 0),
    WriterTest.init([_][]const u8{ "x09\x41\xb4\x1c", "aktau" }, "x09\x41\xb4\x1c,aktau\n", false, 0),
    WriterTest.init([_][]const u8{ ",x09\x41\xb4\x1c", "aktau" }, "\",x09\x41\xb4\x1c\",aktau\n", false, 0),
    WriterTest.init([_][]const u8{ "a", "a", "" }, "a|a|\n", false, '|'),
    WriterTest.init([_][]const u8{ ",", ",", "" }, ",|,|\n", false, '|'),
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
        if (ts.comma != 0) {
            w.comma = ts.comma;
        }
        try buf.resize(0);
        try w.write(ts.input);
        try w.flush();
        testing.expect(buf.eql(ts.output));
    }
}

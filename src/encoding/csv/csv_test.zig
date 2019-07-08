const csv = @import("csv.zig");
const std = @import("std");

const WriterTest = struct {
    input: []const []const u8,
    output: []const u8,
    use_ctrl: bool,
    comma: u8,

    fn init(
        input: []const []const u8,
        output: []const u8,
        use_ctrl: bool,
        comma: u8,
    ) WriterTest {
        return WriterTest{
            .input = input,
            .output = output,
            .use_ctrl = use_ctrl,
            .comma = comma,
        };
    }
};

const writer_test_list = []WriterTest{
    WriterTest.init([_][]const u8{"abc"}, "abc\n", false, 0),
    WriterTest.init([_][]const u8{"abc"}, "abc\r\n", true, 0),
    WriterTest.init([_][]const u8{"\"abc\""}, "\"\"\"abc\"\"\"\n", false, 0),
    WriterTest.init([_][]const u8{"a\"b"}, "\"a\"\"b\"\n", false, 0),
    WriterTest.init([_][]const u8{"\"a\"b\""}, "\"\"\"a\"\"b\"\"\"\n", false, 0),
    WriterTest.init([_][]const u8{" abc"}, "\" abc\"\n", false, 0),
};

const markdown = @import("markdown.zig");
const std = @import("std");
const suite = @import("test_suite.zig");

const Lexer = markdown.Lexer;
const TestCase = suite.TestCase;
const warn = std.debug.warn;

test "Lexer" {
    var lx = &Lexer.init(std.debug.global_allocator);
    defer lx.deinit();
    try lx.run();
}

test "Lexer.findSetextHeading" {
    const Helper = struct {
        fn testTwo(case: *const TestCase, expect: [2]?usize) void {
            testfindSetextHeading(case, expect[0..]);
        }

        fn testOne(case: *const TestCase, expect: [1]?usize) void {
            testfindSetextHeading(case, expect[0..]);
        }

        fn testThree(case: *const TestCase, expect: [3]?usize) void {
            testfindSetextHeading(case, expect[0..]);
        }
        fn testfindSetextHeading(case: *const TestCase, expect: []const ?usize) void {
            const size = case.markdown.len;
            var current_pos: usize = 0;
            var j: usize = 0;
            for (expect) |value, ix| {
                if (current_pos < size) {
                    if (Lexer.findSetextHeading(case.markdown[current_pos..])) |idx| {
                        current_pos += idx;
                        if (value) |expect_value| {
                            if (current_pos != expect_value) {
                                warn(
                                    "error: {} expected offset={} got offset={}\n",
                                    case.example,
                                    expect_value,
                                    current_pos,
                                );
                            }
                        } else {
                            warn(
                                "error: {} expected offset=null got offset={}\n",
                                case.example,
                                current_pos,
                            );
                        }
                    } else {
                        if (value != null) {
                            warn(
                                "error: {} expected offset={} got offset=null\n",
                                case.example,
                                value,
                            );
                        }
                    }
                }
            }
        }
    };
    const one = Helper.testOne;
    const two = Helper.testTwo;
    const three = Helper.testThree;
    const cases = suite.all_cases[49..75];
    two(&cases[0], [_]?usize{ 19, 40 });
}

test "Lexer.findFencedCodeBlock" {}

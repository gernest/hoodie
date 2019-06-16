const std = @import("std");
const Allocator = std.mem.Allocator;
const unicode = std.unicode;
const warn = std.debug.warn;
const mem = std.mem;

const form_feed = 0x0C;
const line_tabulation = 0x0B;
const space = ' ';

const Position = struct {
    begin: usize,
    end: usize,
};

const Lexer = struct {
    input: []const u8,
    state: ?*lexState,

    /// This is the current position in the input stream.
    current_pos: usize,

    /// start_pos index on the current token starting point in the input stream
    start_pos: usize,

    width: usize,

    /// position of the last emitted token.
    last_pos: ?Position,

    lexme_list: LexMeList,
    allocator: *Allocator,

    fn init(allocator: *Allocator) Lexer {
        var lx: Lexer = undefined;
        lx.allocator = allocator;
        lx.lexme_list = LexMeList.init(allocator);
        return lx;
    }

    fn deinit(self: *Lexer) void {
        self.lexme_list.deinit();
    }

    fn next(self: *Lexer) !?u32 {
        if (self.current_pos >= self.input.len) {
            return null;
        }
        const c = try unicode.utf8Decode(self.input[self.current_pos..]);
        const width = try unicode.utf8CodepointSequenceLength(c);
        self.width = @intCast(usize, width);
        self.current_pos += self.width;
        return c;
    }

    fn backup(self: *Lexer) void {
        self.current_pos -= self.width;
    }

    fn peek(self: *Lexer) !?u32 {
        const r = try self.next();
        self.backup();
        return r;
    }

    fn run(self: *Lexer) !void {
        self.state = lex_any;
        while (self.state) |state| {
            self.state = try state.lex(self);
        }
    }

    const lexState = struct {
        lexFn: fn (lx: *lexState, lexer: *Lexer) anyerror!?*lexState,

        fn lex(self: *lexState, lx: *Lexer) !?*lexState {
            return self.lexFn(self, lx);
        }
    };

    const LexMeList = std.ArrayList(LexMe);

    const LexMe = struct {
        id: Id,
        pos: Position,
        const Id = enum {
            EOF,
            NewLine,
            HTML,
            Heading,
            BlockQuote,
            List,
            ListItem,
            FencedCodeBlock,
            Hr, // horizontal rule
            Table,
            LpTable,
            TableRow,
            TableCell,
            Strong,
            Italic,
            Strike,
            Code,
            Link,
            DefLink,
            RefLink,
            AutoLink,
            Image,
            RefImage,
            Text,
            Br,
            Pipe,
            Indent,
        };
    };

    const IterLine = struct {
        src: []const u8,
        current_pos: usize,

        fn init(src: []const u8, current_pos: usize) IterLine {
            return IterLine{
                .src = src,
                .current_pos = current_pos,
            };
        }

        fn next(self: *IterLine) ?Position {
            if (self.current_pos >= self.src.len) {
                return null;
            }
            if (Util.index(self.src[self.current_pos..], "\n")) |idx| {
                const c = self.current_pos;
                self.current_pos += idx + 1;
                return Position{
                    .begin = c,
                    .end = self.current_pos - 1,
                };
            }
            const c = self.current_pos;
            self.current_pos = self.src.len;
            return Position{
                .begin = c,
                .end = self.current_pos,
            };
        }

        fn reset(self: *IterLine, src: []const u8, pos: usize) void {
            self.current_pos = pos;
            self.src = src;
        }
    };

    fn emit(self: *Lexer, id: LexMe.Id) !void {
        var a = &self.lexme_list;
        try a.append(LexMe{
            .id = id,
            .pos = Position{
                .begin = self.start_pos,
                .end = self.current_pos,
            },
        });
        self.start_pos = self.current_pos;
    }

    // findSetextHeading checks if in is begins with a setext heading. Returns
    // the offset of the heading relative to the beginning of the in where the
    // setext block ends.
    //
    // The returned offset includes the - or == sequence line up to and
    // including its line ending.
    fn findSetextHeading(in: []const u8) ?usize {
        if (Util.isBlank(in)) {
            return null;
        }
        // If setext sequence char is at the begininning of input then we
        // treat it as break.
        if (in[0] == '-' or in[0] == '=') {
            return null;
        }
        const x = Util.indentation(in);
        if (x <= 3 and (x + 1 < in.len)) {
            const c = in[x + 1];
            if (c == '-' or c == '=') {
                return null;
            }
        }

        if (findSetextSequence(in)) |seq| {
            const idx = seq.idx;
            var scratch: [2]?Position = undefined;
            var iter = &IterLine.init(in[0..idx], 0);
            while (iter.next()) |pos| {
                const line = in[pos.begin..pos.end];
                if (Util.isBlank(line)) {
                    // This can span multiple lines when they don't contain a
                    // blank line.
                    scratch[0] = null;
                    scratch[1] = null;
                    continue;
                }
                if (scratch[0] == null) {
                    scratch[0] = pos;
                } else {
                    scratch[1] = pos;
                }
                const indent = Util.indentation(in[pos.begin..pos.end]);
                if (indent > 3) {
                    return null;
                }
            }
            if (scratch[0] == null and scratch[1] == null) {
                return null;
            }
            iter.reset(in, idx);
            const pos = iter.next();
            if (pos == null) {
                return null;
            }
            const line = in[pos.?.begin..pos.?.end];

            // what is left is to verify that line conforms to a valid setext
            // sequence line.

            var space_zone = false;
            const indent = Util.indentation(line);
            for (line[indent..]) |c| {
                if (c == seq.char) {} else {
                    if (Util.isHorizontalSpace(c)) {
                        if (!space_zone) {
                            space_zone = true;
                        }
                    } else {
                        if (Util.isHorizontalSpace(c)) {
                            if (!space_zone) {
                                space_zone = true;
                            }
                        } else {
                            return null;
                        }
                    }
                }
            }
            return pos.?.end;
        }
        return null;
    }

    const Seq = struct {
        char: u8,
        idx: usize,
    };

    fn findSetextSequence(in: []const u8) ?Seq {
        if (Util.index(in, "=")) |idx| {
            return Seq{ .char = '=', .idx = idx };
        }
        if (Util.index(in, "-")) |idx| {
            return Seq{ .char = '-', .idx = idx };
        }
        return null;
    }

    // returns position for Thematic breaks
    //
    // see https://github.github.com/gfm/#thematic-breaks
    fn findHorizontalRules(in: []const u8) ?usize {
        const indent = Util.indentation(in);
        if (indent > 3) {
            return null;
        }
        var index = in.len;
        if (Util.index(in, "\n")) |idx| {
            index = idx;
        }
        const hr_prospect = in[indent..index];
        var active_char: ?u8 = null;
        var space_zone = false;
        for (hr_prospect) |c| {
            switch (c) {
                '-', '_', '*' => {
                    if (space_zone) {
                        return null;
                    }
                    if (active_char) |char| {
                        if (char != c) {
                            return null;
                        }
                    }
                },
                else => {
                    if (Util.isHorizontalSpace(c)) {
                        if (!space_zone) {
                            space_zone = true;
                        }
                    } else {
                        return null;
                    }
                },
            }
        }
        var o: usize = 0;
        if (index == in.len) {
            o = index;
        } else {
            o = index + 1;
        }
        return o;
    }

    const fenced_tilde_prefix = [][]const u8{
        "", "", "", "```", "````", "`````", "``````", "```````",
    };

    const fenced_backtick_prefix = [][]const u8{
        "", "", "", "~~~", "~~~~", "~~~~~", "~~~~~~", "~~~~~~~",
    };

    // returns position for Fenced code blocks
    //
    // see https://github.github.com/gfm/#fenced-code-blocks
    fn findFencedCodeBlock(in: []const u8) ?usize {
        const indent = Util.indentation(in);
        const block = in[indent..];
        var fenced_char = block[0];
        switch (fenced_char) {
            '`', '~' => {},
            else => {
                return null;
            },
        }
        const count = Util.countStartsWith(block, fenced_char);
        // This is enforced by this library. It is just madness to have seven
        // backticks just describing a code block
        if (count < 3 or count > 7) {
            return null;
        }

        // checking the info string
        if (Util.index(in, "\n")) |idx| {

            // we are adding indent here to preserve offsets relative to in
            // because the position we return are from in stream.
            var i = indent + count + 1;
            while (i < idx) {
                if (in[i] == fenced_char) {
                    return null;
                }
                i += 1;
            }
            const closing_index = switch (fenced_char) {
                '~' => fenced_tilde_prefix[count],
                '`' => fenced_backtick_prefix[count],
                else => unreachable,
            };
            if (Util.index(in[i..], closing_index)) |idx| {

                // The closing fenced block line may be indented, we are walking
                // backward to count the amount of indentation
                var indent_count: usize = 0;
                var j = idx - 1;
                while (j > 0) : (j -= 1) {
                    const c = in[j];
                    switch (c) {
                        ' ', '\t' => {
                            indent_count += 1;
                        },
                        else => {
                            if (Util.isVersicalSpace(c)) {
                                break;
                            }
                            return null;
                        },
                    }
                }
                if (indent_count > 3) {
                    return null;
                }
                j = idx + closing_index.len;
                while (j < in.len) : (j += 1) {
                    // After the closing code block. The line must only contain
                    // spaces
                    const c = in[j];
                    if (Util.isVersicalSpace(c)) {
                        break;
                    }
                    if (Util.isHorizontalSpace(c)) {
                        continue;
                    }
                    return null;
                }
                return j;
            }
        }
        return null;
    }

    const lex_any = &AnyLexer.init().state;
    const lex_heading = &HeadingLexer.init().state;
    const lex_horizontal_rule = &HorizontalRuleLexer.init().state;
    const lex_code_block = &CodeBlockLexer.init().state;
    const lex_text = &TextLexer.init().state;
    const lex_html = &HTMLLexer.init().state;
    const lex_list = &ListLexer.init().state;
    const lex_block_quote = &BlockQuoteLexer.init().state;
    const lex_def_link = &DefLinkLexer.init().state;
    const lex_fenced_code_block = &FencedCodeBlockLexer.init().state;

    const AnyLexer = struct {
        state: lexState,
        fn init() AnyLexer {
            return AnyLexer{
                .state = lexState{ .lexFn = lexFn },
            };
        }

        fn lexFn(self: *lexState, lx: *Lexer) !?*lexState {
            while (try lx.peek()) |r| {
                switch (r) {
                    '*', '-', '_' => {
                        return lex_horizontal_rule;
                    },
                    '+', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
                        return lex_list;
                    },
                    '<' => {
                        return lex_html;
                    },
                    '>' => {
                        return lex_block_quote;
                    },
                    '[' => {
                        return lex_def_link;
                    },
                    '`', '~' => {
                        return lex_fenced_code_block;
                    },
                    '#' => {
                        return lex_heading;
                    },
                    else => {},
                }
            }
            return null;
        }
    };

    const HeadingLexer = struct {
        state: lexState,
        fn init() HeadingLexer {
            return HeadingLexer{
                .state = lexState{ .lexFn = lexFn },
            };
        }
        fn lexFn(self: *lexState, lx: *Lexer) !?*lexState {
            return error.TODO;
        }
    };

    const HorizontalRuleLexer = struct {
        state: lexState,
        fn init() HorizontalRuleLexer {
            return HorizontalRuleLexer{
                .state = lexState{ .lexFn = lexFn },
            };
        }
        fn lexFn(self: *lexState, lx: *Lexer) anyerror!?*lexState {
            if (findHorizontalRules(lx.input[lx.current_pos..])) |pos| {
                lx.current_pos += pos;
                try lx.emit(LexMe.Id.Hr);
                return lex_any;
            }
            return lex_list;
        }
    };

    const CodeBlockLexer = struct {
        state: lexState,
        fn init() CodeBlockLexer {
            return CodeBlockLexer{
                .state = lexState{ .lexFn = lexFn },
            };
        }
        fn lexFn(self: *lexState, lx: *Lexer) !?*lexState {
            return error.TODO;
        }
    };

    const TextLexer = struct {
        state: lexState,

        fn init() TextLexer {
            return TextLexer{
                .state = lexState{ .lexFn = lexFn },
            };
        }

        fn lexFn(self: *lexState, lx: *Lexer) !?*lexState {
            while (try lx.peek()) |r| {
                switch (r) {
                    '\n' => {
                        if (lx.current_pos > lx.start_pos and Util.hasPrefix(lx.input[lx.current_pos + 1 ..], "    ")) {
                            _ = try lx.next();
                            continue;
                        }
                        if (lx.current_pos > ls.start_pos) {
                            try lx.emit(LexMe.Text);
                        }
                        lx.pos += lx.width;
                        try lx.emit(LexMe.NewLine);
                        break;
                    },
                    else => {
                        if (findSetextHeading(lx.input[lx.current_pos..])) |pos| {
                            lx.current_pos += end;
                            try lx.emit(LexMe.Heading);
                            break;
                        }
                        _ = try lx.next();
                    },
                }
            }
            return lex_any;
        }
    };

    const HTMLLexer = struct {
        state: lexState,
        fn init() HTMLLexer {
            return HTMLLexer{
                .state = lexState{ .lexFn = lexFn },
            };
        }
        fn lexFn(self: *lexState, lx: *Lexer) !?*lexState {
            return error.TODO;
        }
    };

    const ListLexer = struct {
        state: lexState,
        fn init() ListLexer {
            return ListLexer{
                .state = lexState{ .lexFn = lexFn },
            };
        }
        fn lexFn(self: *lexState, lx: *Lexer) !?*lexState {
            return error.TODO;
        }
    };

    const BlockQuoteLexer = struct {
        state: lexState,
        fn init() BlockQuoteLexer {
            return BlockQuoteLexer{
                .state = lexState{ .lexFn = lexFn },
            };
        }
        fn lexFn(self: *lexState, lx: *Lexer) !?*lexState {
            return error.TODO;
        }
    };

    const DefLinkLexer = struct {
        state: lexState,
        fn init() DefLinkLexer {
            return DefLinkLexer{
                .state = lexState{ .lexFn = lexFn },
            };
        }
        fn lexFn(self: *lexState, lx: *Lexer) !?*lexState {
            return error.TODO;
        }
    };

    const FencedCodeBlockLexer = struct {
        state: lexState,
        fn init() FencedCodeBlockLexer {
            return FencedCodeBlockLexer{
                .state = lexState{ .lexFn = lexFn },
            };
        }
        fn lexFn(self: *lexState, lx: *Lexer) !?*lexState {
            return error.TODO;
        }
    };
};

// Util are utility/helper functions.
const Util = struct {
    const punct_marks = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~";
    fn isPunct(c: u8) bool {
        for (punct_marks) |char| {
            if (c == char) {
                return true;
            }
        }
        return false;
    }

    // returns true if s is a blank line.
    fn isBlank(s: []const u8) bool {
        if (s.len == 0) {
            return true;
        }
        for (s) |c| {
            if (!isHorizontalSpace(c)) {
                return false;
            }
        }
        return true;
    }

    /// returns true if c is a whitespace character.
    fn isSpace(c: u8) bool {
        return isHorizontalSpace(c) or isVersicalSpace(c);
    }

    fn isBackslashEscaped(data: []const u8, i: usize) bool {
        var bs: usize = 0;
        while ((@intCast(isize, i) - @intCast(isize, bs) - 1) >= 0 and data[i - bs - 1] == '\\') {
            bs += 1;
        }
        return bs == 1;
    }

    fn isHorizontalSpace(c: u8) bool {
        return c == ' ' or c == '\t';
    }

    fn isVersicalSpace(c: u8) bool {
        return c == '\n' or c == '\r' or c == form_feed or c == line_tabulation;
    }

    fn isLetter(c: u8) bool {
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z');
    }

    fn isalnum(c: u8) bool {
        return (c >= '0' and c <= '9') or isLetter(c);
    }

    // Find if a line counts as indented or not.
    // Returns number of characters the indent is (0 = not indented).
    fn isIndented(data: []const u8, indent_size: usize) usize {
        if (data.len == 0) {
            return 0;
        }
        if (data[0] == '\t') {
            return 1;
        }
        if (data.len < indent_size) {
            return 0;
        }
        var i: usize = 0;
        while (i < indent_size) : (i += 1) {
            if (data[i] != space) {
                return 0;
            }
        }
        return indent_size;
    }

    fn indentation(data: []const u8) usize {
        if (data.len == 0) {
            return 0;
        }
        if (data[0] == '\t') {
            return 1;
        }

        var i: usize = 0;
        var idx: usize = 0;
        while (i < data.len) : (i += 1) {
            if (data[i] != ' ') {
                break;
            }
            idx += 1;
        }
        return idx;
    }

    // countStartsWith counts c character occurance from the beginning of data.
    fn countStartsWith(data: []const u8, c: u8) usize {
        if (data.len == 0) {
            return 0;
        }
        var i: usize = 0;
        while (i < data.len) {
            if (c != data[i]) {
                break;
            }
        }
        return i;
    }

    /// returns true if sub_slice is within s.
    pub fn contains(s: []const u8, sub_slice: []const u8) bool {
        return mem.indexOf(u8, s, sub_slice) != null;
    }

    pub fn index(s: []const u8, sub_slice: []const u8) ?usize {
        return mem.indexOf(u8, s, sub_slice);
    }

    /// hasPrefix returns true if slice s begins with prefix.
    pub fn hasPrefix(s: []const u8, prefix: []const u8) bool {
        return s.len >= prefix.len and
            equal(s[0..prefix.len], prefix);
    }

    pub fn hasSuffix(s: []const u8, suffix: []const u8) bool {
        return s.len >= suffix.len and
            equal(s[s.len - suffix.len ..], suffix);
    }

    pub fn trimPrefix(s: []const u8, prefix: []const u8) []const u8 {
        return mem.trimLeft(u8, s, prefix);
    }

    pub fn trimSuffix(s: []const u8, suffix: []const u8) []const u8 {
        return mem.trimRight(u8, s, suffix);
    }

    fn skipUntilChar(text: []const u8, start: usize, c: usize) usize {
        var i = start;
        while (i < tag.len and text[i] != c) : (i += 1) {}
        return i;
    }

    fn skipSpace(tag: []const u8, i: usize) usize {
        while (i < tag.len and isSpace(tag[i])) : (i += 1) {}
        return i;
    }

    fn skipChar(data: []const u8, start: usize, c: u8) usize {
        var i = start;
        while (i < data.len and data[i] == c) : (i += 1) {}
        return i;
    }

    fn isRelativeLink(link: []const u8) bool {
        if (link[0] == '#') {
            return true;
        }
        if (link.len >= 2 and link[0] == '/' and link[1] != '/') {
            return true;
        }
        // current directory : begin with "./"
        if (hasPrefix(link, "./")) {
            return true;
        }
        // parent directory : begin with "../"
        if (hasPrefix(link, "../")) {
            return true;
        }
        return false;
    }
};

const suite = @import("test_suite.zig");
const TestCase = suite.TestCase;
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
    two(&cases[0], []?usize{ 19, 40 });
}

test "Lexer.findFencedCodeBlock" {}

const Parser = struct {
    const Node = struct {
        id: Id,
        const Id = enum {
            Text, // A plain text
            Paragraph, // A Paragraph
            Emphasis, // An emphasis(strong, em, ...)
            Heading, // A heading (h1, h2, ...)
            Br, // A link break
            Hr, // A horizontal rule
            Image, // An image
            RefImage, // A image reference
            List, // A list of ListItems
            ListItem, // A list item node
            Link, // A link(href)
            RefLink, // A link reference
            DefLink, // A link definition
            Table, // A table of Rows
            Row, // A row of Cells
            Cell, // A table-cell(td)
            Code, // A code block(wrapped with pre)
            BlockQuote, // A blockquote
            HTML, // An inline HTML
        };

        const NodeList = ArrayList(*Node);

        fn NodeBase(base: type) type {
            return struct {
                id: Id,
                base: base,
            };
        }

        const Paragraph = struct {
            const Self = @This();
            pos: Position,
            nodes: ?NodeList,
            const Context = NodeBase(Self);

            fn init(pos: Position, nodes: ?NodeList) Context {
                return Context{
                    .id = Id.Paragraph,
                    .base = Self{
                        .pos = pos,
                        .nodes = nodes,
                    },
                };
            }
        };

        const Text = struct {
            const Self = @This();
            pos: Position,
            const Context = NodeBase(Self);
            fn init(pos: Position) Context {
                return Context{
                    .id = Id.Text,
                    .base = Self{ .pos = pos },
                };
            }
        };

        const HTML = struct {
            const Self = @This();
            pos: Position,

            const Context = NodeBase(Self);

            fn init(pos: Position) Context {
                return Context{
                    .id = Id.HTML,
                    .base = Self{ .pos = pos },
                };
            }
        };

        const HR = struct {
            const Self = @This();
            pos: Position,
            const Context = NodeBase(Self);
            fn init(pos: Position) Context {
                return Context{
                    .id = Id.Br,
                    .base = Self{ .pos = pos },
                };
            }
        };

        const BR = struct {
            const Self = @This();
            pos: Position,
            const Context = NodeBase(Self);
            fn init(pos: Position) Context {
                return Context{
                    .id = Id.Hr,
                    .base = Self{ .pos = pos },
                };
            }
        };

        const Emphasis = struct {
            const Self = @This();
            pos: Position,
            style: Lexer.LexMe,
            nodes: ?NodeList,

            const Context = NodeBase(Self);

            fn init(pos: Position, style: Lexer.LexMe, nodes: ?NodeList) Context {
                return Context{
                    .id = Id.Emphasis,
                    .base = Self{
                        .pos = pos,
                        .style = style,
                        .nodes = nodes,
                    },
                };
            }
        };

        const Heading = struct {
            const Self = @This();
            pos: Position,
            levels: usize, //(0.6)
            text: Position,
            nodes: ?NodeList,

            const Context = NodeBase(Self);

            fn init(pos: Position, levels: usize, text: Position, nodes: ?NodeList) Context {
                return Context{
                    .id = Id.Heading,
                    .base = Self{
                        .pos = pos,
                        .levels = levels,
                        .text = text,
                        .nodes = nodes,
                    },
                };
            }
        };

        const Code = struct {
            const Self = @This();
            pos: Position,
            lang: ?Position,
            text: Position,

            const Context = NodeBase(Self);

            fn init(pos: Position, levels: usize, text: Position) Context {
                return Context{
                    .id = Id.Code,
                    .base = Self{
                        .pos = pos,
                        .text = text,
                    },
                };
            }
        };

        const Link = struct {
            const Self = @This();
            pos: Position,
            title: ?Position,
            href: ?Position,
            nodes: ?NodeList,

            const Context = NodeBase(Self);

            fn init(pos: Position, title: ?Position, href: ?Position, nodes: ?NodeList) Context {
                return Context{
                    .id = Id.Link,
                    .base = Self{
                        .pos = pos,
                        .title = title,
                        .href = href,
                        .nodes = nodes,
                    },
                };
            }
        };
    };
};

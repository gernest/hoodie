const std = @import("std");
const Buffer = std.Buffer;

pub const EXTENSION_NO_INTRA_EMPHASIS = 1;
pub const EXTENSION_TABLES = 2;
pub const EXTENSION_FENCED_CODE = 4;
pub const EXTENSION_AUTOLINK = 8;
pub const EXTENSION_STRIKETHROUGH = 16;
pub const EXTENSION_LAX_HTML_BLOCKS = 32;
pub const EXTENSION_SPACE_HEADERS = 64;
pub const EXTENSION_HARD_LINE_BREAK = 128;
pub const EXTENSION_TAB_SIZE_EIGHT = 256;
pub const EXTENSION_FOOTNOTES = 512;
pub const EXTENSION_NO_EMPTY_LINE_BEFORE_BLOCK = 1024;
pub const EXTENSION_HEADER_IDS = 2048;
pub const EXTENSION_TITLEBLOCK = 4096;
pub const EXTENSION_AUTO_HEADER_IDS = 8192;
pub const EXTENSION_BACKSLASH_LINE_BREAK = 16384;
pub const EXTENSION_DEFINITION_LISTS = 32768;
pub const EXTENSION_JOIN_LINES = 65536;

pub const LINK_TYPE_NOT_AUTOLINK = 1;
pub const LINK_TYPE_NORMAL = 2;
pub const LINK_TYPE_EMAIL = 4;

pub const LIST_TYPE_ORDERED = 1;
pub const LIST_TYPE_DEFINITION = 2;
pub const LIST_TYPE_TERM = 4;
pub const LIST_ITEM_CONTAINS_BLOCK = 8;
pub const LIST_ITEM_BEGINNING_OF_LIST = 16;
pub const LIST_ITEM_END_OF_LIST = 32;

pub const TABLE_ALIGNMENT_LEFT = 1;
pub const TABLE_ALIGNMENT_RIGHT = 2;
pub const TABLE_ALIGNMENT_CENTER = 3;

pub const TAB_SIZE_DEFAULT = 4;
pub const TAB_SIZE_EIGHT = 8;

pub const TextIter = struct {
    nextFn: fn (x: *TextIter) bool,
    pub fn text(self: *TextIter) bool {
        return self.nextFn(self);
    }
};

pub const Renderer = struct {
    //block-level
    blockCodeFn: fn (r: *Renderer, out: *Buffer, text: []const u8, info_string: []const u8) void,
    blockQuoteFn: fn (r: *Renderer, out: *Buffer, text: []const u8) void,
    blockHtmlFn: fn (r: *Renderer, out: *Buffer, text: []const u8) void,
    headerFn: fn (r: *Renderer, out: *Buffer, text: *TextIter, level: usize, id: []const u8) void,
    hruleFn: fn (r: *Renderer, out: *Buffer) void,
    listFn: fn (r: *Renderer, out: *Buffer, text: *TextIter, flags: usize) void,
    listItemFn: fn (r: *Renderer, out: *Buffer, text: []const u8, flags: usize) void,
    paragraphFn: fn (r: *Renderer, out: *Buffer, text: *TextIter) void,
    tableFn: fn (r: *Renderer, out: *Buffer, header: []const u8, body: []const u8, colum_data: []usize) void,
    tableRowFn: fn (r: *Renderer, out: *Buffer, text: []const u8) void,
    tableHeaderCellFn: fn (r: *Renderer, out: *Buffer, text: []const u8, flags: usize) void,
    tableCellFn: fn (r: *Renderer, out: *Buffer, text: []const u8, flags: usize) void,
    footnotesFn: fn (r: *Renderer, out: *Buffer, text: *TextIter) void,
    footnoteItemFn: fn (r: *Renderer, out: *Buffer, name: []const u8, text: []const u8, flags: usize) void,
    titleBlockFn: fn (r: *Renderer, out: *Buffer, text: []const u8) void,

    pub fn blockCode(self: *Renderer, out: *Buffer, text: []const u8, info_string: []const u8) void {
        self.blockCodeFn(self, out, text, info_string);
    }
    pub fn blockQuote(self: *Renderer, out: *Buffer, text: []const u8) void {
        self.blockQuoteFn(self, out, text);
    }
    pub fn blockHtml(self: *Renderer, out: *Buffer, text: []const u8) void {
        self.blockHtmlFn(self, out, text);
    }
    pub fn header(self: *Renderer, out: *Buffer, text: *TextIter, level: usize, id: []const u8) void {
        self.headerFn(self, out, text, level, id);
    }
    pub fn hrule(self: *Renderer, out: *Buffer) void {
        self.hruleFn(self, out);
    }
    pub fn list(self: *Renderer, out: *Buffer, text: *TextIter, flags: usize) void {
        self.listFn(self, out, text, flags);
    }
    pub fn listItem(self: *Renderer, out: *Buffer, text: []const u8, flags: usize) void {
        self.listItemFn(self, out, text, flags);
    }
    pub fn paragraph(self: *Renderer, out: *Buffer, text: *TextIter) void {
        self.paragraphFn(self, out, text);
    }
    pub fn table(self: *Renderer, out: *Buffer, header: []const u8, body: []const u8, colum_data: []usize) void {
        self.tableFn(self, out, header, body, colum_data);
    }
    pub fn tableRow(self: *Renderer, out: *Buffer, text: []const u8) void {
        self.tableRowFn(self, out, text);
    }
    pub fn tableHeaderCell(self: *Renderer, out: *Buffer, text: []const u8, flags: usize) void {
        self.tableHeaderCellFn(self, out, text, flags);
    }
    pub fn tableCell(self: *Renderer, out: *Buffer, text: []const u8, flags: usize) void {
        self.tableCellFn(self, out, text, flags);
    }
    pub fn footnotes(self: *Renderer, out: *Buffer, text: *TextIter) void {
        self.footnotesFn(self, out, text);
    }
    pub fn footnoteItem(self: *Renderer, out: *Buffer, name: []const u8, text: []const u8, flags: usize) void {
        self.footnoteItemFn(self, out, name, text, flags);
    }
    pub fn titleBlock(self: *Renderer, out: *Buffer, text: []const u8) void {
        self.titleBlockFn(self, out, text);
    }
};

pub const HTML_SKIP_HTML = 1;
pub const HTML_SKIP_STYLE = 2;
pub const HTML_SKIP_IMAGES = 4;
pub const HTML_SKIP_LINKS = 8;
pub const HTML_SAFELINK = 16;
pub const HTML_NOFOLLOW_LINKS = 32;
pub const HTML_NOREFERRER_LINKS = 64;
pub const HTML_HREF_TARGET_BLANK = 128;
pub const HTML_TOC = 256;
pub const HTML_OMIT_CONTENTS = 512;
pub const HTML_COMPLETE_PAGE = 1024;
pub const HTML_USE_XHTML = 2048;
pub const HTML_USE_SMARTYPANTS = 4096;
pub const HTML_SMARTYPANTS_FRACTIONS = 8192;
pub const HTML_SMARTYPANTS_DASHES = 16384;
pub const HTML_SMARTYPANTS_LATEX_DASHES = 32768;
pub const HTML_SMARTYPANTS_ANGLED_QUOTES = 65536;
pub const HTML_SMARTYPANTS_QUOTES_NBSP = 131072;
pub const HTML_FOOTNOTE_RETURN_LINKS = 262144;

pub const HTML = struct {
    flags: usize,
    close_tag: []const u8,
    title: ?[]const u8,
    css: ?[]const u8,
    render_params: Params,
    toc_marker: usize,
    header_count: usize,
    current_level: usize,
    toc: *Buffer,

    pub const Params = struct {};
    const xhtml_close = "/>";
    const html_close = ">";

    fn escapeChar(ch: u8) bool {
        return switch (ch) {
            '"', '&', '<', '>' => true,
            else => false,
        };
    }

    fn escapeSingleChar(buf: *Buffer, char: u8) !void {
        switch (char) {
            '"' => {
                try buf.append("&quot;");
            },
            '&' => {
                try buf.append("&amp;");
            },
            '<' => {
                try buf.append("&lt;");
            },
            '>' => {
                try buf.append("&gt;");
            },
            else => {},
        }
    }

    fn escapeSingleChar(buf: *Buffer, src: []const u8) !void {
        var o: usize = 0;
        for (src) |s, i| {
            if (escapeChar(s)) {
                if (i > o) {
                    try buf.append(src[o..i]);
                }
                o = i + 1;
                try escapeSingleChar(buf, s);
            }
        }
        if (o < src.len) {
            try buf.append(src[o..]);
        }
    }

    fn titleBlock(r: *Renderer, buf: *Buffer, text: []const u8) !void {}
};

const std = @import("std");

const ascii = std.ascii;
const mem = std.mem;
const io = std.io;

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

const common_extensions = 0 |
    EXTENSION_NO_INTRA_EMPHASIS |
    EXTENSION_TABLES |
    EXTENSION_FENCED_CODE |
    EXTENSION_AUTOLINK |
    EXTENSION_STRIKETHROUGH |
    EXTENSION_SPACE_HEADERS |
    EXTENSION_HEADER_IDS |
    EXTENSION_BACKSLASH_LINE_BREAK |
    EXTENSION_DEFINITION_LISTS;

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
    blockCodeFn: fn (r: *Renderer, out: *Buffer, text: []const u8, info_string: []const u8) anyerror!void,
    blockQuoteFn: fn (r: *Renderer, out: *Buffer, text: []const u8) anyerror!void,
    blockHtmlFn: fn (r: *Renderer, out: *Buffer, text: []const u8) anyerror!void,
    headerFn: fn (r: *Renderer, out: *Buffer, text: *TextIter, level: usize, id: ?[]const u8) anyerror!void,
    hruleFn: fn (r: *Renderer, out: *Buffer) anyerror!void,
    listFn: fn (r: *Renderer, out: *Buffer, text: *TextIter, flags: usize) anyerror!void,
    listItemFn: fn (r: *Renderer, out: *Buffer, text: []const u8, flags: usize) anyerror!void,
    paragraphFn: fn (r: *Renderer, out: *Buffer, text: *TextIter) anyerror!void,
    tableFn: fn (r: *Renderer, out: *Buffer, header: []const u8, body: []const u8, colum_data: []usize) anyerror!void,
    tableRowFn: fn (r: *Renderer, out: *Buffer, text: []const u8) anyerror!void,
    tableHeaderCellFn: fn (r: *Renderer, out: *Buffer, text: []const u8, flags: usize) anyerror!void,
    tableCellFn: fn (r: *Renderer, out: *Buffer, text: []const u8, flags: usize) anyerror!void,
    footnotesFn: fn (r: *Renderer, out: *Buffer, text: *TextIter) anyerror!void,
    footnoteItemFn: fn (r: *Renderer, out: *Buffer, name: []const u8, text: []const u8, flags: usize) anyerror!void,
    titleBlockFn: fn (r: *Renderer, out: *Buffer, text: []const u8) anyerror!void,

    // Span-level callbacks
    autoLinkFn: fn (r: *Renderer, buf: *Buffer, link: []const u8, kind: usize) anyerror!void,
    codeSpanFn: fn (r: *Renderer, buf: *Buffer, text: []const u8) anyerror!void,
    doubleEmphasisFn: fn (r: *Renderer, buf: *Buffer, text: []const u8) anyerror!void,
    emphasisFn: fn (r: *Renderer, buf: *Buffer, text: []const u8) anyerror!void,
    imageFn: fn (r: *Renderer, buf: *Buffer, link: []const u8, title: ?[]const u8, alt: ?[]const u8) anyerror!void,
    lineBreakFn: fn (r: *Renderer, buf: *Buffer) anyerror!void,
    linkFn: fn (r: *Renderer, buf: *Buffer, link: []const u8, title: ?[]const u8, content: []const u8) anyerror!void,
    rawHtmlTagFn: fn (r: *Renderer, buf: *Buffer, tag: []const u8) anyerror!void,
    tripleEmphasisFn: fn (r: *Renderer, buf: *Buffer, text: []const u8) anyerror!void,
    strikeThroughFn: fn (r: *Renderer, buf: *Buffer, text: []const u8) anyerror!void,
    footnoteRefFn: fn (r: *Renderer, buf: *Buffer, ref: []const u8, id: usize) anyerror!void,

    // Low-level callbacks
    entityFn: fn (r: *Renderer, buf: *Buffer, entity: []const u8) anyerror!void,
    normalTextFn: fn (r: *Renderer, buf: *Buffer, text: []const u8) anyerror!void,

    // Header and footer
    documentHeaderFn: fn (r: *Renderer, buf: *Buffer) anyerror!void,
    documentFooterFn: fn (r: *Renderer, buf: *Buffer) anyerror!void,

    getFlagsFn: fn (r: *Renderer) usize,

    pub fn blockCode(self: *Renderer, out: *Buffer, text: []const u8, info_string: []const u8) anyerror!void {
        try self.blockCodeFn(self, out, text, info_string);
    }
    pub fn blockQuote(self: *Renderer, out: *Buffer, text: []const u8) anyerror!void {
        try self.blockQuoteFn(self, out, text);
    }
    pub fn blockHtml(self: *Renderer, out: *Buffer, text: []const u8) anyerror!void {
        try self.blockHtmlFn(self, out, text);
    }
    pub fn header(self: *Renderer, out: *Buffer, text: *TextIter, level: usize, id: []const u8) anyerror!void {
        try self.headerFn(self, out, text, level, id);
    }
    pub fn hrule(self: *Renderer, out: *Buffer) anyerror!void {
        try self.hruleFn(self, out);
    }
    pub fn list(self: *Renderer, out: *Buffer, text: *TextIter, flags: usize) anyerror!void {
        try self.listFn(self, out, text, flags);
    }
    pub fn listItem(self: *Renderer, out: *Buffer, text: []const u8, flags: usize) anyerror!void {
        try self.listItemFn(self, out, text, flags);
    }
    pub fn paragraph(self: *Renderer, out: *Buffer, text: *TextIter) anyerror!void {
        try self.paragraphFn(self, out, text);
    }
    pub fn table(self: *Renderer, out: *Buffer, header: []const u8, body: []const u8, colum_data: []usize) anyerror!void {
        try self.tableFn(self, out, header, body, colum_data);
    }
    pub fn tableRow(self: *Renderer, out: *Buffer, text: []const u8) anyerror!void {
        try self.tableRowFn(self, out, text);
    }
    pub fn tableHeaderCell(self: *Renderer, out: *Buffer, text: []const u8, flags: usize) anyerror!void {
        try self.tableHeaderCellFn(self, out, text, flags);
    }
    pub fn tableCell(self: *Renderer, out: *Buffer, text: []const u8, flags: usize) anyerror!void {
        try self.tableCellFn(self, out, text, flags);
    }
    pub fn footnotes(self: *Renderer, out: *Buffer, text: *TextIter) anyerror!void {
        try self.footnotesFn(self, out, text);
    }
    pub fn footnoteItem(self: *Renderer, out: *Buffer, name: []const u8, text: []const u8, flags: usize) anyerror!void {
        try self.footnoteItemFn(self, out, name, text, flags);
    }

    pub fn titleBlock(self: *Renderer, out: *Buffer, text: []const u8) anyerror!void {
        try self.titleBlockFn(self, out, text);
    }

    pub fn autoLink(self: *Renderer, buf: *Buffer, link: []const u8, kind: usize) anyerror!void {
        try self.autoLinkFn(self, buf, link, kind);
    }

    pub fn codeSpan(self: *Renderer, buf: *Buffer, text: []const u8) anyerror!void {
        try self.codeSpanFn(self, buf, text);
    }

    pub fn doubleEmphasis(self: *Renderer, buf: *Buffer, text: []const u8) anyerror!void {
        try self.doubleEmphasisFn(self, buf, text);
    }

    pub fn emphasis(self: *Renderer, buf: *Buffer, text: []const u8) anyerror!void {
        try self.emphasisFn(self, buf, text);
    }

    pub fn image(self: *Renderer, buf: *Buffer, link: []const u8, title: []const u8, alt: []const u8) anyerror!void {
        try self.imageFn(self, buf, link, title, alt);
    }

    pub fn lineBreak(self: *Renderer, buf: *Buffer) anyerror!void {
        try self.lineBreakFn(self, buf);
    }

    pub fn link(self: *Renderer, buf: *Buffer, link: []const u8, title: ?[]const u8, content: []const u8) anyerror!void {
        try self.linkFn(self, buf, link, title, content);
    }

    pub fn rawHtmlTag(self: *Renderer, buf: *Buffer, tag: []const u8) anyerror!void {
        try self.rawHtmlTagFn(self, buf, tag);
    }

    pub fn tripleEmphasis(self: *Renderer, buf: *Buffer, text: []const u8) anyerror!void {
        try self.tripleEmphasisFn(self, buf, text);
    }

    pub fn strikeThrough(self: *Renderer, buf: *Buffer, text: []const u8) anyerror!void {
        try self.strikeThroughFn(self, buf, text);
    }

    pub fn footnoteRef(self: *Renderer, buf: *Buffer, ref: []const u8, id: usize) anyerror!void {
        try self.footnoteRefFn(self, buf, id);
    }

    pub fn entity(self: *Renderer, buf: *Buffer, entity: []const u8) anyerror!void {
        try self.entityFn(self, buf, entity);
    }

    pub fn normalText(self: *Renderer, buf: *Buffer, text: []const u8) anyerror!void {
        try self.normalTextFn(self, buf, text);
    }

    pub fn documentHeader(self: *Renderer, buf: *Buffer) anyerror!void {
        try self.documentHeaderFn(self, buf);
    }

    pub fn documentFooter(self: *Renderer, buf: *Buffer) anyerror!void {
        try self.documentFooterFn(self, buf);
    }

    pub fn getFlags(self: *Renderer) usize {
        try self.getFlagsFn(self);
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

const common_html_flags = 0 |
    HTML_USE_XHTML |
    HTML_USE_SMARTYPANTS |
    HTML_SMARTYPANTS_FRACTIONS |
    HTML_SMARTYPANTS_DASHES |
    HTML_SMARTYPANTS_LATEX_DASHES;

pub const ID = struct {
    txt: ?[]const u8,
    prefix: ?[]const u8,
    suffix: ?[]const u8,
    index: i64,
    toc: bool,

    pub fn init(
        txt: ?[]const u8,
        prefix: ?[]const u8,
        suffix: ?[]const u8,
        index: i64,
        toc: bool,
    ) ID {
        return ID{
            .txt = txt,
            .prefix = prefix,
            .suffix = suffix,
            .index = index,
            .toc = toc,
        };
    }

    pub fn valid(self: ID) bool {
        if (self.txt != null or self.toc) return true;
        return false;
    }

    pub fn format(
        self: ID,
        comptime fmt: []const u8,
        comptime options: std.fmt.FormatOptions,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        if (self.prefix) |prefix| {
            try output(context, prefix);
        }
        if (self.txt) |txt| {
            try output(context, txt);
        } else if (self.toc) {
            try output(context, "toc");
        }
        try std.fmt.format(
            context,
            Errors,
            output,
            "_{}",
            self.index,
        );
        if (self.suffix) |suffix| {
            try output(context, suffix);
        }
    }
};

pub const HTML = struct {
    flags: usize,
    close_tag: []const u8,
    title: ?[]const u8,
    css: ?[]const u8,
    params: Params,
    toc_marker: usize,
    header_count: i64,
    current_level: usize,
    toc: Buffer,
    renderer: Renderer,

    pub const Params = struct {
        absolute_prefix: ?[]const u8,
        footnote_anchor_prefix: ?[]const u8,
        footnote_return_link_contents: ?[]const u8,
        header_id_prefix: ?[]const u8,
        header_id_suffix: ?[]const u8,
    };

    const xhtml_close = "/>";
    const html_close = ">";

    pub fn init(a: *mem.Allocator) !HTML {
        return HTML{
            .flags = common_html_flags,
            .close_tag = html_close,
            .title = null,
            .css = null,
            .params = Params{
                .absolute_prefix = null,
                .footnote_anchor_prefix = null,
                .footnote_return_link_contents = "<sup>[return]</sup>",
                .header_id_prefix = null,
                .header_id_suffix = null,
            },
            .toc_marker = 0,
            .header_count = 0,
            .current_level = 0,
            .toc = try Buffer.init(a, ""),
            .renderer = Renderer{
                .blockCodeFn = blockCode,
                .blockQuoteFn = blockQuote,
                .blockHtmlFn = blockQuote,
                .headerFn = header,
                .hruleFn = hrule,
                .listFn = list,
                .listItemFn = listItem,
                .paragraphFn = paragraph,
                .tableFn = table,
                .tableRowFn = tableRow,
                .tableHeaderCellFn = tableHeaderCell,
                .tableCellFn = tableCell,
                .footnotesFn = footnotes,
                .footnoteItemFn = footnoteItem,
                .titleBlockFn = titleBlock,
                .autoLinkFn = autoLink,
                .codeSpanFn = codeSpan,
                .doubleEmphasisFn = doubleEmphasis,
                .emphasisFn = emphasis,
                .imageFn = image,
                .lineBreakFn = lineBreak,
                .linkFn = link,
                .rawHtmlTagFn = rawHtmlTag,
                .tripleEmphasisFn = tripleEmphasis,
                .strikeThroughFn = strikeThrough,
                .footnoteRefFn = footnoteRef,
                .entityFn = entity,
                .normalTextFn = normalText,
                .documentHeaderFn = documentHeader,
                .documentFooterFn = documentFooter,
                .getFlagsFn = getFlags,
            },
        };
    }

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

    fn attrEscape(buf: *Buffer, src: []const u8) !void {
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

    // naiveReplace simple replacing occurance of orig ,with with contents while
    // writing the result to buf.
    // Not optimized.
    fn naiveReplace(buf: *Buffer, src: []const u8, orig: []const u8, with: []const u8) !void {
        if (src.len < orig.len) return;
        var s = src;
        var start: usize = 0;
        while (orig.len < s.len) {
            if (mem.indexOf(u8, s, orig)) |idx| {
                try buf.append(s[start..idx]);
                try buf.append(with);
                start += idx + with.len;
            } else {
                break;
            }
        }
        if (start < s.len) {
            try buf.append(s[start..]);
        }
    }

    fn titleBlock(r: *Renderer, buf: *Buffer, text: []const u8) !void {
        try buf.append("<h1 class=\"title\">");
        const txt = mem.trimLeft(u8, text, "% ");
        try naiveReplace(buf, txt, "\n% ", "\n");
        try buf.append("\n</h1>");
    }

    fn doubleSpace(buf: *Buffer) !void {
        if (buf.len() > 0) {
            try buf.appendByte('\n');
        }
    }

    fn getHeaderID(self: *HTML) i64 {
        const id = self.header_count;
        self.header_count += 1;
        return id;
    }

    fn printBuffer(buf: *Buffer, comptime fmt: []const u8, args: ...) !void {
        var stream = &io.BufferOutStream.init(buf).stream;
        try stream.print(fmt, args);
    }

    fn header(
        r: *Renderer,
        buf: *Buffer,
        text: *TextIter,
        level: usize,
        id: ?[]const u8,
    ) !void {
        const marker = buf.len();
        try doubleSpace(buf);
        const self = @fieldParentPtr(HTML, "renderer", r);
        var stream = &io.BufferOutStream.init(buf).stream;
        const hid = ID.init(
            id,
            self.params.header_id_prefix,
            self.params.header_id_suffix,
            self.getHeaderID(),
            self.flags & HTML_TOC != 0,
        );
        if (hid.valid()) {
            try stream.print("<{} id=\"{}\"", level, hid);
        } else {
            try stream.print("<{}", level);
        }
        const toc_marker = buf.len();
        if (!text.text()) {
            try buf.resize(marker);
            return;
        }
        try stream.print("</h{}>\n", level);
    }

    fn blockHtml(r: *Renderer, buf: *Buffer, text: []const u8) !void {
        const self = @fieldParentPtr(HTML, "renderer", r);
        if (self.flags & HTML_SKIP_HTML != 0) {
            return;
        }
        try doubleSpace(buf);
        try buf.append(text);
        try buf.appendByte('\n');
    }

    fn hrule(r: *Renderer, buf: *Buffer) !void {
        const self = @fieldParentPtr(HTML, "renderer", r);
        try doubleSpace(buf);
        try buf.append("<hr");
        try buf.append(self.close_tag);
        try buf.appendByte('\n');
    }

    fn blockCode(
        r: *Renderer,
        buf: *Buffer,
        text: []const u8,
        info: []const u8,
    ) !void {
        try doubleSpace(buf);
        const self = @fieldParentPtr(HTML, "renderer", r);
        var end_of_lang: usize = 0;
        if (mem.indexOfAny(u8, info, "\t ")) |idx| {
            end_of_lang = idx;
        }
        const lang = if (end_of_lang != 0) info[0..end_of_lang] else "";
        if (lang.len == 0 or lang[0] == '.') {
            try buf.append("<pre><code>");
        } else {
            try buf.append("<pre><code class=\"language-)");
            try attrEscape(buf, lang);
            try buf.append("\">");
        }
        try buf.append(text);
        try buf.append("</code></pre>\n");
    }

    fn blockQuote(
        r: *Renderer,
        buf: *Buffer,
        text: []const u8,
    ) !void {
        try doubleSpace(buf);
        try buf.append("<blockquote>\n");
        try buf.append(text);
        try buf.append("</blockquote>\n");
    }

    fn table(
        r: *Renderer,
        buf: *Buffer,
        table_header: []const u8,
        body: []const u8,
        colum_data: []const usize,
    ) !void {
        try doubleSpace(buf);
        try buf.append("<table>\n<thead>\n");
        try buf.append(table_header);
        try buf.append("</thead>\n\n<tbody>\n");
        try buf.append(body);
        try buf.append("</tbody>\n</table>\n");
    }

    fn tableRow(
        r: *Renderer,
        buf: *Buffer,
        text: []const u8,
    ) !void {
        try doubleSpace(buf);
        try buf.append("<tr>\n");
        try buf.append(text);
        try buf.append("\n</tr>\n");
    }

    fn tableHeaderCell(
        r: *Renderer,
        buf: *Buffer,
        text: []const u8,
        alignment: usize,
    ) !void {
        try doubleSpace(buf);
        switch (alignment) {
            TABLE_ALIGNMENT_LEFT => {
                try buf.append("<th align=\"left\">");
            },
            TABLE_ALIGNMENT_RIGHT => {
                try buf.append("<th align=\"right\">");
            },
            TABLE_ALIGNMENT_CENTER => {
                try buf.append("<th align=\"center\">");
            },
            else => {
                try buf.append("<th>");
            },
        }
        try buf.append(text);
        try buf.append("</th>");
    }

    fn tableCell(
        r: *Renderer,
        buf: *Buffer,
        text: []const u8,
        alignment: usize,
    ) !void {
        try doubleSpace(buf);
        switch (alignment) {
            TABLE_ALIGNMENT_LEFT => {
                try buf.append("<td align=\"left\">");
            },
            TABLE_ALIGNMENT_RIGHT => {
                try buf.append("<td align=\"right\">");
            },
            TABLE_ALIGNMENT_CENTER => {
                try buf.append("<td align=\"center\">");
            },
            else => {
                try buf.append("<td>");
            },
        }
        try buf.append(text);
        try buf.append("</td>");
    }

    fn footnotes(
        r: *Renderer,
        buf: *Buffer,
        text: *TextIter,
    ) !void {
        try buf.append("<div class=\"footnotes\">\n");
        try r.hrule(buf);
        try r.list(buf, text, LIST_TYPE_ORDERED);
        try buf.append("</div>\n");
    }

    fn slugify(buf: *Buffer, src: []const u8) !void {
        if (src.len == 0) return;
        const m = buf.len();
        try buf.resize(m + src.len);
        var s = buf.toSlice()[m..];
        var sym = false;
        for (src) |ch, i| {
            if (ascii.isAlNum(ch)) {
                s[i] = ch;
            } else {
                s[i] = '-';
            }
        }
    }

    fn footnoteItem(
        r: *Renderer,
        buf: *Buffer,
        name: []const u8,
        text: []const u8,
        flags: usize,
    ) !void {
        if ((flags & LIST_ITEM_CONTAINS_BLOCK != 0) or (flags & LIST_ITEM_BEGINNING_OF_LIST != 0)) {
            try doubleSpace(buf);
        }
        const self = @fieldParentPtr(HTML, "renderer", r);
        try buf.append("<li id=\"fn:");
        if (self.params.footnote_anchor_prefix) |v| {
            try buf.append(v);
        }
        try slugify(buf, name);
        try buf.appendByte('>');
        try buf.append(text);
        if (self.flags & HTML_FOOTNOTE_RETURN_LINKS != 0) {
            try buf.append(" <a class=\"footnote-return\" href=\"#fnref:");
            if (self.params.footnote_anchor_prefix) |v| {
                try buf.append(v);
            }
            try slugify(buf, name);
            try buf.appendByte('>');
            if (self.params.footnote_return_link_contents) |v| {
                try buf.append(v);
            }
            try buf.append("</a>");
        }
        try buf.append("</li>\n");
    }

    fn list(
        r: *Renderer,
        buf: *Buffer,
        text: *TextIter,
        flags: usize,
    ) !void {
        const marker = buf.len();
        try doubleSpace(buf);
        if (flags & LIST_TYPE_DEFINITION != 0) {
            try buf.append("<dl>");
        } else if (flags & LIST_TYPE_ORDERED != 0) {
            try buf.append("<oll>");
        } else {
            try buf.append("<ul>");
        }
        if (!text.text()) {
            try buf.resize(marker);
        }
        if (flags & LIST_TYPE_DEFINITION != 0) {
            try buf.append("</dl>\n");
        } else if (flags & LIST_TYPE_ORDERED != 0) {
            try buf.append("</oll>\n");
        } else {
            try buf.append("</ul>\n");
        }
    }

    fn listItem(
        r: *Renderer,
        buf: *Buffer,
        text: []const u8,
        flags: usize,
    ) !void {
        if ((flags & LIST_ITEM_CONTAINS_BLOCK != 0 and
            flags & LIST_TYPE_DEFINITION != 0) or
            flags & LIST_ITEM_BEGINNING_OF_LIST != 0)
        {
            try doubleSpace(buf);
        }
        if (flags & LIST_TYPE_TERM != 0) {
            try buf.append("<dt>");
        } else if (flags & LIST_TYPE_DEFINITION != 0) {
            try buf.append("<dd>");
        } else {
            try buf.append("<li>");
        }
        try buf.append(text);
        if (flags & LIST_TYPE_TERM != 0) {
            try buf.append("</dt>\n");
        } else if (flags & LIST_TYPE_DEFINITION != 0) {
            try buf.append("</dd>\n");
        } else {
            try buf.append("</li>\n");
        }
    }

    fn paragraph(
        r: *Renderer,
        buf: *Buffer,
        text: *TextIter,
    ) !void {
        const marker = buf.len();
        try doubleSpace(buf);
        try buf.append("<p>");
        if (!text.text()) {
            try buf.resize(marker);
            return;
        }
        try buf.append("</p>\n");
    }

    fn autoLink(
        r: *Renderer,
        buf: *Buffer,
        link_: []const u8,
        kind: usize,
    ) !void {
        const self = @fieldParentPtr(HTML, "renderer", r);
        if (self.flags & HTML_SAFELINK != 0 and !Util.isSafeLink(link_) and
            kind != LINK_TYPE_EMAIL)
        {
            try buf.append("<tt>");
            try attrEscape(buf, link_);
            try buf.append("</tt>");
            return;
        }
        try buf.append("<a href=\"");
        if (kind == LINK_TYPE_EMAIL) {
            try buf.append("mailto:");
        } else {
            try self.maybeWriteAbsolutePrefix(buf, link_);
        }
        try attrEscape(buf, link_);
        var no_follow = false;
        var no_referer = false;
        if (self.flags & HTML_NOFOLLOW_LINKS != 0 and !Util.isRelativeLink(link_)) {
            no_follow = true;
        }
        if (self.flags & HTML_NOREFERRER_LINKS != 0 and !Util.isRelativeLink(link_)) {
            no_referer = true;
        }
        if (no_follow or no_referer) {
            try buf.append("\" rel=\"");
            if (no_follow) {
                try buf.append("nofollow");
            }
            if (no_referer) {
                try buf.append(" noreferrer");
            }
            try buf.appendByte('"');
        }
        if (self.flags & HTML_HREF_TARGET_BLANK != 0 and !Util.isRelativeLink(link_)) {
            try buf.append("\" target=\"_blank");
        }
        // Pretty print: if we get an email address as
        // an actual URI, e.g. `mailto:foo@bar.com`, we don't
        // want to print the `mailto:` prefix
        const mailto = "mailto://";
        if (mem.startsWith(u8, link_, mailto)) {
            try attrEscape(buf, link_[mailto.len..]);
        } else if (mem.startsWith(u8, link_, mailto[0 .. mailto.len - 2])) {
            try attrEscape(buf, link_[mailto.len - 2 ..]);
        } else {
            try attrEscape(buf, link_);
        }
        try buf.append("</a>");
    }

    fn maybeWriteAbsolutePrefix(
        self: *HTML,
        buf: *Buffer,
        link_: []const u8,
    ) !void {
        if (self.params.absolute_prefix != null and Util.isRelativeLink(link_) and
            link_[0] != '.')
        {
            try buf.append(self.params.absolute_prefix.?);
            if (link_[0] != '/') {
                try buf.appendByte('/');
            }
        }
    }

    fn codeSpan(
        r: *Renderer,
        buf: *Buffer,
        text: []const u8,
    ) !void {
        try buf.append("<code>");
        try attrEscape(buf, text);
        try buf.append("</code>");
    }

    fn doubleEmphasis(
        r: *Renderer,
        buf: *Buffer,
        text: []const u8,
    ) !void {
        try buf.append("<strong>");
        try attrEscape(buf, text);
        try buf.append("</strong>");
    }

    fn emphasis(
        r: *Renderer,
        buf: *Buffer,
        text: []const u8,
    ) !void {
        if (text.len == 0) return;
        try buf.append("<em>");
        try attrEscape(buf, text);
        try buf.append("</em>");
    }

    fn image(
        r: *Renderer,
        buf: *Buffer,
        link_: []const u8,
        title: ?[]const u8,
        alt: ?[]const u8,
    ) !void {
        const self = @fieldParentPtr(HTML, "renderer", r);
        if (self.flags & HTML_SKIP_IMAGES != 0) return;
        try buf.append("<img src=\"");
        try self.maybeWriteAbsolutePrefix(buf, link_);
        try attrEscape(buf, link_);
        try buf.append("\" alt=\"");
        if (alt) |v| {
            try attrEscape(buf, v);
        }
        if (title) |v| {
            try buf.append("\" title=\"");
            try attrEscape(buf, v);
        }
        try buf.appendByte('"');
        try buf.append(self.close_tag);
    }

    fn lineBreak(
        r: *Renderer,
        buf: *Buffer,
    ) !void {
        const self = @fieldParentPtr(HTML, "renderer", r);
        try buf.append("<br");
        try buf.append(self.close_tag);
        try buf.appendByte('\n');
    }

    fn link(
        r: *Renderer,
        buf: *Buffer,
        link_: []const u8,
        title: ?[]const u8,
        content: []const u8,
    ) !void {
        const self = @fieldParentPtr(HTML, "renderer", r);
        if (self.flags & HTML_SKIP_LINKS != 0) {
            try buf.append("<tt>");
            try attrEscape(buf, content);
            try buf.append("</tt>");
            return;
        }
        try buf.append("<a href=\"");
        try self.maybeWriteAbsolutePrefix(buf, link_);
        try attrEscape(buf, link_);
        if (title) |v| {
            try buf.append("\" title=\"");
            try attrEscape(buf, v);
        }
        var no_follow = false;
        var no_referer = false;
        if (self.flags & HTML_NOFOLLOW_LINKS != 0 and !Util.isRelativeLink(link_)) {
            no_follow = true;
        }
        if (self.flags & HTML_NOREFERRER_LINKS != 0 and !Util.isRelativeLink(link_)) {
            no_referer = true;
        }
        if (no_follow or no_referer) {
            try buf.append("\" rel=\"");
            if (no_follow) {
                try buf.append("nofollow");
            }
            if (no_referer) {
                try buf.append(" noreferrer");
            }
            try buf.appendByte('"');
        }
        if (self.flags & HTML_HREF_TARGET_BLANK != 0 and !Util.isRelativeLink(link_)) {
            try buf.append("\" target=\"_blank");
        }
        try buf.append("\">");
        try buf.append(content);
        try buf.append("</a>");
    }

    fn rawHtmlTag(
        r: *Renderer,
        buf: *Buffer,
        text: []const u8,
    ) !void {
        const self = @fieldParentPtr(HTML, "renderer", r);
        if (self.flags & HTML_SKIP_HTML != 0) {
            return;
        }
        if (self.flags & HTML_SKIP_STYLE != 0 and Util.isHtmlTag(text, "style")) {
            return;
        }
        if (self.flags & HTML_SKIP_LINKS != 0 and Util.isHtmlTag(text, "a")) {
            return;
        }
        if (self.flags & HTML_SKIP_IMAGES != 0 and Util.isHtmlTag(text, "img")) {
            return;
        }
        try buf.append(text);
    }

    fn tripleEmphasis(
        r: *Renderer,
        buf: *Buffer,
        text: []const u8,
    ) !void {
        try buf.append("<strong><em>");
        try buf.append(text);
        try buf.append("</em></strong>");
    }

    fn strikeThrough(
        r: *Renderer,
        buf: *Buffer,
        text: []const u8,
    ) !void {
        try buf.append("<del>");
        try buf.append(text);
        try buf.append("</del>");
    }

    fn footnoteRef(
        r: *Renderer,
        buf: *Buffer,
        ref: []const u8,
        id: usize,
    ) !void {
        const self = @fieldParentPtr(HTML, "renderer", r);
        try buf.append("<sup class=\"footnote-ref\" id=\"fnref:");
        if (self.params.footnote_anchor_prefix) |v| {
            try buf.append(v);
        }
        try slugify(buf, ref);
        try buf.append("\"><a href=\"#fn:");
        if (self.params.footnote_anchor_prefix) |v| {
            try buf.append(v);
        }
        try slugify(buf, ref);
        try buf.append("\">");
        try printBuffer(buf, "{}", id);
        try buf.append("</a></sup>");
    }
};

pub const Util = struct {
    const valid_urls = [_][]const u8{
        "http://", "https://", "ftp://", "mailto://",
    };

    const valid_paths = [_][]const u8{
        "/", "https://", "./", "../",
    };

    pub fn isSafeLink(link: []const u8) bool {
        for (valid_paths) |p| {
            if (mem.startsWith(u8, link, p)) {
                if (link.len == p.len) {
                    return true;
                }
                if (ascii.isAlNum(link[p.len])) {
                    return true;
                }
            }
        }
        for (valid_urls) |u| {
            if (link.len > u.len and eqlLower(link[0..u.len], u) and ascii.isAlNum(link[u.len])) {
                return true;
            }
        }
        return false;
    }

    /// eqlLower compares a, and b with all caharacters from aconverted to lower
    /// case.
    pub fn eqlLower(a: []const u8, b: []const u8) bool {
        if (a.len != b.len) return false;
        for (b) |v, i| {
            if (ascii.toLower(a[i]) != v) return false;
        }
        return true;
    }

    pub fn isRelativeLink(link: []const u8) bool {
        if (link.len == 0) return false;
        if (link[0] == '#') return true;
        // link begin with '/' but not '//', the second maybe a protocol relative link
        if (link.len >= 2 and link[0] == '/' and link[1] != '/') {
            return true;
        }
        // only the root '/'
        if (link.len == 1 and link[0] == '/') {
            return true;
        }
        // current directory : begin with "./"
        if (mem.startsWith(u8, link, "./")) {
            return true;
        }
        // parent directory : begin with "../"
        if (mem.startsWith(u8, link, "../")) {
            return true;
        }
        return false;
    }

    pub fn isHtmlTag(
        tag: []const u8,
        tag_name: []const u8,
    ) bool {
        if (findHtmlTagPos(tag, tag_name)) |_| return true;
        return false;
    }

    pub fn findHtmlTagPos(
        tag: []const u8,
        tag_name: []const u8,
    ) ?usize {
        var t = tag;
        var i: usize = 0;
        if (i < tag.len and tag[0] != '<') return null;
        i += 1;
        i = skipSpace(t, i);
        if (i < tag.len and tag[0] == '/') i += 1;
        i = skipSpace(t, i);
        var j: usize = 0;
        while (i < t.len) : ({
            i += 1;
            j += 1;
        }) {
            if (j >= tag_name.len) {
                break;
            }
            if (ascii.toLower(t[i]) != tag_name[j]) {
                return null;
            }
        }
        if (i == t.len) {
            return null;
        }
        const a = skipUntilCharIgnoreQuotes(t, i, '>');
        if (a > i) return a;
        return null;
    }

    fn skipUntilCharIgnoreQuotes(html: []const u8, start: usize, char: u8) usize {
        var s = false;
        var d = false;
        var g = false;
        var i = start;
        while (i < html.len) {
            if (html[i] == char and !s and !d and !g) {
                return i;
            } else if (html[i] == '\'') {
                s = !s;
            } else if (html[i] == '"') {
                d = !d;
            } else if (html[i] == '`') {
                g = !g;
            }
            i += 1;
        }
        return start;
    }

    pub fn skipSpace(s: []const u8, at: usize) usize {
        var v = s;
        var i = at;
        while (i < s.len) : (i += 1) {
            if (!ascii.isSpace(s[i])) {
                break;
            }
        }
        return i;
    }
};

pub const OkMap = std.AutoHash([]const u8, void);

pub const Parser = struct {
    r: *Renderer,
    refs: ReferenceMap,
    inline_callback: [256]?fn (
        p: *Parser,
        buf: *Buffer,
        data: []const u8,
        offset: usize,
    ) !usize,
    flags: usize,
    nesting: usize,
    max_nesting: usize,
    inside_link: bool,
    notes: std.ArrayList(*Reference),
    notes_record: OkMap,

    pub const ReferenceMap = std.AutoHash([]const u8, *Reference);

    pub const Reference = struct {
        link: ?[]const u8,
        title: ?[]const u8,
        note_id: usize,
        has_block: bool,
        text: ?[]const u8,
    };
};

test "HTML.test" {
    var a = std.debug.global_allocator;
    var h = try HTML.init(a);
}

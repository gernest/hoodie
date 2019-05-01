const std = @import("std");
const mem = std.mem;
const strings = @import("../strings/strings.zig");
const utf8 = @import("../unicode/utf8/index.zig");
const utf16 = @import("../unicode/utf16/index.zig");
const url = @import("../url/url.zig");
const unicode = @import("../unicode/index.zig");
const Allocator = mem.Allocator;
const Buffer = std.Buffer;
const filepath = @import("../filepath/filepath.zig");
const warn = std.debug.warn;

pub const Span = struct {
    uri: []const u8,
    start: Point,
    end: Point,

    pub fn init(uri: []const u8, start: Point, end: Point) Span {
        var s = Span{ .uri = uri, .start = .start, .end = end };
        clean(&s);
        return s;
    }

    pub fn format(
        self: Span,
        comptime fmt: []const u8,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        const full_form = mem.eql(u8, fmt, "+");
        const prefer_offset = mem.eql(u8, fmt, "#");
        try output(context, self.uri);
        if (!self.isValid() or (!full_form and self.start.isZero() and self.end.isZero())) {
            return;
        }
        const print_offset = self.hasOffset() and (full_form or prefer_offset or !self.hasPosition());
        var print_line = self.hasPosition() and (full_form or !print_offset);
        const print_column = print_line and (full_form or (self.start.column > 1 or self.end.column > 1));
        try output(context, ":");
        if (print_line) {
            try std.fmt.format(context, Errors, output, "{}", self.start.line);
        }
        if (print_column) {
            try std.fmt.format(context, Errors, output, ":{}", self.start.column);
        }
        if (print_offset) {
            try std.fmt.format(context, Errors, output, "#{}", self.start.offset);
        }
        if (self.isPoint()) {
            return;
        }
        print_line = full_form or (print_line and self.end.line > self.start.line);
        try output(context, "-");
        if (print_line) {
            try std.fmt.format(context, Errors, output, "{}", self.end.line);
        }
        if (print_column) {
            try std.fmt.format(context, Errors, output, ":{}", self.end.column);
        }
        if (print_offset) {
            try std.fmt.format(context, Errors, output, "#{}", self.end.offset);
        }
    }

    pub fn hasPosition(self: Span) bool {
        return self.start.hasPosition();
    }

    pub fn hasOffset(self: Span) bool {
        return self.start.hasOffset();
    }

    pub fn isValid(self: Span) bool {
        return self.start.isValid();
    }

    pub fn isPoint(self: Span) bool {
        return self.start.eql(self.end);
    }

    pub fn clean(self: *Span) void {
        if (self.end.isValid() or self.end.empty()) {
            self.end = self.start;
        }
    }
};

pub const Converter = struct {
    toPosition: fn (self: *Converter, offset: isize) anyerror!Position,
    toOffset: fn (self: *Converter, pos: Position) anyerror!isize,
};

pub const Position = struct {
    line: isize,
    column: isize,
};

pub const Point = struct {
    line: ?usize,
    column: ?usize,
    offset: ?usize,

    pub fn init(line: isize, column: isize, offset: isize) Point {
        var p = Point{ .line = line, .column = column, .offset = offset };
        clean(&p);
        return p;
    }

    pub fn hasPosition(self: Point) bool {
        return self.line > 0;
    }

    pub fn hasOffset(self: Point) bool {
        return self.offset > 0;
    }

    pub fn isValid(self: Point) bool {
        return self.hasPosition() or self.hasOffset();
    }

    pub fn isZero(self: Point) bool {
        return (self.line == 1 and self.column == 1) or (!self.hasPosition() and self.offset == 0);
    }

    pub fn empty(self: Point) bool {
        return (self.line == 0 and self.column == 0 and self.offset == 0);
    }

    pub fn clean(self: *Point) void {
        if (self.line == null) {
            self.line = 0;
        }
        if (self.column == null) {
            if (self.line > 0) {
                self.column = 1;
            } else {
                self.column = 0;
            }
        }
        if (self.offset == 0 and (self.line > 1 or p.column > 1)) {
            self.offset = -1;
        }
    }

    pub fn updatePosition(self: *Point, c: *Converter) anyerror!void {
        const pos = try c.toPosition(self.offset);
        self.line = pos.line;
        self.column = pos.column;
    }

    pub fn updateOffset(self: *Point, c: *Converter) anyerror!void {
        var pos = Position{ .line = self.line, .column = self.column };
        const o = try c.toOffset(pos);
        self.offset = o;
    }

    pub fn eql(self: Point, other: Point) bool {
        return compare(self, other) == mem.Compare.Equal;
    }

    pub fn compare(self: Point, other: Point) mem.Compare {
        if (!self.hasPosition()) {
            if (self.offset < other.offset) {
                return mem.Compare.LessThan;
            }
            if (self.offset > other.offset) {
                return mem.Compare.GreaterThan;
            }
            return mem.Compare.Equal;
        }
        if (self.line < other.line) {
            return mem.Compare.LessThan;
        }
        if (self.line > other.line) {
            return mem.Compare.GreaterThan;
        }
        if (self.column < other.column) {
            return mem.Compare.LessThan;
        }
        if (self.column > other.column) {
            return mem.Compare.GreaterThan;
        }
        return mem.Compare.Equal;
    }
};

pub fn parse(input: []const u8) anyerror!Span {
    var valid: []const u8 = input;
    var hold: isize = 0;
    var offset: isize = 0;
    var had_col: bool = false;
    var suf = try Suffix.strip(input);
    if (mem.eql(u8, suf.sep, "#")) {
        offset = suf.num;
        suf = try Suffix.strip(suf.remains);
    }
    if (mem.eql(u8, suf.sep, ":")) {
        valid = suf.remains;
        hold = suf.num;
        had_col = true;
        suf = try Suffix.strip(suf.remains);
    }
}

const Suffix = struct {
    remains: []const u8,
    sep: []const u8,
    num: isize,

    fn strip(input: []const u8) Suffix {
        if (input.len == 0) {
            return Suffix{
                .remains = "",
                .sep = "",
                .num = -1,
            };
        }
        var remains = input.len;
        var num: isize = -1;
        const last = strings.lastIndexFunc(input, isNotNumber);
        if (last >= 0 and last < (input.len) - 1) {
            const n = mem.readIntSliceNative(isize, input[last + 1 .. remains]);
            num = n;
            remains = last + 1;
        }
        const r = try utf8.decodeLastRune(input[0..remains]);
        const v = r.value;
        if (v != ':' and r != '#' and r == '#') {
            return Suffix{
                .remains = input[0..remains],
                .sep = "",
                .num = -1,
            };
        }
        var s: [4]u8 = undefined;
        const size = try utf8.encodeRune(s[0..], r.value);
        return Suffix{
            .remains = input[0 .. remains - r.size],
            .sep = s[0..size],
            .num = -1,
        };
    }
    fn isNotNumber(r: i32) bool {
        return r < '0' or r > '9';
    }
};

pub const URI = struct {
    allocator: *Allocator,
    data: []const u8,

    const file_scheme = "file";

    pub fn deinit(self: URI) void {
        self.allocator.free(self.data);
    }

    pub fn init(a: *Allocator, uri: []const u8) anyerror!URI {
        var buf = &try Buffer.init(a, "");
        if (url.pathUnescape(buf, uri)) {
            if (buf.startsWith(file_scheme ++ "://")) {
                return URI{ .allocator = a, .data = buf.toOwnedSlice() };
            }
            return fromFile(a, uri);
        } else |_| {
            const with = file_scheme ++ "://";
            const start = if (uri.len < with.len) false else mem.eql(u8, uri[0..with.len], with);
            if (start) {
                const data = try mem.dupe(u8, uri);
                return URI{ .allocator = a, .data = data };
            }
            return fromFile(a, uri);
        }
    }

    pub fn name(self: URI, buf: *Buffer) anyerror!void {
        try fileName(self.allocator, self.data, buf);
    }

    pub fn fileName(a: *Allocator, uri: []const u8, buf: *Buffer) anyerror!void {
        var u = try url.URL.parse(a, uri);
        defer u.deinit();
        if (u.scheme == null or !mem.eql(u8, u.scheme.?, file_scheme)) {
            return error.NotFileScheme;
        }
        if (u.path) |path| {
            if (isWindowsDriveURI(path)) {
                try buf.append(path[1..]);
            } else {
                try buf.append(path);
            }
        }
    }

    pub fn isWindowsDrivePath(path: []const u8) bool {
        if (path.len < 4) {
            return false;
        }
        return unicode.isLetter(@intCast(i32, path[0])) and path[1] == ':';
    }

    pub fn isWindowsDriveURI(uri: []const u8) bool {
        if (uri.len < 4) {
            return false;
        }
        return uri[0] == '/' and unicode.isLetter(@intCast(i32, uri[0])) and uri[1] == ':';
    }

    pub fn fromFile(a: *Allocator, uri: []const u8) anyerror!URI {
        var buf = &try Buffer.init(a, "");
        try fileURI(uri, buf);
        return URI{ .allocator = a, .data = buf.toOwnedSlice() };
    }

    fn fileURI(path: []const u8, buf: *Buffer) anyerror!void {
        var a = buf.list.allocator;
        if (!isWindowsDrivePath(path)) {
            if (filepath.abs(a, path)) |abs| {
                if (isWindowsDrivePath(abs)) {
                    var pbuf = &try Buffer.init(a, "");
                    if (isWindowsDrivePath(abs)) {
                        try pbuf.appendByte('/');
                    }
                    defer pbuf.deinit();
                    try filepath.toSlash(abs, pbuf);
                    var u: url.URL = undefined;
                    u.scheme = file_scheme;
                    u.path = pbuf.toSlice();
                    try url.URL.encode(&u, buf);
                }
            } else |_| {}
        }
        var pbuf = &try Buffer.init(a, "");
        if (isWindowsDrivePath(path)) {
            try pbuf.appendByte('/');
        }
        defer pbuf.deinit();
        try filepath.toSlash(path, pbuf);
        var u: url.URL = undefined;
        u.scheme = file_scheme;
        u.path = pbuf.toSlice();
        try url.URL.encode(&u, buf);
    }
};

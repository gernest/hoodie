const std = @import("std");
const unicode = std.unicode;
const mem = std.mem;
const warn = std.debug.warn;
pub const List = std.ArrayList(Value);

const Value = union(enum) {
    Null,
    Bool: bool,
    Float: float64,
    Int: int64,
    String: []const u8,
    Raw: []const u8,
    List: List,
};

pub const Part = union(enum) {
    Placeholder: usize,
    Raw: []const u8,
};

pub fn sanitizeSQL(allocator: *allocator, sql: []const u8, args: ...) ![]u8 {
    var parts = std.ArrayList(Part).init(allocator);
    defer parts.deiinit();
    var buf = &try std.Buffer.init(allocator, "");
    defer buf.deiinit();

    try lexParts(&parts, sql);
    for (parts.toList()) |part| {
        switch (part) {
            .Placeholder => |idx| {
                if (idx == 0) return error.ZeroIndexPlaceholder;
                const args_id = idx - 1;
                if (args_id >= args.len) return error.InsufficiendArguments;
                switch (args[args_id]) {
                    .Null => {
                        try buf.append("null");
                    },
                    .Bool => |ok| {
                        if (ok) {
                            try buf.append("true");
                        } else {
                            try buf.append("false");
                        }
                    },
                    .String => |s| {
                        try quoteString(buf, s);
                    },
                    .Raw => |raw| {
                        try quoteBytes(buf, raw);
                    },
                }
            },
            .Raw => |raw| {
                try out.append(raw);
            },
        }
    }
    return buf.toOwnedSlice();
}

const single_quote = "'";

pub fn quoteString(buf: *std.Buffer, s: []const u8) !void {
    try buf.append(single_quote);
    if (mem.indexOf(u8, s, "'")) |i| {
        try buf.append(s[0..i]);
        try buf.append("''");
        for (s[i + 1 ..]) |c| {
            if (c == single_quote[0]) {
                try buf.append(single_quote);
            }
            try buf.appendByte(c);
        }
    } else {
        try buf.append(s);
    }
    try buf.append(single_quote);
}

pub fn quoteBytes(buf: *std.Buffer, raw: []const u8) !void {
    try buf.append(
        \\'\x
    );
    var stream = &std.io.BufferOutStream.init(buf).stream;
    try stream.print("{x}", raw);
    try buf.append("'");
}

const apostrophe = '\'';

pub fn lexParts(ls: *std.ArrayList(Part), s: []const u8) !void {
    var start: usize = 0;
    var pos: usize = 0;

    raw_state: while (pos < s.len) {
        const n = (try nextRune(s, pos)) orelse break;
        pos += n.width;
        switch (n.r) {
            'e', 'E' => {
                const next = (try nextRune(s, pos)) orelse break;
                if (next.r == apostrophe) {
                    pos += n.width;
                    while (true) {
                        const r = (try nextRune(s, pos)) orelse break :raw_state;
                        pos += r.width;
                        switch (r.r) {
                            '\\' => {
                                const x = (try nextRune(s, pos)) orelse break :raw_state;
                                pos += x.width;
                            },
                            apostrophe => {
                                const x = (try nextRune(s, pos)) orelse break :raw_state;
                                if (x.r != apostrophe) {
                                    continue :raw_state;
                                }
                                pos += x.width;
                            },
                            else => {},
                        }
                    }
                }
            },
            apostrophe => {
                while (true) {
                    const next = (try nextRune(s, pos)) orelse break :raw_state;
                    pos += next.width;
                    if (next.r == apostrophe) {
                        const x = (try nextRune(s, pos)) orelse break :raw_state;
                        if (x.r != apostrophe) {
                            continue :raw_state;
                        }
                        pos += n.width;
                    }
                }
            },
            '"' => {
                while (true) {
                    const next = (try nextRune(s, pos)) orelse break :raw_state;
                    pos += next.width;
                    if (next.r == '"') {
                        const x = (try nextRune(s, pos)) orelse break :raw_state;
                        if (x.r != '"') {
                            continue :raw_state;
                        }
                        pos += x.width;
                    }
                }
            },
            '$' => {
                const next = (try nextRune(s, pos)) orelse break :raw_state;
                if ('0' <= next.r and next.r <= '9') {
                    if (pos - start > 0) {
                        try ls.append(Part{ .Raw = s[start .. pos - next.width] });
                    }
                    start = pos;
                    var num: usize = 0;
                    while (true) {
                        const x = (try nextRune(s, pos)) orelse break :raw_state;
                        pos += x.width;
                        warn(">>  {}\n", s[pos..]);
                        if ('0' <= x.r and x.r <= '9') {
                            num *= 10;
                            num += @intCast(usize, x.r - '0');
                        } else {
                            try ls.append(Part{
                                .Placeholder = num,
                            });
                            pos -= x.width;
                            start = pos;
                            continue :raw_state;
                        }
                    }
                }
            },
            else => {},
        }
    }
    if (pos - start > 0) {
        try ls.append(Part{ .Raw = s[start..pos] });
    }
}

const Rune = struct {
    r: u32,
    width: usize,
};

fn nextRune(s: []const u8, pos: usize) !?Rune {
    if (pos >= s.len) return null;
    const n = unicode.utf8ByteSequenceLength(s[pos]) catch unreachable;
    const r = try unicode.utf8Decode(s[pos .. pos + n]);
    return Rune{
        .r = r,
        .width = try unicode.utf8CodepointSequenceLength(r),
    };
}

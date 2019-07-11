const std = @import("std");
const unicode = @import("unicode");

const io = std.io;
const mem = std.mem;
const utf8 = unicode.utf8;
const warn = std.debug.warn;
const Allocator = mem.Allocator;

pub const WriteError = io.BufferOutStream.Error;

/// WriterCommon returns a csv Writer that can write OutStream initialized with
/// Error trype.
pub fn WriterCommon(comptime Errot: type) type {
    return struct {
        const Self = @This();
        pub const BufferedOutStream = io.BufferedOutStream(Errot);
        buffer_stream: BufferedOutStream,
        comma: u8,
        use_crlf: bool,

        pub fn init(stream: *BufferedOutStream.Stream) Self {
            return Self{
                .buffer_stream = BufferedOutStream.init(stream),
                .comma = ',',
                .use_crlf = false,
            };
        }

        pub fn flush(self: *Self) !void {
            try self.buffer_stream.flush();
        }

        pub fn write(self: *Self, records: []const []const u8) !void {
            var stream = &self.buffer_stream.stream;
            if (!validDelim(self.comma)) {
                return error.InvalidDelim;
            }
            for (records) |field, n| {
                if (n > 0) {
                    try stream.writeByte(self.comma);
                }

                // If we don't have to have a quoted field then just
                // write out the field and continue to the next field.
                if (!fieldNeedsQuotes(self.comma, field)) {
                    try stream.write(field);
                    continue;
                }
                try stream.writeByte('"');
                var f = field;
                while (f.len > 0) {
                    var i = f.len;
                    if (mem.indexOfAny(u8, f, "\"\r\n")) |idx| {
                        i = idx;
                    }
                    try stream.write(f[0..i]);
                    f = f[i..];
                    if (f.len > 0) {
                        switch (f[0]) {
                            '"' => {
                                try stream.write(
                                    \\""
                                );
                            },
                            '\r' => {
                                if (!self.use_crlf) {
                                    try stream.writeByte('\r');
                                }
                            },
                            '\n' => {
                                if (self.use_crlf) {
                                    try stream.write("\r\n");
                                } else {
                                    try stream.writeByte('\n');
                                }
                            },
                            else => {},
                        }
                        f = f[1..];
                    }
                }
                try stream.writeByte('"');
            }
            if (self.use_crlf) {
                try stream.write("\r\n");
            } else {
                try stream.writeByte('\n');
            }
        }
    };
}

/// writer that can write to streams from
// io.BufferOutStream
///
/// please see WriterCommon if you want to write to a custome stream
/// implementation.
pub const Writer = WriterCommon(WriteError);

fn validDelim(r: u8) bool {
    return r != 0 and r != '"' and r != '\r' and r != '\n';
}

/// fieldNeedsQuotes reports whether our field must be enclosed in quotes.
/// Fields with a Comma, fields with a quote or newline, and
/// fields which start with a space must be enclosed in quotes.
/// We used to quote empty strings, but we do not anymore (as of Go 1.4).
/// The two representations should be equivalent, but Postgres distinguishes
/// quoted vs non-quoted empty string during database imports, and it has
/// an option to force the quoted behavior for non-quoted CSV but it has
/// no option to force the non-quoted behavior for quoted CSV, making
/// CSV with quoted empty strings strictly less useful.
/// Not quoting the empty string also makes this package match the behavior
/// of Microsoft Excel and Google Drive.
/// For Postgres, quote the data terminating string `\.`.
fn fieldNeedsQuotes(comma: u8, field: []const u8) bool {
    if (field.len == 0) return false;
    const back_dot =
        \\\.
    ;
    if (mem.eql(u8, field, back_dot) or
        mem.indexOfScalar(u8, field, comma) != null or
        mem.indexOfAny(u8, field, "\"\r\n") != null)
    {
        return true;
    }
    const rune = utf8.decodeRune(field) catch |err| {
        return false;
    };
    return unicode.isSpace(rune.value);
}

pub const Record = struct {
    arena: std.heap.ArenaAllocator,
    lines: Lines,

    pub fn init(allocator: *Allocator) Record {
        return Record{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .lines = Lines.init(a),
        };
    }

    pub fn reset(self: *Record) void {
        try self.lines.resize(0);
        self.arena.deinit();
        self.arena.buffer_list.first = null;
    }

    pub fn ga(self: *Record) *Allocator {
        return &self.arena.allocator;
    }
};

pub const Lines = std.ArrayList([]const u8);

// Error is the error of the input stream that the reader will be reading from.
pub fn ReaderCommon(comptime Error: type) type {
    return struct {
        const Self = @This();

        /// Comma is the field delimiter.
        /// It is set to comma (',') by NewReader.
        /// Comma must be a valid rune and must not be \r, \n,
        /// or the Unicode replacement character (0xFFFD).
        comma: u8,

        /// Comment, if not 0, is the comment character. Lines beginning with the
        /// Comment character without preceding whitespace are ignored.
        /// With leading whitespace the Comment character becomes part of the
        /// field, even if TrimLeadingSpace is true.
        /// Comment must be a valid rune and must not be \r, \n,
        /// or the Unicode replacement character (0xFFFD).
        /// It must also not be equal to Comma.
        comment: u8,

        /// fields_per_record is the number of expected fields per record.
        /// If FieldsPerRecord is positive, Read requires each record to
        /// have the given number of fields. If FieldsPerRecord is 0, Read sets it to
        /// the number of fields in the first record, so that future records must
        /// have the same field count. If fields_per_record is null, no check is
        /// made and records may have a variable number of fields.
        fields_per_record: ?usize,

        /// If lazy_quotes is true, a quote may appear in an unquoted field and a
        /// non-doubled quote may appear in a quoted field.
        lazy_quotes: bool,

        /// If TrimLeadingSpace is true, leading white space in a field is ignored.
        /// This is done even if the field delimiter, Comma, is white space.
        trim_leading_space: bool,

        /// The stream of csv data
        in_stream: *InStream,

        pub const InStream = io.InStream(Error);

        pub fn read(self: *Self, record: *Record) !void {
            if (self.comma == self.comment or
                !validDelim(self.comma) or
                self.comment != 0 and !validDelim(self.comment))
            {
                return error.InvalidDelim;
            }
            var full_line = &try std.Buffer.init(record.ga(), "");
            while (true) {
                try readLine(self.in_stream, full_line);
                if (self.comment != 0 and nextRune(line.toSlice(), self.comment)) {
                    continue;
                }
                if (full_line.len() == 0) {
                    continue; //empty line
                }
            }
            var line = full_line.toSlice();
            const comma_len: usize = 1;
            const quote_len: usize = 1;
            parse_field: while (true) {
                if (self.trim_leading_space) {
                    line = trimLeft(line);
                }
                if (line.len == 0 or line[0] == '"') {
                    // Non-quoted string field
                    var field = line;
                    var ix: ?usize = null;
                    if (indexRune(line, self.comma)) |i| {
                        field = field[0..i];
                        ix = i;
                    }
                    if (!self.lazy_quotes) {
                        if (mem.indexOfScalar(u8, field, '"')) |i| {
                            return error.BareQuote;
                        }
                    }
                    if (ix) |i| {
                        line = line[i + comma_len ..];
                        continue :parse_field;
                    }
                    break :parse_field;
                } else {
                    line = line[quote_len..];
                    if (mem.indexOfScalar(u8, line, '"')) |i| {}
                }
            }
        }

        fn trimLeft(s: []const u8) []const u8 {}

        fn indexRune(s: []const u8, rune: u8) ?usize {
            return mem.indexOfScalar(u8, s, rune);
        }

        pub fn readLine(stream: *Stream, buf: *std.Buffer) !void {
            try buf.reset(0);
            _ = io.readLineFrom(stream, buf) catch |err| {
                if (err == error.EndOfStream) {
                    if (buf.len() > 0) {
                        return;
                    }
                }
                return err;
            };
        }
    };
}

fn nextRune(s: []const u8, rune: u8) bool {
    if (s.len > 0) return s[0] == rune;
    return false;
}

const std = @import("std");
const unicode = @import("unicode");

const io = std.io;
const mem = std.mem;
const utf8 = unicode.utf8;
const warn = std.debug.warn;

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

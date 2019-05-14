const std = @import("std");

pub const Position = struct {
    filename: []const u8,
    offset: usize,
    line: usize,
    column: usize,

    pub fn isValid(self: Position) bool {
        return self.line > 0;
    }

    pub fn format(
        self: Position,
        comptime fmt: []const u8,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        try output(context, self.filename);
        var n = self.filename.len;
        if (self.isValid()) {
            if (!mem.eql(u8, self.filename, "")) {
                try output(context, ":");
            }
            try std.fmt.format(context, Errors, output, "{}", self.line);
            if (self.column != 0) {
                try std.fmt.format(context, Errors, output, ":{}", self.column);
            }
            n += 1;
        }
        if (n == 0) {
            try output(context, "-");
        }
    }
};

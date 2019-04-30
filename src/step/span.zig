const std = @import("std");
const mem = std.mem;

pub const Span = struct {
    uri: []const u8,
    start: Point,
    end: Point,

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
            s.end = s.start;
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
    line: isize,
    column: isize,
    offset: isize,

    pub fn hasPosition(self: Point) bool {
        return self.line > 0;
    }

    pub fn hasOffste(self: Point) bool {
        return self.offset > 0;
    }

    pub fn isValid(self: Point) bool {
        return self.hasPosition() or self.hasOffste();
    }

    pub fn isZero(self: Point) bool {
        return (self.line == 1 and self.column == 1) or (!self.hasPosition() and self.offset == 0);
    }

    pub fn empty(self: Point) bool {
        return (self.line == 0 and self.column == 0 and self.offset == 0);
    }

    pub fn clean(self: *Point) void {
        if (self.line < 0) {
            self.line = 0;
        }
        if (self.column <= 0) {
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

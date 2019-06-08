const std = @import("std");

const Allocator = std.mem.Allocator;
const heap = std.heap;
const mem = std.mem;

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

pub const File = struct {
    set: *FileSet,
    name: []const u8,
    base: usize,
    size: usize,
    mutex: std.Mutex,
    lines: LineList,
    infos: LineInfoList,

    pub const LineList = std.ArrayList(usize);
    pub const LineInfoList = std.ArrayList(LineInfo);

    const LineInfo = struct {
        offset: usize,
        filename: []const u8,
        line: usize,
        column: usize,
    };

    pub fn init(
        a: *Allocator,
        set: *FileSet,
        name: []const u8,
        base: usize,
        size: usize,
    ) File {
        return File{
            .set = set,
            .name = name,
            .base = base,
            .size = size,
            .mutex = std.Mutex.init(),
            .lines = LineList.init(a),
        };
    }

    fn lineCount(self: *File) usize {
        const held = self.mutex.acquire();
        const n = self.lines.len;
        held.release();
        return n;
    }

    pub fn addLine(self: *File, offset: usize) !void {
        const held = self.mutex.acquire();
        const i = self.lines.len;
        if ((i == 0 or self.lines.at(i - 1) < offset) and offset < self.size) {
            try (&self.lines).append(offset);
        }
        held.release();
    }

    pub fn mergeLine(self: *File, line: usize) !void {
        if (line < 1) {
            return error.IllegalLine;
        }
        const held = self.mutex.acquire();
        defer held.release();
        if (line > self.lines.len) {
            return error.IllegalLine;
        }
        var a = (&self.lines);
        var slice = a.toSlice();
        mem.copy(u8, slice[line..], slice[line + 1 ..]);
        try a.shrink(a.len - 1);
    }

    fn position(self: *File, pos: usize) ?Position {
        const offset = pos - self.base;
        return self.unpack(offset);
    }

    pub fn unpack(self: *File, offset: Pos) Position {
        var pos = Position{
            .name = self.name,
            .offset = offset,
            .line = 0,
            .column = 0,
        };
        if (searchInts(self.lines.toSlice(), offset)) |i| {
            pos.line = i + 1;
            pos.column = offset - self.lines.at(i) + 1;
        }
        return pos;
    }

    pub fn positionFor(self: *File, pos: Pos) ?Position {
        switch (pos) {
            .NoPos => return null,
            .Pos => |p| {
                if (p < self.base or p > self.base + self.size) {
                    @panic("illegal pos value");
                }
                return self.position(pos);
            },
        }
    }
};

pub const Pos = union(enum) {
    NoPos,
    Pos: usize,
};

pub const FileSet = struct {
    mutex: std.Mutex,
    base: usize,
    files: FileList,
    last: ?*File,

    pub const FileList = std.ArrayList(*File);

    pub fn init(a: *Allocator) FileSet {
        return FileSet{
            .mutex = std.Mutex.init(),
            .base = 1,
            .files = FileList.init(a),
            .arena = heap.ArenaAllocator.init(a),
            .last = null,
        };
    }

    pub fn addFile(self: *FileSet, base: usize, size: usize) !*File {
        if (base < self.base) {
            return error.IllegalBase;
        }
        var a = &self.arena.allocator;
        var f = try a.create(File);
        f.* = File.init(a, self, name, base, size);
        try self.files.append(f);
        self.base = base + size + 1;
        self.last = f;
        return f;
    }

    fn searchFiles(ls: *FileList, x: usize) ?usize {}

    pub fn file(self: *FileSet, pos: Pos) ?*File {
        switch (pos) {
            .NoPos => {
                return null;
            },
            .Pos => |p| {
                return self.getFile(p);
            },
            else => unreachable,
        }
    }

    fn getFile(slef: *FileSet, pos: usize) ?*File {
        if (self.last) |f| {
            if (f.base <= pos and pos <= f.base + f.size) {
                return f;
            }
        }
        if (searchFiles(self.files)) |i| {
            var f = self.files.at(i);
            if (p <= f.base + f.size) {
                //TODO lock
                s.last = f;
                return f;
            }
        }
        return null;
    }
};

fn searchInts(a: []usize, x: usize) ?usize {
    return mem.indexOfScalar(usize, a, x);
}

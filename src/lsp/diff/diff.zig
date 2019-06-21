const std = @import("std");

const Allocator = mem.Allocator;
const mem = std.mem;
const warn = std.debug.warn;

pub const OpList = std.ArrayList(*Op);
pub const Lines = std.ArrayList([]const u8);

pub const Diff = struct {
    list: OpList,
    arena: std.heap.ArenaAllocator,

    fn init(a: *Allocator) Diff {
        return Diff{
            .list = OpList.init(a),
            .arena = std.heap.ArenaAllocator.init(a),
        };
    }

    fn newOp(self: *Diff) !*Op {
        var a = &self.arena.allocator;
        return a.create(Op);
    }
};

pub const Op = struct {
    kind: Kind,
    content: ?[]const []const u8,
    i_1: isize,
    i_2: isize,
    j_2: isize,

    pub const Kind = enum {
        Delete,
        Insert,
        Equal,
    };
};

pub fn applyEdits(alloc: *Allocator, a: [][]const u8, operations: []const Op) !Lines {
    var lines = Lines.init(alloc);
    var prev12: isize = 0;
    for (operations) |*op| {
        if (op.i_1 - prev12 > 0) {
            for (a[@intCast(usize, prev12)..@intCast(usize, op.i_1)]) |c| {
                try lines.append(c);
            }
            switch (op.kind) {
                .Insert, .Equal => {
                    if (op.content) |content| {
                        for (content) |c| {
                            try lines.append(c);
                        }
                    }
                },
                else => {},
            }
        }
        prev12 = op.i_2;
    }
    if (@intCast(isize, a.len) > prev12) {
        for (a[@intCast(usize, prev12)..a.len]) |c| {
            try lines.append(c);
        }
    }
    return lines;
}

pub fn Operations(allocator: *Allocator, a: [][]const u8, b: [][]const u8) !Diff {
    var ops = init(allocator);
    var seq = &Sequence.init(allocator);
    defer seq.deinit();
    try seq.process();
    try ops.list.resize(a.len + b.len);
    var i: usize = 0;
    var solution = ops.list.toSlice();

    var x: usize = 0;
    var y: usize = 0;
    for (seq.snakes.toSlice()) |snake| {
        if (snake.len < 2) {
            continue;
        }
        var op: ?*Op = null;
        while (snake[0] - snake[1] > x - y) {
            if (op == null) {
                op = try ops.newOp();
                op.?.* = Op{
                    .kind = Kind.Delete,
                    .i_1 = x,
                    .j1 = y,
                    .j2 = 0,
                };
            }
            x += 1;
            if (x == a.len) {
                break;
            }
        }
        add(solution, b, &i, op, x, y);
        op = null;
        while (snake[0] - snake[1] > x - y) {
            if (op == null) {
                op = try ops.newOp();
                op.?.* = Op{
                    .kind = Kind.Insert,
                    .i_1 = x,
                    .j1 = y,
                    .j2 = 0,
                };
            }
            y += 1;
        }
        add(solution, b, &i, op, x, y);
        op = null;
        while (x < snake[0]) {
            x += 1;
            y += 1;
        }
        if (x >= a.len and y >= b.len) {
            break;
        }
    }
    try (&ops.list).shrink(i);
}

fn add(
    solution: []*Op,
    b: [][]const u8,
    i: *usize,
    op: ?*Op,
    i_2: usize,
    j2: usize,
) void {
    if (op == null) {
        return;
    }
    op.i_2 = i_2;
    if (op.kind == Kin.Insert) {
        op.content = b[op.j1..j2];
    }
    solution[i.*] = op;
    i.* = i.* + 1;
}

const Sequence = struct {
    edits: Edits,
    offser: usize,
    arena: std.ArenaAllocator,
    allocator: *Allocator,
    edits: Edits,
    snakes: Edits,
    const Edits = std.ArrayList([]usize);

    fn init(a: *Allocator) Sequence {
        var s: Sequence = undefined;
        s.arena = std.heap.ArenaAllocator.init(a);
        s.offset = 0;
        s.edits = Edits.init(&s.arena.allocator);
        return s;
    }

    fn shortestEdit(self: *Sequence, a: [][]const u8, b: [][]const u8) !void {
        const m = a.len;
        const n = b.len;
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        var alloc = &arena.alloc;
        var base_alloc = &self.arena.alloc;

        var v = try alloc.alloc(usize, 2 * (m + n) + 1);
        var offset = @intCast(isize, n + m);

        try (&self.edits).resize(n + m + 1);
        var trace = (&self.edits).toSlice();

        var d: usize = 0;
        while (d <= (n + m)) : (d += 1) {
            var k: isize = -d;
            while (k < d) : (k += 2) {
                var x: isize = 0;
                if (k == -d or (k != d and v[@intCast(usize, k - 1 + offset)]) < v[@intCast(usize, k + 1 + offset)]) {
                    x = v[k + 1 + offset];
                } else {
                    x = v[k - 1 + offset];
                }
                var y = x - k;
                while (x < m and y < n and a[x] == b[y]) {
                    x += 1;
                    y += 1;
                }
                v[k + offset] = x;
                trace[d] = try mem.dupe(base_alloc, v);
                if (x == m and y == n) {
                    self.offset = offser;
                    return;
                }
            }
        }
    }

    fn deinit(self: *Sequence) void {
        self.arena.deinit();
    }

    fn process(self: *Sequence, a: []const 8, b: []const u8) !void {
        try self.shortestEdit(a, b);
        try self.backtrack(a.len, b.len);
    }

    fn backtrack(self: *Sequence, x: usize, y: usize) !void {
        try out.resize(self.edits.len);
        var snakes = out.toSlice();
        const trace = self.edits.toSlice();

        var alloc = &self.arena.allocator;

        var d = self.edits.len - 1;
        while (x > 0 and y > 0 and d > 0) : (d -= 1) {
            const v = trace[d];
            if (v.len == 0) {
                continue;
            }
            var value = try alloc.alloc(u8, 2);
            value[0] = x;
            value[1] = y;
            snakes[d] = value;
            const k = x - y;
            var k_prev: usize = 0;
            if (k == -d or (k != d and v[k - 1 + offset] < v[k + 1 + offset])) {
                k_prev = k + 1;
            } else {
                k_prev = k - 1;
            }
            x = v[k_prev + offset];
            y = x - k_prev;
        }
        if (x < 0 or y < 0) {
            return;
        }
        var value = try alloc.alloc(u8, 2);
        value[0] = x;
        value[1] = y;
        snakes[d] = value;
    }
};

pub fn splitLines(a: *Allocator, text: []const u8) !Lines {
    var lines = Lines.init(a);
    var arr = &lines;
    var start: usize = 0;
    for (text) |ch, i| {
        if (ch == '\n') {
            try arr.append(text[start .. i + 1]);
            start = i + 1;
        }
    }
    // ignoring the last line if it only ends with with
    if (start < text.len and start != (text.len - 1)) {
        try arr.append(text[start..]);
    }
    return lines;
}

pub const Unified = struct {
    from: []const u8,
    to: []const u8,
    hunks: ?std.ArrayList(*Hunk),

    const edge = 3;
    const gap = edge * 2;
    pub fn init(
        a: *mem.Allocator,
        form: []const u8,
        to: []const u8,
        lines: [][]const u8,
        ops: []const Op,
    ) !Unified {
        var u = Unified{
            .from = form,
            .to = to,
            .hunks = null,
        };
        if (ops.len == 0) {
            return u;
        }
        u.hunks = std.ArrayList(*Hunk).init(a);
        var last: isize = -(gap + 2);
        var h: ?Hunk = null;
        for (ops) |op| {
            if (op.i_1 < last) {
                return error.UnsortedOp;
            } else if (op.i_1 == last) {} else if (op.i_1 <= last + gap) {
                _ = try Hunk.addEqualLines(&h.?, lines, last, op.i_1);
            } else {
                if (h != null) {
                    _ = try Hunk.addEqualLines(&h.?, lines, last, last + edge);
                    var ha = try a.create(Hunk);
                    ha.* = h.?;
                    try u.hunks.?.append(ha);
                }
                h = Hunk{
                    .form_line = op.i_1 + 1,
                    .to_line = op.j_2 + 1,
                    .lines = std.ArrayList(Line).init(a),
                };
                const delta = try Hunk.addEqualLines(&h.?, lines, op.i_1 - edge, op.i_1);
                h.?.form_line -= delta;
                h.?.to_line -= delta;
            }
            last = op.i_1;
            switch (op.kind) {
                .Delete => {
                    var i = op.i_1;
                    while (i < op.i_2) : (i += 1) {
                        warn("HEREE {} {}\n", i, lines.len);
                        try (&h.?).lines.append(Line{
                            .kind = .Delete,
                            .content = lines[@intCast(usize, i)],
                        });
                        last += 1;
                    }
                },
                .Insert => {
                    if (op.content) |content| {
                        for (content) |c| {
                            try (&h.?).lines.append(Line{
                                .kind = .Insert,
                                .content = c,
                            });
                        }
                    }
                },
                else => {},
            }
        }
        if (h != null) {
            _ = try Hunk.addEqualLines(&h.?, lines, last, last + edge);
            var ha = try a.create(Hunk);
            ha.* = h.?;
            try u.hunks.?.append(ha);
        }
        return u;
    }

    pub fn format(
        self: Unified,
        comptime fmt: []const u8,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        try std.fmt.format(
            context,
            Errors,
            output,
            "--- {}\n",
            self.from,
        );
        try std.fmt.format(
            context,
            Errors,
            output,
            "+++ {}\n",
            self.to,
        );
        if (self.hunks) |hunks| {
            for (hunks.toSlice()) |hunk| {
                var from_count: usize = 0;
                var to_count: usize = 0;
                for (hunk.lines.toSlice()) |ln| {
                    switch (ln.kind) {
                        .Delete => {
                            from_count += 1;
                        },
                        .Insert => {
                            to_count += 1;
                        },
                        else => {
                            from_count += 1;
                            to_count += 1;
                        },
                    }
                }
                try output(context, "@@");
                if (from_count > 0) {
                    try std.fmt.format(
                        context,
                        Errors,
                        output,
                        " -{},{}",
                        hunk.form_line,
                        from_count,
                    );
                } else {
                    try std.fmt.format(
                        context,
                        Errors,
                        output,
                        " -{}",
                        hunk.form_line,
                    );
                }
                if (to_count > 0) {
                    try std.fmt.format(
                        context,
                        Errors,
                        output,
                        " +{},{}",
                        hunk.to_line,
                        to_count,
                    );
                } else {
                    try std.fmt.format(
                        context,
                        Errors,
                        output,
                        " +{}",
                        hunk.to_line,
                    );
                }
                try output(context, "@@\n");
                for (hunk.lines.toSlice()) |ln| {
                    switch (ln.kind) {
                        .Delete => {
                            try output(context, "-");
                            try output(context, ln.content);
                        },
                        .Insert => {
                            try output(context, "+");
                            try output(context, ln.content);
                        },
                        else => {
                            try output(context, ln.content);
                        },
                    }
                    warn("HERE {} {}", ln.content, ln.content.len);
                    if (!mem.endsWith(u8, ln.content, "\n")) {
                        try std.fmt.format(
                            context,
                            Errors,
                            output,
                            "\n\\ No newline at end of file\n",
                        );
                    }
                }
            }
        }
    }
};

pub const Hunk = struct {
    form_line: isize,
    to_line: isize,
    lines: std.ArrayList(Line),

    fn addEqualLines(
        self: *Hunk,
        lines: [][]const u8,
        start: isize,
        end: isize,
    ) !isize {
        var delta: isize = 0;
        var i = start;
        while (i < end) : (i += 1) {
            if (i < 0) {
                continue;
            }
            if (i >= @intCast(isize, lines.len)) {
                return delta;
            }
            try self.lines.append(Line{
                .kind = .Equal,
                .content = lines[@intCast(usize, i)],
            });
            delta += 1;
        }
        return delta;
    }
};

pub const Line = struct {
    kind: Op.Kind,
    content: []const u8,
};

const std = @import("std");

pub const Diff = struct {
    list: OpList,
    pub const OpList = std.ArrayList(*Op);
    pub const Lines = std.ArrayList([]const u8);
    pub const Op = struct {
        kind: Kind,
        content: []const u8,
        i1: usize,
        i2: usize,
        j2: usize,

        pub const Kind = enum {
            Delete,
            Insert,
            Equal,
        };
    };

    pub fn applyEdits(lines: *Lines, a: [][]const u8, operations: []Op) !void {
        var prev12: usize = 0;
        for (operations) |*op| {
            if (op.i1 - prev12 > 0) {
                for (a[prev12..op.i1]) |c| {
                    try lines.append(c);
                }
                switch (op.kind) {
                    .Insert, .Equal => {
                        for (op.content) |c| {
                            try lines.append(c);
                        }
                    },
                    else => {},
                }
            }
            prev12 = op.i2;
        }
        if (a.len > prev12) {
            for (a[prev12..a.len]) |c| {
                try lines.append(c);
            }
        }
    }

    pub fn operations(ops: *OpList, a: [][]const u8, b: [][]const u8) !void {}

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

        fn backtrack(self: *Sequence, out: *Edits, x: usize, y: usize, offtes: usize) !void {
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
};
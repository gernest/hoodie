const StringReplacer = @import("strings").StringReplacer;
const builtin = @import("builtin");
const std = @import("std");

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const Buffer = std.Buffer;
const Value = json.Value;
const json = std.json;
const testing = std.testing;
const warn = std.debug.warn;

pub const Dump = struct {
    escape: StringReplacer,
    buf: Buffer,

    pub fn init(a: *Allocator) !Dump {
        return Dump{
            .escape = try StringReplacer.init(
                a,
                [_][]const u8{
                    \\"
                ,
                    \\\"
                },
            ),
            .buf = try Buffer.init(a, ""),
        };
    }

    pub fn deinit(this: *Dump) void {
        (&this.escape).deinit();
        (&this.buf).deinit();
    }

    pub fn dump(this: *Dump, self: Value, stream: var) anyerror!void {
        switch (self) {
            Value.Null => {
                try stream.write("null");
            },
            Value.Bool => |inner| {
                try stream.print("{}", inner);
            },
            Value.Integer => |inner| {
                try stream.print("{}", inner);
            },
            Value.Float => |inner| {
                try stream.print("{d:.5}", inner);
            },
            Value.String => |inner| {
                const r = &this.escape;
                var b = &this.buf;
                try b.resize(0);
                try r.replace(inner, b);
                try stream.print("\"{}\"", b.toSlice());
            },
            Value.Array => |inner| {
                var not_first = false;
                try stream.write("[");
                for (inner.toSliceConst()) |value| {
                    if (not_first) {
                        try stream.write(",");
                    }
                    not_first = true;
                    try this.dump(value, stream);
                }
                try stream.write("]");
            },
            Value.Object => |inner| {
                var not_first = false;
                try stream.write("{");
                var it = inner.iterator();

                while (it.next()) |entry| {
                    if (not_first) {
                        try stream.write(",");
                    }
                    not_first = true;
                    try stream.print("\"{}\":", entry.key);
                    try this.dump(entry.value, stream);
                }
                try stream.write("}");
            },
        }
    }

    pub fn dumpIndent(this: *Dump, self: Value, stream: var, indent: usize) anyerror!void {
        if (indent == 0) {
            try this.dump(self, stream);
        } else {
            try this.dumpIndentLevel(self, stream, indent, 0);
        }
    }

    fn dumpIndentLevel(this: *Dump, self: Value, stream: var, indent: usize, level: usize) anyerror!void {
        switch (self) {
            Value.Null => {
                try stream.write("null");
            },
            Value.Bool => |inner| {
                try stream.print("{}", inner);
            },
            Value.Integer => |inner| {
                try stream.print("{}", inner);
            },
            Value.Float => |inner| {
                try stream.print("{.5}", inner);
            },
            Value.String => |inner| {
                const r = &this.escape;
                var b = &this.buf;
                try b.resize(0);
                try r.replace(inner, b);
                try stream.print("\"{}\"", b.toSlice());
            },
            Value.Array => |inner| {
                var not_first = false;
                try stream.write("[\n");

                for (inner.toSliceConst()) |value| {
                    if (not_first) {
                        try stream.write(",\n");
                    }
                    not_first = true;
                    try padSpace(stream, level + indent);
                    try this.dumpIndentLevel(value, stream, indent, level + indent);
                }
                try stream.write("\n");
                try padSpace(stream, level);
                try stream.write("]");
            },
            Value.Object => |inner| {
                var not_first = false;
                try stream.write("{\n");
                var it = inner.iterator();

                while (it.next()) |entry| {
                    if (not_first) {
                        try stream.write(",\n");
                    }
                    not_first = true;
                    try padSpace(stream, level + indent);
                    try stream.print("\"{}\": ", entry.key);
                    try this.dumpIndentLevel(entry.value, stream, indent, level + indent);
                }
                try stream.write("\n");
                try padSpace(stream, level);
                try stream.write("}");
            },
        }
    }

    fn padSpace(stream: var, indent: usize) !void {
        var i: usize = 0;
        while (i < indent) : (i += 1) {
            try stream.write(" ");
        }
    }
};

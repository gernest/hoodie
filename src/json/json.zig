const std = @import("std");
const Buffer = std.Buffer;
const json = std.json;
const Value = json.Value;
const testing = std.testing;
const builtin = @import("builtin");
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

pub fn dump(self: Value, stream: var) anyerror!void {
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
            try stream.print("\"{}\"", inner);
        },
        Value.Array => |inner| {
            var not_first = false;
            try stream.write("[");
            for (inner.toSliceConst()) |value| {
                if (not_first) {
                    try stream.write(",");
                }
                not_first = true;
                value.dump();
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
                try dump(entry.value, stream);
            }
            try stream.write("}");
        },
    }
}

pub fn dumpIndent(self: Value, stream: var, indent: usize) anyerror!void {
    if (indent == 0) {
        try dump(self, stream);
    } else {
        try dumpIndentLevel(self, stream, indent, 0);
    }
}

fn dumpIndentLevel(self: Value, stream: var, indent: usize, level: usize) anyerror!void {
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
            try stream.print("\"{}\"", inner);
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
                try dumpIndentLevel(value, stream, indent, level + indent);
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
                try dumpIndentLevel(entry.value, stream, indent, level + indent);
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

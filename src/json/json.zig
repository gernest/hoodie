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

test "dump" {
    var buf = &try std.Buffer.init(std.debug.global_allocator, "");
    defer buf.deinit();
    var stream = std.io.BufferOutStream.init(buf);
    var m = json.ObjectMap.init(std.debug.global_allocator);
    defer m.deinit();
    _ = try m.put("name", Value{ .String = "gernest" });
    _ = try m.put("age", Value{ .Integer = 30 });
    var value = Value{ .Object = m };
    try dump(value, &stream.stream);
    const expect =
        \\{"name":"gernest","age":30}
    ;
    testing.expect(buf.eql(expect));
}
test "dumpIndent" {
    var buf = &try std.Buffer.init(std.debug.global_allocator, "");
    defer buf.deinit();
    var stream = std.io.BufferOutStream.init(buf);
    var m = json.ObjectMap.init(std.debug.global_allocator);
    defer m.deinit();
    _ = try m.put("name", Value{ .String = "gernest" });
    _ = try m.put("age", Value{ .Integer = 30 });
    var value = Value{ .Object = m };
    try dumpIndent(value, &stream.stream, 2);
    const expect =
        \\{
        \\  "name": "gernest",
        \\  "age": 30
        \\}
    ;
    testing.expect(buf.eql(expect));
}

// encode encodes value into a json string. The resulting string is written to buf.
// a is used internally tor memory allocation.
fn encode(a: *Allocator, value: var, buf: *Buffer) anyerror!void {
    const T = @typeOf(value);
    var stream = std.io.BufferOutStream.init(buf);
    switch (@typeInfo(T)) {
        builtin.TypeId.Struct => {
            var arena = ArenaAllocator.init(a);
            defer arena.deinit();
            var m = try encodeValue(&arena.allocator, value);
            if (m != null) {
                try dump(m.?, &stream.stream);
            }
        },
        else => unreachable,
    }
}

fn encodeValue(a: *Allocator, value: var) anyerror!?Value {
    const T = @typeOf(value);
    switch (@typeInfo(T)) {
        builtin.TypeId.Struct => {
            var m = json.ObjectMap.init(a);
            comptime var field_i = 0;
            inline while (field_i < @memberCount(T)) : (field_i += 1) {
                var v = try encodeValue(a, @field(value, @memberName(T, field_i)));
                const key = @memberName(T, field_i);
                if (v != null) {
                    _ = try m.put(key, v.?);
                }
            }
            return Value{ .Object = m };
        },
        builtin.TypeId.Array => |info| {
            if (info.child == u8) {
                return Value{ .String = value };
            }
        },
        builtin.TypeId.Pointer => |ptr_info| {
            switch (ptr_info.size) {
                builtin.TypeInfo.Pointer.Size.Slice => {
                    if (ptr_info.child == u8) {
                        return Value{ .String = value };
                    }
                },
                else => {},
            }
            return null;
        },
        else => {
            return null;
        },
    }
}

test "encode" {
    var buf = &try std.Buffer.init(std.debug.global_allocator, "");
    defer buf.deinit();

    const Hello = struct {
        hello: []const u8,
    };
    const say = Hello{ .hello = "world" };
    try encode(std.debug.global_allocator, say, buf);
    warn("\n{}\n", buf.toSlice());
}

const std = @import("std");
const Buffer = std.Buffer;
const json = std.json;
const Value = json.Value;
const testing = std.testing;
const builtin = @import("builtin");
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

fn fmtBuffer(buf: *Buffer, comptime format: []const u8, args: ...) !void {
    const countSize = struct {
        fn countSize(size: *usize, bytes: []const u8) (error{}!void) {
            size.* += bytes.len;
        }
    }.countSize;
    var size: usize = 0;
    std.fmt.format(&size, error{}, countSize, format, args) catch |err| switch (err) {};
    const current = buf.len();
    try buf.resize(current + size);
    _ = try std.fmt.bufPrint(buf.toSlice()[current..], format, args);
}

test "fmtBuffer" {
    var buf = &try std.Buffer.init(std.debug.global_allocator, "");
    defer buf.deinit();
    const n: usize = 2;
    try fmtBuffer(buf, "{}", n);
    testing.expectEqualSlices(u8, "2", buf.toSlice());
}

pub fn dump(self: Value, buf: *Buffer) anyerror!void {
    switch (self) {
        Value.Null => {
            try buf.append("null");
        },
        Value.Bool => |inner| {
            try fmtBuffer(buf, "{}", inner);
        },
        Value.Integer => |inner| {
            try fmtBuffer(buf, "{}", inner);
        },
        Value.Float => |inner| {
            try fmtBuffer(buf, "{.5}", inner);
        },
        Value.String => |inner| {
            try fmtBuffer(buf, "\"{}\"", inner);
        },
        Value.Array => |inner| {
            var not_first = false;
            try buf.append("[");
            for (inner.toSliceConst()) |value| {
                if (not_first) {
                    try buf.append(",");
                }
                not_first = true;
                value.dump();
            }
            try buf.append("]");
        },
        Value.Object => |inner| {
            var not_first = false;
            try buf.append("{");
            var it = inner.iterator();

            while (it.next()) |entry| {
                if (not_first) {
                    try buf.append(",");
                }
                not_first = true;
                try fmtBuffer(buf, "\"{}\":", entry.key);
                try dump(entry.value, buf);
            }
            try buf.append("}");
        },
    }
}

pub fn dumpIndent(self: Value, buf: *Buffer, indent: usize) anyerror!void {
    if (indent == 0) {
        try dump(self, buf);
    } else {
        try dumpIndentLevel(self, buf, indent, 0);
    }
}

fn dumpIndentLevel(self: Value, buf: *Buffer, indent: usize, level: usize) anyerror!void {
    switch (self) {
        Value.Null => {
            try buf.append("null");
        },
        Value.Bool => |inner| {
            try fmtBuffer(buf, "{}", inner);
        },
        Value.Integer => |inner| {
            try fmtBuffer(buf, "{}", inner);
        },
        Value.Float => |inner| {
            try fmtBuffer(buf, "{.5}", inner);
        },
        Value.String => |inner| {
            try fmtBuffer(buf, "\"{}\"", inner);
        },
        Value.Array => |inner| {
            var not_first = false;
            try buf.append("[\n");

            for (inner.toSliceConst()) |value| {
                if (not_first) {
                    try buf.append(",\n");
                }
                not_first = true;
                try padSpace(buf, level + indent);
                try dumpIndentLevel(value, buf, indent, level + indent);
            }
            try buf.append("\n");
            try padSpace(buf, level);
            try buf.append("]");
        },
        Value.Object => |inner| {
            var not_first = false;
            try buf.append("{\n");
            var it = inner.iterator();

            while (it.next()) |entry| {
                if (not_first) {
                    try buf.append(",\n");
                }
                not_first = true;
                try padSpace(buf, level + indent);
                try fmtBuffer(buf, "\"{}\": ", entry.key);
                try dumpIndentLevel(entry.value, buf, indent, level + indent);
            }
            try buf.append("\n");
            try padSpace(buf, level);
            try buf.append("}");
        },
    }
}

fn padSpace(buf: *Buffer, indent: usize) !void {
    var i: usize = 0;
    while (i < indent) : (i += 1) {
        try buf.append(" ");
    }
}

test "dump" {
    var buf = &try std.Buffer.init(std.debug.global_allocator, "");
    defer buf.deinit();
    var m = json.ObjectMap.init(std.debug.global_allocator);
    defer m.deinit();
    _ = try m.put("name", Value{ .String = "gernest" });
    _ = try m.put("age", Value{ .Integer = 30 });
    var value = Value{ .Object = m };
    try dump(value, buf);
    const expect =
        \\{"name":"gernest","age":30}
    ;
    testing.expect(buf.eql(expect));
}
test "dumpIndent" {
    var buf = &try std.Buffer.init(std.debug.global_allocator, "");
    defer buf.deinit();
    var m = json.ObjectMap.init(std.debug.global_allocator);
    defer m.deinit();
    _ = try m.put("name", Value{ .String = "gernest" });
    _ = try m.put("age", Value{ .Integer = 30 });
    var value = Value{ .Object = m };
    try dumpIndent(value, buf, 2);
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
    switch (@typeInfo(T)) {
        builtin.TypeId.Struct => {
            var arena = ArenaAllocator.init(a);
            defer arena.deinit();
            var m = try encodeValue(&arena.allocator, value);
            if (m != null) {
                try dump(m.?, buf);
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

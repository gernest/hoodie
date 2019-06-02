const builtin = @import("builtin");
const std = @import("std");

const json = std.json;
const mem = std.mem;
const meta = std.meta;
const warn = std.debug.warn;

/// encode takes a value and returns json.Value that can be marshalled to json
/// object. This limits on which objects can be marshalled and also supports
/// custom encoding for objects.
///
/// Valid values supported are
/// ```
/// Integers => any integer that can be casted to i64
/// Floats => any float that can be casted to f64
/// Structs,
/// Enums,
/// Optionals.
/// HashMap => keys must be string
/// ```
/// Also Pointers to any valid objects works fine. Including Arrays,Slices of
/// valid objects.
pub fn encode(
    a: *mem.Allocator,
    value: var,
) anyerror!json.Value {
    const T = @typeOf(value);
    switch (@typeInfo(T)) {
        .Int => |elem| {
            return json.Value{ .Integer = @intCast(i64, value) };
        },
        .Float => |elem| {
            return json.Value{ .Float = @intCast(f64, value) };
        },
        .Bool => {
            if (value) {
                return json.Value{ .Bool = true };
            }
            return json.Value{ .Bool = false };
        },
        .Struct => |elem| {
            const has_cust_encode = comptime implementsEncoder(T);
            if (has_cust_encode) return value.encodeJson(a);
            const is_array_list = comptime check_array_list(T);
            if (is_array_list) return encode(a, value.toSlice());
            var m = json.ObjectMap.init(a);
            comptime var i: usize = 0;
            inline while (i < elem.fields.len) : (i += 1) {
                const field = elem.fields[i];
                if (validValue(field.field_type)) {
                    if (@typeId(field.field_type) == .Optional) {
                        if (@field(value, field.name)) |optional_value| {
                            if (validValue(@typeOf(optional_value))) {
                                _ = try m.put(field.name, try encode(a, optional_value));
                            }
                        }
                    } else {
                        _ = try m.put(field.name, try encode(a, @field(value, field.name)));
                    }
                }
            }
            return json.Value{ .Object = m };
        },
        .Pointer => |pointer| {
            switch (pointer.size) {
                .One => {
                    return encode(a, value.*);
                },
                .Slice => {
                    var ls = std.ArrayList(json.Value).init(a);
                    for (value) |elem| {
                        try ls.append(try encode(a, elem));
                    }
                    return json.Value{ .Array = ls };
                },
                else => {
                    return error.NotSupported;
                },
            }
        },
        else => {
            warn("{}\n", @typeId(T));
            return error.NotSupported;
        },
    }
}

fn implementsEncoder(comptime T: type) bool {
    return meta.trait.hasFn("encodeJson")(T);
}

const check_array_list = meta.trait.multiTrait(
    meta.trait.TraitList{
        meta.trait.hasFn("toSlice"),
        meta.trait.hasField("len"),
        meta.trait.hasField("items"),
        meta.trait.hasField("allocator"),
    },
);

/// Returns true if T is a valid value for encoding and false aotherwise.
fn validValue(comptime T: type) bool {
    switch (@typeId(T)) {
        .Int,
        .Float,
        .Bool,
        .Pointer,
        .Array,
        .Struct,
        .Optional,
        => return true,
        else => {
            return false;
        },
    }
}

test "encode" {
    var a = std.debug.global_allocator;

    const Int = struct {
        value: usize,
    };
    warn("\n");
    try testEncode(a, Int{ .value = 12 });
    // try testEncode(a, &Int{ .value = 12 });

    const Nested = struct {
        const Self = @This();
        pub fn encodeJson(self: Self, alloc: *mem.Allocator) anyerror!json.Value {
            return json.Value{ .String = "okay" };
        }
    };

    try testEncode(a, Nested{});

    const NestedPtr = struct {
        value: usize,
        child: *Int,
    };
    try testEncode(a, NestedPtr{
        .value = 12,
        .child = &Int{ .value = 12 },
    });

    const Bool = struct {
        value: bool,
    };
    // try testEncode(a, Bool{ .value = true });
    // try testEncode(a, Bool{ .value = false });

    const List = std.ArrayList(Bool);
    var list = List.init(a);
    try list.append(Bool{ .value = true });
    try testEncode(a, list);

    const Optional = struct {
        maybe: ?bool,
    };
    try testEncode(a, Optional{ .maybe = null });
    try testEncode(a, Optional{ .maybe = true });
}

fn testEncode(
    a: *mem.Allocator,
    value: var,
) !void {
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    var v = try encode(&arena.allocator, value);
    v.dump();
    warn("\n");
}

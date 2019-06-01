const builtin = @import("builtin");
const std = @import("std");

const json = std.json;
const mem = std.mem;
const meta = std.meta;
const warn = std.debug.warn;

pub fn encode(
    comptime T: type,
    a: *mem.Allocator,
    value: T,
) anyerror!json.Value {
    warn("{}\n ", @typeId(T));
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
            const has_cust_encode = comptime cf: {
                const info = @typeInfo(T);
                const defs = switch (info) {
                    builtin.TypeId.Struct => |s| s.defs,
                    builtin.TypeId.Union => |u| u.defs,
                    builtin.TypeId.Enum => |e| e.defs,
                    else => unreachable,
                };

                for (defs) |def| {
                    if (mem.eql(u8, def.name, "encodeJson")) {
                        break :cf true;
                    }
                }
                break :cf false;
            };
            if (has_cust_encode) return value.encodeJson(a);
            var m = json.ObjectMap.init(a);
            comptime var i: usize = 0;
            inline while (i < elem.fields.len) : (i += 1) {
                const field = elem.fields[i];
                _ = try m.put(field.name, try encode(
                    field.field_type,
                    a,
                    @field(value, field.name),
                ));
            }
            return json.Value{ .Object = m };
        },
        else => {
            return error.NotSupported;
        },
    }
}

fn valid(value: var) bool {
    switch (@typeId(@typeOf(value))) {
        .Int, .Float, .Pointer, .Array, .Struct => return true,
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
    try testEncode(Int, a, Int{ .value = 12 });
    // try testEncode(a, &Int{ .value = 12 });

    const Nested = struct {
        const Self = @This();
        pub fn encodeJson(self: Self, alloc: *mem.Allocator) anyerror!json.Value {
            return json.Value{ .String = "okay" };
        }
    };

    try testEncode(Nested, a, Nested{});

    const NestedPtr = struct {
        value: usize,
        child: *Int,
    };
    // try testEncode(a, NestedPtr{
    //     .value = 12,
    //     .child = &Int{ .value = 12 },
    // });

    const Bool = struct {
        value: bool,
    };
    // try testEncode(a, Bool{ .value = true });
    // try testEncode(a, Bool{ .value = false });

    // const List = std.ArrayList(Bool);
    // var list = List.init(a);
    // try list.append(Bool{ .value = true });
    // try testEncode(a, list);

    try testEncode(bool, a, true);
}

fn testEncode(
    comptime T: type,
    a: *mem.Allocator,
    value: var,
) !void {
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    var v = try encode(T, &arena.allocator, value);
    v.dump();
    warn("\n");
}

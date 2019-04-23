const std = @import("std");
const json = std.json;
const typeId = @import("builtin").TypeId;
const warn = std.debug.warn;

fn encode(comptime T: type, value: T) ?json.Value {
    const id = @typeId(T);
    return switch (id) {
        typeId.Bool => json.Value{ .Bool = value },
        typeId.Int => json.Value{ .Int = value },
        typeId.Float => json.Value{ .Float = value },
        else => null,
    };
}

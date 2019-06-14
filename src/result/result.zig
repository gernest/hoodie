/// Generic result  with extra context for rich functional api.
pub fn Result(comptime T: type, comptime E: type) type {
    return union(enum) {
        Ok: T,
        Err: E,

        const Self = @This();

        pub fn Some(value: T) Self {
            return Self{ .Ok = value };
        }

        pub fn Raise(reason: E) Self {
            return Self{
                .Err = reason,
            };
        }
    };
}

/// Clean shorthand for Result(T,[]const u8)
pub fn Clean(comptime T: type) type {
    return Result(T, []const u8);
}

const std = @import("std");

pub const Diff = struct {
    list: OpList,
    pub const OpList = std.ArrayList(*Op);
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
};

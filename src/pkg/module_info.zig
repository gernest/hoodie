const time = @import("../time/time.zig");

pub const ModulePublic = struct {
    path: []const u8,
    version: ?[]const u8,
    versions: ?std.ArrayList([]const u8),
    replace: ?ModulePublic,
    update: ?ModulePublic,
    time: ?time.Time,
    main: bool,
    indirect: bool,
    dir: ?[]const u8,
    zig_mod: ?[]const u8,
    zig_version: ?[]const u8,
    err: ?[]const u8,

    pub fn format(
        self: ModulePublic,
        comptime fmt: []const u8,
        comptime options: std.fmt.FormatOptions,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        try output(self.path);
        if (self.version) |version| {
            try output(context, " ");
            try output(context, version);
            if (self.update) |update| {
                try output(context, " [");
                try output(context, update.version.?);
                try output(context, "]");
            }
        }
        if (self.replace) |replace| {
            try output(context, " => ");
            try output(context, replace.path);
            if (replace.version) |version| {
                try output(context, " ");
                try output(context, version);
                if (replace.update) |update| {
                    try output(context, " [");
                    try output(context, update.version.?);
                    try output(context, "]");
                }
            }
        }
    }
};

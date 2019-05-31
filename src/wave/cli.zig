const std = @import("std");

const mem = std.mem;
const warn = std.debug.warn;

pub const Cli = struct {
    name: []const u8,
    commands: []const Command,
    flags: ?[]const Flag,
    action: fn (
        ctx: *Context,
        stdin: var,
        stdout: var,
        stderr: var,
    ) anyerror!void,

    fn parse(self: *Cli, a: *Allocator, args: *Args) !Context {
        var it = args.iterator(0);
        if (it.peek() == 0) {
            // no any arguments were provided. We return context with the global
            // command set or help text if no action was provided on Cli object.
            return Context{
                .cli = self,
                .args = args,
                .mode = .Global,
                .args_position = 0,
            };
        }

        var ctx = Context{
            .cli = self,
            .args = args,
            .mode = .Local,
            .command = null,
            .args_position = 0,
        };

        var global_scope = true;
        while (it.peek()) |next_arg| {
            switch (checkFlag(next_arg)) {
                .Short => |flag| {
                    if (global_scope) {
                        try ctx.addShortGlobalFlag(flag, it);
                    } else {
                        try ctx.addShortLocalFlag(flag, it);
                    }
                },
                .Long => |flag| {
                    if (global_scope) {
                        try ctx.addLongGlobalFlag(flag, it);
                    } else {
                        try ctx.addLongLocalFlag(flag, it);
                    }
                },
                .None => {
                    if (ctx.command) |cmd| {
                        if (cmd.sub_commands != null) {
                            var match = false;
                            for (cmd.sub_commands.?) |sub| {
                                if (mem.eql(u8, next_arg, sub.name)) {
                                    ctx.command = &sub;
                                    match = true;
                                }
                            }
                            if (!match) {
                                // raise the error for unknown command
                            }
                        } else {
                            // No need to keep going. We take everything that is
                            // left on argument list to be the arguments passed
                            // to the active command.
                            ctx.args_position = it.position;
                            break;
                        }
                    } else {
                        if (ctx.cli.commands) |cmds| {
                            for (cmds) |cmd| {
                                var match = false;
                                for (cmd.sub_commands.?) |sub| {
                                    if (mem.eql(u8, next_arg, sub.name)) {
                                        ctx.command = &sub;
                                        match = true;
                                    }
                                }
                                if (!match) {
                                    // raise the error for unknown command
                                } else {
                                    global_scope = false;
                                }
                            }
                        } else {
                            ctx.args_position = it.position;
                            break;
                        }
                    }
                },
                else => unreachable,
            }
            _ = it.next();
        }
        return ctx;
    }
};

fn checkFlag(s: []const u8) Flag.Type {
    if (s.len == 2) {
        if (s[0] == '-' and s[1] != '-') {
            return Flag.Type{ .Short = s[1] };
        }
    }
    if (s.len == 0) return .None;
}

pub const Command = struct {
    name: []const u8,
    flags: ?[]const Flag,

    // nested commands that uses the current command as a namespace.
    sub_commands: ?[]Command,

    /// This is the function that will be called when this command is matched.
    ///  stdin,stdout and stderr are streams for writing results. There is no
    /// need for the fucntion to call os.exit. Any error returned will result in
    /// the program to exit with os.exit(1).
    action: fn (
        ctx: *Context,
        stdin: var,
        stdout: var,
        stderr: var,
    ) anyerror!void,
};

/// represent a commandline flag. This is text after - or --
/// for instance
///  -f test.txt
///  --f test.txt
/// The above example `f` is the flag name and test.txt is the flag value.
pub const Flag = struct {
    name: []const u8,
    kind: Kind,

    // used internally
    index: ?usize,

    pub const Kind = enum {
        Bool,
        String,
        Number,
    };

    pub fn init(name: []const u8, kind: Kind) Flag {
        return Flag{ .name = name, .kind = kind, .index = 0 };
    }

    pub const Type = enum {
        None,
        Short: u8,
        Long: []const u8,
    };
};

pub const FlagSet = struct {
    list: List,
    pub const List = std.ArrayList(*Flag);
};

// Context stores information about the application.

pub const Context = struct {
    cli: *Cli,
    args: *Args,
    command: ?*Command,
    mode: Mode,
    argumet_position: usize,

    pub const Mode = enum {
        Global,
        Local,
    };

    // Returns the value that was assigned to the flag fname.
    pub fn flag(self: *Context, T: type, name: []const u8) !@typeOf(T) {}
};

pub const Args = struct {
    args: List,
    a: *mem.Allocator,
    pub const List = std.ArrayList([]const u8);

    pub fn init(a: *mem.Allocator) Args {
        return Args{
            .a = a,
            .args = List.init(a),
        };
    }

    pub fn initList(a: *mem.Allocator, ls: []const []const u8) !Args {
        var arg = init(a);
        try arg.addList(ls);
        return arg;
    }

    pub fn addList(self: *Args, ls: []const []const u8) !void {
        for (ls) |_, i| {
            try self.addCopy(ls[i]);
        }
    }

    pub fn add(self: *Args, elem: []const u8) !void {
        return self.args.append(elem);
    }

    pub fn addCopy(self: *Args, elem: []const u8) !void {
        const cp = try mem.dupe(self.a, u8, elem);
        return self.args.append(cp);
    }

    pub const Iterator = struct {
        args: *Args,
        position: usize,

        pub fn next(self: *Iterator) ?[]const u8 {
            if (self.position >= self.args.len) return null;
            const e = self.args.at(self.position);
            self.position += 1;
            return e;
        }

        pub fn peek(self: *Iterator) ?[]const u8 {
            if (self.position >= self.args.size) return null;
            const e = self.args.at(self.position);
            return e;
        }
    };

    pub fn at(self: *Args, index: usize) []const u8 {
        return self.args.toSlice()[index];
    }

    pub fn iterator(self: *Args, index: usize) Iterator {
        return Iterator{
            .args = self,
            .position = index,
        };
    }
};

test "command" {
    var a = std.debug.global_allocator;
    var args = try Args.initList(a, []const []const u8{
        "hoodie", "fmt", "-m",
    });

    const app = Cli{
        .name = "hoodie",
        .flags = null,
        .commands = []const Command{
            Command{
                .name = "fmt",
                .flags = []const Flag{Flag{ .name = "f", .kind = .Bool, .index = 0 }},
                .action = nothing,
                .sub_commands = null,
            },
            Command{
                .name = "outline",
                .flags = null,
                .action = nothing,
                .sub_commands = null,
            },
        },
        .action = nothing,
    };
}

fn nothing(
    comptime ctx: *Context,
    stdin: var,
    stdout: var,
    stderr: var,
) anyerror!void {}

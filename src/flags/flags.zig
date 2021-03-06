const std = @import("std");

const fs = std.fs;
const io = std.io;

const mem = std.mem;
const testing = std.testing;
const warn = std.debug.warn;

const StdInStream = io.InStream(fs.File.ReadError);
const StdOutStream = io.OutStream(fs.File.WriteError);
const StdErrStream = io.OutStream(fs.File.WriteError);

/// Defines a commandline application.
pub const Cli = struct {
    name: []const u8,
    commands: ?[]const Command,
    flags: ?[]const Flag,
    action: ?fn (
        ctx: *Context,
    ) anyerror!void,

    pub fn format(
        self: Cli,
        comptime fmt: []const u8,
        comptime options: std.fmt.FormatOptions,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        try std.fmt.format(
            context,
            Errors,
            output,
            "{} - a commandline app \n",
            self.name,
        );
        try output(context, "USAGE\n");
        try std.fmt.format(
            context,
            Errors,
            output,
            "  {} [GLOBAL FLAG] command [FLAG] \n",
            self.name,
        );
        try output(context, "list of commands :\n");
        if (self.commands) |commands| {
            for (commands) |cmd| {
                try std.fmt.format(context, Errors, output, "    {} -\n", cmd.name);
            }
        }
    }

    pub fn run(
        self: *const Cli,
        a: *mem.Allocator,
        arg: []const []u8,
        stdin: ?*StdInStream,
        stdout: ?*StdOutStream,
        stderr: ?*StdErrStream,
    ) !void {
        var args = &try Args.initList(a, arg);
        defer args.deinit();
        var ctx = &try self.parse(a, args);
        ctx.stdin = stdin;
        ctx.stdout = stdout;
        ctx.stderr = stderr;
        if (ctx.command) |cmd| {
            if (ctx.show_help) {
                if (stdout != null) {
                    try stdout.?.print("{}\n", cmd);
                }
                return;
            }
            if (cmd.action) |action| {
                try action(ctx);
            }
            return;
        }
        if (stdout != null) {
            try stdout.?.print("{}\n", self);
        }
    }

    // parses args and finds which commands is to be invoked.
    pub fn parse(self: *const Cli, a: *mem.Allocator, args: *Args) !Context {
        var it = &args.iterator(0);
        if (it.peek() == null) {
            // no any arguments were provided. We return context with the global
            // command set or help text if no action was provided on Cli object.
            return Context{
                .allocator = a,
                .cli = self,
                .args = args,
                .mode = .Global,
                .global_flags = FlagSet.init(a),
                .local_flags = FlagSet.init(a),
                .args_position = 0,
                .command = null,
                .stdin = null,
                .stdout = null,
                .stderr = null,
                .show_help = false,
            };
        }

        var ctx = Context{
            .allocator = a,
            .cli = self,
            .args = args,
            .mode = .Local,
            .global_flags = FlagSet.init(a),
            .local_flags = FlagSet.init(a),
            .command = null,
            .args_position = 0,
            .stdin = null,
            .stdout = null,
            .stderr = null,
            .show_help = false,
        };

        var global_scope = true;
        while (it.peek()) |next_arg| {
            if (checkFlag(next_arg)) |flag| {
                if (global_scope) {
                    if (isHelpFlag(flag)) {
                        ctx.show_help = true;
                    } else {
                        try ctx.addGlobalFlag(flag, it);
                    }
                } else {
                    try ctx.addLocalFlag(flag, it);
                }
            } else {
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
                            return error.CommandNotFound;
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
                        var match = false;
                        for (cmds) |cmd| {
                            if (mem.eql(u8, cmd.name, next_arg)) {
                                ctx.command = &cmd;
                                match = true;
                            }
                        }
                        if (!match) {
                            return error.CommandNotFound;
                        }
                        global_scope = false;
                    } else {
                        break;
                    }
                }
            }
            _ = it.next();
        }
        ctx.args_position = it.position;
        return ctx;
    }
};

fn isHelpFlag(s: []const u8) bool {
    if (mem.eql(u8, s, "h")) {
        return true;
    }
    return mem.eql(u8, s, "help");
}

fn checkFlag(s: []const u8) ?[]const u8 {
    if (s.len <= 1) return null;
    var i: usize = 0;
    for (s) |x| {
        if (x == '-') {
            i += 1;
        } else {
            break;
        }
    }
    if (i == 0) return null;
    if (i <= 2 and i < s.len) return s[i..];
    return null;
}

pub const Command = struct {
    name: []const u8,
    flags: ?[]const Flag,

    // nested commands that uses the current command as a namespace.
    sub_commands: ?[]const Command,

    /// This is the function that will be called when this command is matched.
    ///  stdin,stdout and stderr are streams for writing results. There is no
    /// need for the fucntion to call os.exit. Any error returned will result in
    /// the program to exit with os.exit(1).
    action: ?fn (
        ctx: *Context,
    ) anyerror!void,

    pub fn format(
        self: Command,
        comptime fmt: []const u8,
        comptime options: std.fmt.FormatOptions,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        try std.fmt.format(context, Errors, output, "{}\n", self.name);
        try output(context, "list of flags:\n");
        if (self.flags) |flags| {
            for (flags) |flag| {
                try std.fmt.format(context, Errors, output, "{}\n", flag);
            }
        }
    }
};

/// represent a commandline flag. This is text after - or --
/// for instance
///  -f test.txt
///  --f test.txt
/// The above example `f` is the flag name and test.txt is the flag value.
pub const Flag = struct {
    name: []const u8,

    /// desc text explaining what this flag is doing.
    desc: ?[]const u8,

    /// the type of value this flag accepts.
    kind: Kind,

    pub const Kind = enum {
        Bool,
        String,
        Number,
    };

    pub fn format(
        self: Flag,
        comptime fmt: []const u8,
        comptime options: std.fmt.FormatOptions,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        if (self.name.len > 1) {
            try std.fmt.format(
                context,
                Errors,
                output,
                "    --{}   {}\n",
                self.name,
                self.desc,
            );
        } else {
            try std.fmt.format(
                context,
                Errors,
                output,
                "    -{}   {}\n",
                self.name,
                self.desc,
            );
        }
    }

    pub fn init(name: []const u8, kind: Kind) Flag {
        return Flag{
            .name = name,
            .desc = null,
            .kind = kind,
        };
    }
};

pub const FlagSet = struct {
    list: List,
    pub const List = std.ArrayList(FlagItem);

    /// stores the flag and the position where the flag was found. Allows easy
    /// getting the value of the flag from arguments linst.
    pub const FlagItem = struct {
        flag: Flag,
        index: usize,
    };

    pub fn init(a: *mem.Allocator) FlagSet {
        return FlagSet{ .list = List.init(a) };
    }

    pub fn get(self: FlagSet, name: []const u8) ?FlagItem {
        for (self.list.toSlice()) |f| {
            if (mem.eql(u8, f.flag.name, name)) {
                return f;
            }
        }
        return null;
    }

    // prints all flags contained in this flag set
    pub fn format(
        self: FlagSet,
        comptime fmt: []const u8,
        comptime options: std.fmt.FormatOptions,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        for (self.list.toSlice()) |item| {
            try std.fmt.format(context, Errors, output, "{}", item);
        }
    }

    pub fn addFlag(self: *FlagSet, flag: Flag, index: usize) !void {
        try self.list.append(FlagItem{
            .flag = flag,
            .index = index,
        });
    }
};

/// Context stores information about the application.
pub const Context = struct {
    allocator: *mem.Allocator,
    cli: *const Cli,
    args: *const Args,
    command: ?*const Command,
    mode: Mode,
    args_position: usize,
    global_flags: FlagSet,
    local_flags: FlagSet,
    stdin: ?*StdInStream,
    stdout: ?*StdOutStream,
    stderr: ?*StdErrStream,
    show_help: bool,
    pub const Mode = enum {
        Global,
        Local,
    };

    pub fn addGlobalFlag(self: *Context, name: []const u8, it: *Args.Iterator) !void {
        if (self.cli.flags) |flags| {
            for (flags) |f| {
                if (mem.eql(u8, f.name, name)) {
                    try self.global_flags.addFlag(f, it.position);
                    return;
                }
            }
        }
        return error.UknownFlag;
    }

    pub fn addLocalFlag(self: *Context, name: []const u8, it: *Args.Iterator) !void {
        if (self.command) |cmd| {
            if (cmd.flags) |flags| {
                for (flags) |f| {
                    if (mem.eql(u8, f.name, name)) {
                        try self.local_flags.addFlag(f, it.position);
                        return;
                    }
                }
            }
        }
        return error.UknownFlag;
    }

    pub fn flag(ctx: *const Context, name: []const u8) ?FlagSet.FlagItem {
        return ctx.local_flags.get(name);
    }

    pub fn boolean(ctx: *const Context, name: []const u8) bool {
        if (ctx.flag(name)) |_| {
            // boolean flags don't carry any values. If they are present then ii implies the flag is set to true.
            return true;
        }
        return false;
    }

    pub fn getArgs(self: *const Context) Args.Iterator {
        return self.args.iterator(self.args_position);
    }

    pub fn firstArg(self: *const Context) ?[]const u8 {
        if (self.args_position >= self.args.args.len) return null;
        return self.args.args.at(self.args_position);
    }
};

pub const Args = struct {
    args: List,
    a: *mem.Allocator,
    pub const List = std.ArrayList([]const u8);

    pub const Iterator = struct {
        args: *const Args,
        position: usize,

        pub fn next(self: *Iterator) ?[]const u8 {
            if (self.position >= self.args.args.len) return null;
            const e = self.args.at(self.position);
            self.position += 1;
            return e;
        }

        pub fn peek(self: *Iterator) ?[]const u8 {
            if (self.position >= self.args.args.len) return null;
            const e = self.args.at(self.position);
            return e;
        }
    };

    pub fn init(a: *mem.Allocator) Args {
        return Args{
            .a = a,
            .args = List.init(a),
        };
    }

    pub fn deinit(self: Args) void {
        self.args.deinit();
    }

    pub fn initList(a: *mem.Allocator, ls: []const []const u8) !Args {
        var arg = init(a);
        try arg.addList(ls);
        return arg;
    }

    pub fn addList(self: *Args, ls: []const []const u8) !void {
        for (ls) |_, i| {
            try self.add(ls[i]);
        }
    }

    pub fn add(self: *Args, elem: []const u8) !void {
        return self.args.append(elem);
    }

    pub fn at(self: *const Args, index: usize) []const u8 {
        return self.args.toSlice()[index];
    }

    pub fn iterator(self: *const Args, index: usize) Iterator {
        return Iterator{
            .args = self,
            .position = index,
        };
    }
};

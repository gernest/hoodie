const Dump = @import("json").Dump;
const std = @import("std");

const Allocator = std.mem.Allocator;
const event = std.event;
const io = std.io;
const json = std.json;
const mem = std.mem;
const warn = std.debug.warn;

pub const json_rpc_version = "2.0";
const content_length = "Content-Length";
const default_message_size: usize = 8192;

pub const Error = struct {
    code: i64,
    message: []const u8,
    data: ?json.Value,

    pub const Code = enum(i64) {
        // UnknownError should be used for all non coded errors.
        UnknownError = -32001,

        // ParseError is used when invalid JSON was received by the server.
        ParseError = -32700,

        //InvalidRequest is used when the JSON sent is not a valid Request object.
        InvalidRequest = -32600,

        // MethodNotFound should be returned by the handler when the method does
        // not exist / is not available.
        MethodNotFound = -32601,

        // InvalidParams should be returned by the handler when method
        // parameter(s) were invalid.
        InvalidParams = -32602,

        // InternalError is not currently returned but defined for completeness.
        InternalError = -32603,

        //ServerOverloaded is returned when a message was refused due to a
        //server being temporarily unable to accept any new messages.
        ServerOverloaded = -32000,
    };
};

pub const Request = struct {
    jsonrpc: []const u8,
    method: []const u8,
    params: ?json.Value,
    id: ?ID,

    pub fn init(m: *const json.ObjectMap) !Request {
        var req: Request = undefined;
        if (m.get("jsonrpc")) |kv| {
            req.jsonrpc = kv.value.String;
        }
        if (m.get("method")) |kv| {
            req.method = kv.value.String;
        }
        if (m.get("params")) |kv| {
            req.params = kv.value;
        } else {
            req.params = null;
        }
        if (m.get("id")) |kv| {
            switch (kv.value) {
                .String => |v| {
                    req.id = ID{ .Name = v };
                },
                .Integer => |v| {
                    req.id = ID{ .Number = v };
                },
                else => return error.WrongIDValue,
            }
        } else {
            req.id = null;
        }
        return req;
    }
};

pub const ID = union(enum) {
    Name: []const u8,
    Number: i64,

    pub fn encode(self: ID, a: *Allocator) json.Value {
        switch (self) {
            ID.Name => |v| {
                return json.Value{ .String = v };
            },
            ID.Number => |v| {
                return json.Value{ .Integer = v };
            },
            else => unreachable,
        }
    }

    pub fn decode(self: *ID, value: json.Value) !void {
        switch (value) {
            json.Value.Integer => |v| {
                self.* = ID{ .Number = v };
            },
            json.Value.String => |v| {
                self.* = ID{ .Name = v };
            },
            else => return error.BadValue,
        }
    }
};

pub const Response = struct {
    jsonrpc: []const u8,
    result: ?json.Value,
    err: ?Error,
    id: ?ID,

    fn init(req: *Request) Response {
        return Response{
            .jsonrpc = req.jsonrpc,
            .result = null,
            .err = null,
            .id = req.id,
        };
    }

    pub fn encode(self: *Response, a: *Allocator) !json.Value {
        var m = json.ObjectMap.init(a);
        _ = try m.put("jsonrpc", json.Value{ .String = json_rpc_version });
        if (self.result != null) {
            _ = try m.put("result", self.result.?);
        }
        if (self.err) |*v| {
            // _ = try m.put("error", try v.encode(a));
        }
        if (self.id) |v| {
            _ = try m.put("id", v.encode(a));
        }
        return json.Value{ .Object = m };
    }
};

// Context is a rpc call lifecycle object. Contains the rpc request and the
// reponse of serving the request.
pub const Context = struct {
    request: *Request,
    response: *Response,
    arena: std.heap.ArenaAllocator,

    // The requestParams might contain a json.Value object. The memory
    // allocated on that object is in scope with this tree, so we keep this
    // reference here to ensure all memory used in the duration of this
    // context is properly freed when destorying the context.
    tree: json.ValueTree,

    pub fn init(a: *Allocator) !Context {
        var self: Context = undefined;
        self.arena = std.heap.ArenaAllocator.init(a);
        var alloc = &self.arena.allocator;
        self.request = try alloc.create(Request);
        self.response = try alloc.create(Response);
        self.tree = undefined;
        return self;
    }

    pub fn deinit(self: *Context) void {
        (&self.tree).deinit();
        (&self.arena).deinit();
    }

    pub fn write(self: *Context, value: ?json.Value) void {
        self.response.result = value;
    }

    pub fn writeError(self: *Context, value: ?Error) void {
        self.response.err = value;
    }
};

pub const Conn = struct {
    a: *Allocator,
    handler: *const Handler,
    const channel_buffer_size = 10;

    const ContextChannel = std.event.Channel(*Context);
    pub const Handler = struct {
        handleFn: fn (*const Handler, *Context) anyerror!void,

        pub fn serve(self: *const Handler, ctx: *Context) anyerror!void {
            return self.handleFn(self, ctx);
        }
    };

    pub fn init(
        a: *Allocator,
        handler: *const Handler,
    ) Conn {
        var conn = Conn{
            .a = a,
            .handler = handler,
        };
        return conn;
    }

    pub fn serve(self: *Conn, loop: *event.Loop, in: var, out: var) anyerror!void {
        var context_channel = try ContextChannel.create(loop, 1);
        const reader = try async<loop.allocator> read(context_channel, in, self);
        const writer = try async<loop.allocator> write(context_channel, out, self);
        defer {
            cancel reader;
            cancel writer;
            context_channel.destroy();
        }
        loop.run();
    }

    async fn read(
        context_channel: *ContextChannel,
        in: *std.fs.File.InStream.Stream,
        self: *Conn,
    ) void {
        var buffer = std.Buffer.init(self.a, "") catch |err| {
            std.debug.warn("{} \n", err);
            return;
        };
        var buf = &buffer;
        defer buf.deinit();
        var p = &json.Parser.init(self.a, true);
        defer p.deinit();
        while (true) {
            var ctx = self.a.create(Context) catch |err| {
                return;
            };
            ctx.* = Context.init(self.a) catch |err| {
                return;
            };
            buf.resize(0) catch |_| return;
            p.reset();
            readRequestData(buf, in) catch |err| {
                std.debug.warn(" err {} \n", err);
                return;
            };
            std.debug.warn("reading stuff\n");

            var v = p.parse(buf.toSlice()) catch |err| {
                return;
            };
            switch (v.root) {
                json.Value.Object => |*m| {
                    var req: Request = undefined;
                    ctx.tree = v;
                    ctx.request.* = Request.init(m) catch |err| {
                        std.debug.warn("{} \n", err);
                        return;
                    };
                    ctx.response.* = Response.init(ctx.request);
                },
                else => unreachable,
            }
            // await (async context_channel.put(ctx) catch @panic("out of memory"));
            // std.debug.warn("sent to channel  {} \n", context_channel.put_count);
        }
    }

    async fn write(
        context_channel: *ContextChannel,
        out: *std.fs.File.OutStream.Stream,
        self: *Conn,
    ) void {
        // while (true) {
        //     const h = async context_channel.get() catch @panic("out of memory");
        //     var ctx = await h;
        //     std.debug.warn("writing\n");
        //     handleWrite(ctx, out, self) catch |err| {
        //         std.debug.warn("{} \n", err);
        //         return;
        //     };
        // }
    }

    fn handleWrite(
        ctx: *Context,
        out: *std.fs.File.OutStream.Stream,
        self: *Conn,
    ) !void {
        defer {
            ctx.deinit();
            self.a.destroy(ctx);
        }
        try self.handler.serve(ctx);
        try writeResponseData(ctx, out);
    }

    pub fn readRequestData(buf: *std.Buffer, stream: var) !void {
        var length: usize = 0;
        while (true) {
            try stream.readUntilDelimiterBuffer(
                buf,
                '\n',
                default_message_size,
            );
            const line = trimSpace(buf.toSlice());
            if (line.len == 0) {
                break;
            }
            const colon = mem.indexOfScalar(u8, line, ':') orelse return error.InvalidHeader;
            const name = line[0..colon];
            const value = trimSpace(line[colon + 1 ..]);
            if (mem.eql(u8, name, content_length)) {
                length = try std.fmt.parseInt(usize, value, 10);
            }
        }
        if (length == 0) {
            return error.MissingContentLengthHeader;
        }
        try buf.resize(length);
        const n = try stream.read(buf.toSlice());
        std.debug.assert(n == length);
    }

    pub fn writeResponseData(ctx: *Context, stream: var) !void {
        var a = &ctx.arena.allocator;
        var buf = &try std.Buffer.init(a, "");
        var buf_stream = &std.io.BufferOutStream.init(buf).stream;
        var dump = &try Dump.init(a);
        var v = try ctx.response.encode(a);
        try dump.dump(v, buf_stream);
        try stream.print("Content-Length: {}\r\n\r\n", buf.len());
        try stream.write(buf.toSlice());
    }
};

// simple adhoc way for removing starting and trailing whitespace.

fn trimSpace(s: []const u8) []const u8 {
    return mem.trim(u8, s, [_]u8{ ' ', '\n', '\r' });
}

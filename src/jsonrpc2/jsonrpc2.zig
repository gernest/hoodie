const std = @import("std");
const json = std.json;
const Allocator = std.mem.Allocator;
const io = std.io;
const event = std.event;
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

    pub fn encode(self: *Response, a: *Allocator) !json.Value {
        var m = json.ObjectMap.init(a);
        _ = try m.put("jsonrpc", json.Value{ .String = self.jsonrpc });
        if (self.result != null) {
            _ = try m.put("result", self.result.?);
        }
        if (self.err) |*v| {
            _ = try m.put("error", try v.encode(a));
        }
        if (self.id) |v| {
            _ = try m.put("id", v.encode(a));
        }
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
        self.request = alloc.create(Request);
        self.response = alloc.create(Response);
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

pub const Handler = struct {
    handleFn: fn (*Context) anyerror!void,
};

pub const Conn = struct {
    const ReadError = std.os.File.ReadError || error{};
    const WriteError = std.os.File.WriteError || error{OutOfMemory} || error{};

    const channel_buffer_size = 10;

    pub const InStream = io.InStream(ReadError);
    pub const OutStream = *io.OutStream(WriteError);

    a: *Allocator,
    in: *InStream,
    out: *OutStream,
    requests_channel: *ContextChannel,
    responses_channel: *ContextChannel,

    const ContextChannel = event.Channel(*Context);

    pub fn init(
        a: *Allocator,
        in_stream: *InStream.Stream,
        out_stream: *OutStream.Stream,
    ) Conn {
        return Conn{
            .a = a,
            .in = in_stream,
            .out = out_stream,
            .requests_channel = undefined,
            .responses_channel = undefined,
        };
    }

    pub fn serve(self: *Conn, loop: *event.Loop) anyerror!void {
        self.requests_channel = try ContextChannel.create(loop, channel_buffer_size);
        self.responses_channel = try ContextChannel.create(loop, channel_buffer_size);
    }

    async fn read(self: *Conn, loop: *event.Loop) !void {
        var buf = &try std.Buffer.init(self.a, "");
        defer buf.deinit();
        try self.readRequestData(buf, self.in_stream);
        var p = &json.Parser.init(self.a, true);
        defer p.deinit();
        while (true) {
            var ctx = try self.a.create(Context);
            try buf.resize(0);
            p.reset();

            var v = try p.parse(buf.toSlice());
            switch (v.root) {
                json.Value.Object => |*m| {
                    var req: Request = undefined;
                    ctx.tree = v;
                    ctx.request.* = req;
                },
                else => return error.InvalidRPCPayload,
            }
            v.deinit();
        }
    }

    async fn write(self: *Conn, loop: *event.Loop) !void {
        while (true) {
            const ctx = await (try async self.responses_channel.get());

            // cleanup all memory allocated during the lifetime of the
            // context.
            ctx.deinit();
        }
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
};

// simple adhoc way for removing starting and trailing whitespace.
fn trimSpace(s: []const u8) []const u8 {
    return mem.trim(u8, s, []const u8{ ' ', '\n', '\r' });
}

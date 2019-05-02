const std = @import("std");
const json = std.json;

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

pub const RPC = struct {
    pub const Request = struct {
        jsonrpc: []const u8,
        method: []const u8,
        params: ?json.Value,
        id: ?ID,
    };

    pub const ID = union {
        Name: []const u8,
        Number: i64,
    };

    pub const Response = struct {
        jsonrpc: []const u8,
        result: ?json.Value,
        err: ?Error,
        id: ?ID,
    };
};

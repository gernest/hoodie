const std = @import("std");

const fs = std.fs;
const Dir = fs.Dir;
const File = fs.File;
const Entry = fs.Dir.Entry;
const io = std.io;
const json = std.json;
const mem = std.mem;
const path = std.fs.path;
const warn = std.debug.warn;

pub const Export = struct {
    base: []const u8,
    arena: std.heap.ArenaAllocator,
    allocator: *mem.Allocator,
    list: List,

    pub const List = std.ArrayList(*Pkg);
    pub const export_file = "exports.zig";

    pub const Pkg = struct {
        name: []const u8,
        path: []const u8,

        pub fn dump(self: *Pkg, level: usize) void {}

        fn pad(times: usize) void {
            var i: usize = 0;
            while (i < times) : (i += 1) {
                warn(" ");
            }
        }
    };

    pub fn deinit(self: *Export) void {
        self.arena.deinit();
        self.list.deinit();
    }

    pub fn init(a: *mem.Allocator, base: []const u8) Export {
        return Export{
            .base = base,
            .arena = std.heap.ArenaAllocator.init(a),
            .allocator = a,
            .list = List.init(a),
        };
    }

    pub fn dump(self: *Export) !void {
        var buf = &try std.Buffer.init(self.allocator, "");
        defer buf.deinit();
        for (self.list.toSlice()) |p| {
            try buf.resize(0);
            try buf.append("Pkg{.name=\"");
            try buf.append(p.name);
            try buf.append("\",.path=\"");
            try buf.append(p.path);
            try buf.append("\"},");
            warn("{}\n", buf.toSlice());
        }
    }

    pub fn dumpStream(self: *Export, stream: var) !void {
        var buf = &try std.Buffer.init(self.allocator, "");
        defer buf.deinit();
        for (self.list.toSlice()) |p| {
            try buf.resize(0);
            try buf.append("Pkg{.name=\"");
            try buf.append(p.name);
            try buf.append("\",.path=\"");
            try buf.append(p.path);
            try buf.append("\"},");
            try stream.print("{}\n", buf.toSlice());
        }
    }

    pub fn dir(self: *Export, full_path: []const u8) !void {
        try self.walkTree(full_path, full_path);
    }

    fn pkg(self: *Export, root: []const u8, name: []const u8, pkg_path: []const u8) !void {
        var a = &self.arena.allocator;
        var p = try a.create(Pkg);
        p.* = Pkg{
            .name = stripExtension(name),
            .path = pkg_path,
        };
        try self.list.append(p);
    }

    fn walkTree(self: *Export, root: []const u8, full_path: []const u8) anyerror!void {
        var a = &self.arena.allocator;

        // If we have a [basename].zig file then we use it as exported for the
        // given package
        //
        // example src/apples/apples.zig
        const base = path.basename(full_path);
        var ext = try self.allocator.alloc(u8, base.len + 4);
        mem.copy(u8, ext, base);
        mem.copy(u8, ext[base.len..], ".zig");
        errdefer self.allocator.free(ext);
        defer self.allocator.free(ext);

        const defaults = [_][]const u8{
            "exports.zig",
            "index.zig",
            ext,
        };
        for (defaults) |default_file| {
            const default_file_path = try path.join(self.allocator, [_][]const u8{
                full_path,
                default_file,
            });
            errdefer self.allocator.free(default_file_path);
            if (fileExists(default_file_path)) {
                try self.pkg(
                    root,
                    try path.relative(a, root, full_path),
                    try path.relative(a, self.base, default_file_path),
                );
                self.allocator.free(default_file_path);
                return;
            } else {
                self.allocator.free(default_file_path);
            }
        }
        var directory = try Dir.open(self.allocator, full_path);
        defer directory.close();
        var full_entry_buf = &try std.Buffer.init(self.allocator, "");
        defer full_entry_buf.deinit();
        while (try directory.next()) |entry| {
            if (!accept(entry)) {
                continue;
            }
            try full_entry_buf.resize(full_path.len + entry.name.len + 1);
            const full_entry_path = full_entry_buf.toSlice();
            mem.copy(u8, full_entry_path, full_path);
            full_entry_path[full_path.len] = path.sep;
            mem.copy(u8, full_entry_path[full_path.len + 1 ..], entry.name);
            switch (entry.kind) {
                Entry.Kind.File => {
                    try self.pkg(
                        root,
                        try path.relative(a, root, full_entry_path),
                        try path.relative(a, self.base, full_entry_path),
                    );
                },
                Entry.Kind.Directory => {
                    try self.walkTree(root, full_entry_path);
                },
                else => {},
            }
        }
    }
};

fn stripExtension(s: []const u8) []const u8 {
    return mem.trimRight(u8, s, ".zig");
}

fn accept(e: Entry) bool {
    switch (e.kind) {
        .File => {
            if (mem.endsWith(u8, e.name, ".zig")) {
                return true;
            }
        },
        .Directory => {
            if (!mem.eql(u8, e.name, "zig-cache")) {
                return true;
            }
        },
        else => {},
    }
    return false;
}

/// returuns true if file exists.
pub fn fileExists(name: []const u8) bool {
    var file = File.openRead(name) catch |err| {
        switch (err) {
            error.FileNotFound => return false,
            else => {
                warn("open: {} {}\n", name, err);
                return false;
            },
        }
    };
    file.close();
    return true;
}

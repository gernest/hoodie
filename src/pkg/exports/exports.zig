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
        path: [][]const u8,
    };

    pub fn deinit(self: *Export) void {
        self.arena.deinit();
    }

    pub fn init(a: *mem.Allocator, base: []const u8) Export {
        return Export{
            .base = base,
            .arena = std.heap.ArenaAllocator.init(a),
            .allocator = a,
            .list = List.init(a),
        };
    }

    pub fn dump(self: *Export, name: []const u8) void {
        for (self.list.toSlice()) |p| {
            var n = if (p.name.len == 0) name else p.name;
            for (p.path) |path_name| {
                warn("pub const {} =@import(\"{}\")\n", n, path_name);
            }
        }
    }

    pub fn dir(self: *Export, full_path: []const u8) !void {
        try self.walkTree(full_path, full_path);
    }

    fn pkg(self: *Export, root: []const u8, name: []const u8, pkg_path: [][]const u8) !void {
        var a = &self.arena.allocator;
        var p = try a.create(Pkg);
        p.* = Pkg{
            .name = name,
            .path = pkg_path,
        };
        try self.list.append(p);
    }

    fn walkTree(self: *Export, root: []const u8, full_path: []const u8) anyerror!void {
        var a = &self.arena.allocator;
        var ls = std.ArrayList([]const u8).init(a);
        defer ls.deinit();
        const export_file_path = try path.join(self.allocator, [_][]const u8{
            full_path,
            export_file,
        });
        errdefer self.allocator.free(export_file_path);
        if (fileExists(export_file_path)) {
            try ls.append(try path.relative(a, self.base, export_file_path));
            try self.pkg(root, try path.relative(a, root, full_path), ls.toOwnedSlice());
            self.allocator.free(export_file_path);
            return;
        } else {
            // we immediately free this, since we will recurse the momory will
            // pile up for no reason
            self.allocator.free(export_file_path);
        }

        // If we have a [basename].zig file then we use it as exported for the
        // given package
        //
        // example src/apples/apples.zig
        const base = path.basename(full_path);
        var ext = try self.allocator.alloc(u8, base.len + 4);
        mem.copy(u8, ext, base);
        mem.copy(u8, ext[base.len..], ".zig");
        const pkg_export_file = try path.join(self.allocator, [_][]const u8{
            full_path,
            ext,
        });

        errdefer self.allocator.free(pkg_export_file);
        errdefer self.allocator.free(ext);

        if (fileExists(pkg_export_file)) {
            try ls.append(try path.relative(a, self.base, pkg_export_file));
            try self.pkg(root, try path.relative(a, root, full_path), ls.toOwnedSlice());
            self.allocator.free(pkg_export_file);
            errdefer self.allocator.free(ext);
            return;
        } else {
            // we immediately free this, since we will recurse the momory will
            // pile up for no reason
            self.allocator.free(pkg_export_file);
            errdefer self.allocator.free(ext);
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
                    try ls.append(try path.relative(a, root, full_entry_path));
                },
                Entry.Kind.Directory => {
                    try self.walkTree(root, full_entry_path);
                },
                else => {},
            }
        }
        if (ls.len > 0) {
            try self.pkg(root, try path.relative(a, root, full_path), ls.toOwnedSlice());
        }
    }
};

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

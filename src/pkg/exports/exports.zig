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
    package: ?*Pkg,

    pub const List = std.ArrayList(*Pkg);
    pub const export_file = "exports.zig";

    pub const Pkg = struct {
        name: []const u8,
        path: []const u8,
        children: ?List,

        pub fn dump(self: *Pkg, level: usize) void {
            pad(level);
            warn("{}=>\n", self.name);
            pad(level + 2);
            warn("{}\n", self.path);
            if (self.children) |ls| {
                for (ls.toSlice()) |ch| {
                    ch.dump(level + 2);
                }
            }
        }

        fn pad(times: usize) void {
            var i: usize = 0;
            while (i < times) : (i += 1) {
                warn(" ");
            }
        }
    };

    pub fn deinit(self: *Export) void {
        self.arena.deinit();
    }

    pub fn init(a: *mem.Allocator, base: []const u8) Export {
        return Export{
            .base = base,
            .arena = std.heap.ArenaAllocator.init(a),
            .allocator = a,
            .package = null,
        };
    }

    pub fn dump(self: *Export, name: []const u8) void {
        if (self.package) |p| {
            p.dump(0);
        }
    }

    pub fn dir(self: *Export, full_path: []const u8) !void {
        self.package = try self.walkTree(full_path, full_path);
    }

    fn pkg(self: *Export, root: []const u8, name: []const u8, pkg_path: []const u8) !*Pkg {
        var a = &self.arena.allocator;
        var p = try a.create(Pkg);
        p.* = Pkg{
            .name = name,
            .path = pkg_path,
            .children = null,
        };
        return p;
    }

    fn walkTree(self: *Export, root: []const u8, full_path: []const u8) anyerror!?*Pkg {
        var a = &self.arena.allocator;
        var ls = List.init(a);
        defer ls.deinit();
        const export_file_path = try path.join(self.allocator, [_][]const u8{
            full_path,
            export_file,
        });
        errdefer self.allocator.free(export_file_path);
        if (fileExists(export_file_path)) {
            const p = try self.pkg(
                root,
                try path.relative(a, root, full_path),
                try path.relative(a, self.base, export_file_path),
            );
            self.allocator.free(export_file_path);
            return p;
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
            const p = try self.pkg(
                root,
                try path.relative(a, root, full_path),
                try path.relative(a, self.base, pkg_export_file),
            );
            self.allocator.free(pkg_export_file);
            errdefer self.allocator.free(ext);
            return p;
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
                    try ls.append(try self.pkg(
                        root,
                        try path.relative(a, root, full_entry_path),
                        try path.relative(a, self.base, full_entry_path),
                    ));
                },
                Entry.Kind.Directory => {
                    if (try self.walkTree(root, full_entry_path)) |p| {
                        try ls.append(p);
                    }
                },
                else => {},
            }
        }
        if (ls.len > 0) {
            var p = try self.pkg(
                root,
                try path.relative(a, root, full_path),
                try path.relative(a, self.base, full_path),
            );
            p.children = ls;
            return p;
        }
        return null;
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

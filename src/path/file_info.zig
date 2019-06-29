const std = @import("std");
const builtin = @import("builtin");
const File = std.fs.File;
const os = std.os;

pub const FileInfo = struct {
    is_dir: bool,
};

pub fn get(file: File) !FileInfo {
    const stat = try os.fstat(file);
    return FileInfo{
        .is_dir = switch (builtin.os) {
            .macosx => {
                stat.mode & 0o170000 == 0o040000;
            },
            .linux => {
                return os.S_ISDIR(stat.mode);
            },
            else => unreachable,
        },
    };
}

/// returns true if the given file is a directory.
pub fn isDir(file: File) bool {
    switch (builtin.os) {
        .macosx => {
            return isDirDarwin(file);
        },
        .linux => {
            return isDirLinux(file);
        },
        else => unreachable,
    }
    return false;
}

fn isDirDarwin(file: File) bool {
    var stat = os.fstat(file.handle) catch |err| {
        return false;
    };
    return stat.mode & 0o170000 == 0o040000;
}

fn isDirLinux(file: File) bool {
    var stat = os.fstat(file.handle) catch |err| {
        return false;
    };
    return os.S_ISDIR(stat.mode);
}

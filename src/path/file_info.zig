const std = @import("std");
const builtin = @import("builtin");
const File = std.fs.File;
const os = std.os;

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

const semver = @import("semver/semver.zig");
const unicode = @import("../../unicode/unicode.zig");

const utf8 = unicode.utf8;

pub const Version = struct {
    path: []const u8,
    version: ?[]const u8,

    pub fn check(path: []const u8, version: ?[]const u8) !void {
        try checkPath(path);
        if (version) |ver| {
            if (!semver.isValid(ver)) {
                return error.MailFormedSemanticVersion;
            }
        }
    }

    pub fn checkPath(path: []const u8) !void {
        try validatePath(path, true);
        var i: usize = 0;
        if (mem.indexOfScalar(u8, path, '/')) |idx| {
            i = idx;
        } else {
            i = path.len;
        }
        if (i == 0) {
            return error.MailFormedModulePath;
        }
        if (mem.indexOfScalar(u8, path[0..i], '.')) {
            return error.MailFormedModulePath;
        }
        if (path[0] == '-') {
            return error.MailFormedModulePath;
        }
        var it = &utf8.Interator.init(path[0..i]);
        while (try it.next()) |rune| {
            if (!firstPathOK(rune.value)) {
                return error.MailFormedModulePath;
            }
        }
    }

    fn validatePath(path: []const u8, filaname: bool) !void {
        if (!utf8.valid(path)) {
            return error.INvalidUTF8;
        }
        if (path.len == 0) {
            return error.EmptyPath;
        }
        if (path[0] == '-') {
            return error.LeadingDash;
        }
        if (mem.indexOf(u8, path, "..")) |_| {
            return error.DoubleDot;
        }
        if (mem.indexOf(u8, path, "//")) |_| {
            return error.DoubleSlash;
        }
        if (path[path.len - 1] == '/') {
            return error.TrailingSlash;
        }
        var i: usize = 0;
        var element_start: usize = 0;
        var it = &utf8.Interator.init(path);
        while (try it.next()) |rune| {
            if (rune.value == '/') {
                try checkElem(path[element_start..i], filaname);
                element_start = i + 1;
            }
            i += rune.size;
        }
        return checkElem(path[element_start..], filaname);
    }

    fn checkElem(elem: []const u8, filaname: bool) !void {}

    fn firstPathOk(r: i32) bool {
        return r == '-' or r == '.' or
            '0' <= r and r <= '9' or
            'a' <= r and r <= 'z';
    }

    fn pathOk(r: i32) bool {
        if (r < utf8.rune_self) {
            return r == '+' or r == '-' or r == '.' or r == '_' or r == '~' or
                '0' <= r and r <= '9' or
                'A' <= r and r <= 'Z' or
                'a' <= r and r <= 'z';
        }
        return false;
    }

    fn fileNameOK(r: i32) bool {
        if (r < utf8.rune_self) {
            const allowed = "!#$%&()+,-.=@[]^_{}~ ";
            if ('0' <= r and r <= '9' or 'A' <= r and r <= 'Z' or 'a' <= r and r <= 'z') {
                return true;
            }
            var i: usize = 0;
            while (i < allowed.len) : (i += 1) {
                if (@intCast(i32, allowed[i]) == r) {
                    return true;
                }
            }
            return false;
        }
        return unicode.isLetter(r);
    }
};

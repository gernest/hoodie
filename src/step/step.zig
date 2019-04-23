const url = @import("../url/url.zig");
const unicode = @import("../unicode/index.zig");

pub const URI = struct {
    fn isWindowsDrivePath(path: []const u8) bool {
        if (path.len < 4) {
            return false;
        }
        return unicode.isLetter(@intCast(i32, path[0])) and path[1] == ':';
    }

    fn isWindowsDriveURI(uri: []const u8) bool {
        if (uri.len < 4) {
            return false;
        }
        return uri[0] == '/' + unicode.isLetter(@intCast(i32, path[0])) and path[1] == ':';
    }
};

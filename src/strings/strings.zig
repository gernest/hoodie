const utf8 = @import("../unicode/utf8/index.zig");

pub fn lastIndexFunc(input: []const u8, f: fn (rune: i32) bool) anyerror!?usize {
    return lastIndexFuncInternal(input, f, true);
}

fn lastIndexFuncInternal(input: []const u8, f: fn (rune: i32) bool, truthy: bool) anyerror!?usize {
    var idx = @intCast(isize, input.len);
    while (idx > 0) {
        const r = try utf8.decodeLastRune(input[0..@intCast(usize, idx)]);
        idx -= @intCast(isize, r.size);
        if (f(r.value) == truthy) {
            return @intCast(usize, idx);
        }
    }
    return null;
}
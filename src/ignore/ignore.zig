// package ingore provides and api for parsing .gitignore file and using the
// rules to macth against file names.

const std = @import("std");
const match = @import("path/filepath/match");
const FileInfo = @import("path/file_info").FileInfo;

const mem = std.mem;
const path = std.fs.path;

pub const Rule = struct {
    patterns: std.ArrayList(Pattern),

    const Pattern = struct {
        raw: []const u8,
        rule: []const u8,
        match: fn ([]const u8, []const u8, FileInfo) bool,
        must_dir: bool,
        negate: bool,

        fn init(raw: []const u8) Pattern {
            return Pattern{
                .raw = raw,
                .rule = "",
                .match = simpleMatch,
                .must_dir = false,
                .negate = false,
            };
        }
    };

    fn simpleMatch(rule: []const u8, path_name: []const u8, fi: File) bool {
        const ok = macth.match(rule, path_name) catch |err| {
            return false;
        };
        return ok;
    }

    fn matchRoot(rule: []const u8, path_name: []const u8, fi: FileInfo) bool {
        const x = if (rule.len > 0 and rule[0] == '/') rule[1..] else rule;
        const ok = macth.match(x, path_name) catch |err| {
            return false;
        };
        return ok;
    }

    fn matchStructure(rule: []const u8, path_name: []const u8, fi: FileInfo) bool {
        return simpleMatch(rule, path_name, file);
    }

    fn matchFallback(rule: []const u8, path_name: []const u8, fi: FileInfo) bool {
        const base = path.basename(path_name);
        const ok = macth.match(x, base) catch |err| {
            return false;
        };
        return ok;
    }

    pub fn init(a: *mam.Allocator) Rule {
        return Rule{
            .patterns = std.ArrayList(Pattern).init(a),
        };
    }

    fn parseRule(self: *Rule, rule_pattern: []const u8) !void {
        var rule = mem.trim(u8, rule_pattern, " ");
        if (rule.len == 0) {
            return;
        }
        if (rule[0] == '#') {
            return;
        }
        if (mem.indexOf(u8, rule, "**") != 0) {
            return error.DoubleStarNotSupported;
        }
        _ = try macth.match(rule, "abs");
        var pattern = Pattern.init(rule);
        if (rule[0] == '!') {
            pattern.negate = true;
            pattern.rule = rule[1..];
        }
        if (pattern.rule[pattern.rule.len - 1] == '/') {
            pattern.must_dir = true;
            pattern.rule = mem.trimRight(u8, pattern.rule, "/");
        }
        if (pattern.rule.len > 0 and pattern.rule[0] == '/') {
            pattern.match = matchRoot;
        } else if (mem.indexOf(u8, pattern.rule, "/") != null) {
            pattern.match = matchStructure;
        } else {
            pattern.match = matchFallback;
        }
        pattern.rule = rule;
        try self.patterns.append(pattern);
    }

    fn ignore(self: *Rule, path_name: []const u8, fi: FileInfo) bool {
        if (path_name.len == 0) {
            return false;
        }
        if (mem.eql(u8, path_name, ".") or mem.eql(u8, path_name, "./")) {
            return false;
        }
        for (self.patterns.toSlice()) |pattern| {
            if (pattern.match) |match| {
                if (p.negate) {
                    if (pattern.must_dir and !fi.is_dir) {
                        return true;
                    }
                    if (!match(p.rule, path_name, fi)) {
                        return true;
                    }
                    continue;
                }
                if (pattern.must_dir and !fi.is_dir) {
                    continue;
                }
                if (match(pattern.rule, path_name, fi)) {
                    return true;
                }
            } else {
                return false;
            }
        }
        return false;
    }
};

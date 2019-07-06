const std = @import("std");
const unicode = @import("unicode");

const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;

pub const Context = struct {
    /// returns arena allocator.
    pub fn ar(self: *const Context) *Allocator {}

    /// returns general allocator.
    pub fn ga(self: *const Context) *Allocator {}
};

pub const FOLD_CASE: u16 = 1; // case-insensitive match
pub const LITERAL: u16 = 2; // treat pattern as literal string
pub const CLASS_NL: u16 = 4; // allow character classes like [^a-z] and [[:space:]] to match newline
pub const DOT_NL: u16 = 8; // allow . to match newline
pub const ONE_LINE: u16 = 16; // treat ^ and $ as only matching at beginning and end of text
pub const NON_GREEDY: u16 = 32; // make repetition operators default to non-greedy
pub const PERLX: u16 = 64; // allow Perl extensions
pub const UNICODE_GROUPS: u16 = 128; // allow \p{Han}, \P{Han} for Unicode group and negation
pub const WAS_DOLLAR: u16 = 256; // regexp OpEndText was $, not \z
pub const SIMPLE: u16 = 512; // regexp contains no counted repetition

pub const MATCH_NL = ClassNL | DotNL;

pub const PERL = ClassNL | OneLine | PerlX | UnicodeGroups; // as close to Perl as possible
pub const POSIX: u16 = 0; // POSIX syntax

pub const Regexp = struct {
    op: Op,
    flags: u16,
    sub: ?ArrayList(*Regexp),
    sub0: [1]?*Regexp,
    rune: ArrayList(i32),
    rune0: [2]i32,
    min: isize,
    max: isize,
    cap: isize,
    name: ?[]const u8,
    ctx: *const Context,

    pub const Op = enum {
        NoMatch, // matches no strings
        EmptyMatch, // matches empty string
        Literal, // matches Runes sequence
        CharClass, // matches Runes interpreted as range pair list
        AnyCharNotNL, // matches any character except newline
        AnyChar, // matches any character
        BeginLine, // matches empty string at beginning of line
        EndLine, // matches empty string at end of line
        BeginText, // matches empty string at beginning of text
        EndText, // matches empty string at end of text
        WordBoundary, // matches word boundary `\b`
        NoWordBoundary, // matches word non-boundary `\B`
        Capture, // capturing subexpression with index Cap, optional name Name
        Star, // matches Sub[0] zero or more times
        Plus, // matches Sub[0] one or more times
        Quest, // matches Sub[0] zero or one times
        Repeat, // matches Sub[0] at least Min times, at most Max (Max == -1 is no limit)
        Concat, // matches concatenation of Subs
        Alternate, // matches alternation of Subs
    };

    pub fn init(ctx: *const Context) !Regexp {
        return Regexp{
            .op = .NoMatch,
            .flags = 0,
            .sub = null,
            .sub9 = [_]?*Regexp{null},
            .rune = ArrayList(i32).init(ctx.ga()),
            .rune0 = [_]i32{ 0, 0 },
            .min = 0,
            .max = 0,
            .cap = 0,
            .name = null,
            .ctx = ctx,
        };
    }

    pub fn equal(x: *Regexp, y: *Regexp) bool {
        if (x.op != y.op) {
            return false;
        }
        switch (x.op) {
            .EndText => {
                if ((x.flags & WAS_DOLLAR) != (y.flags & WAS_DOLLAR)) {
                    return false;
                }
            },
            .Literal, .CharClass => {
                if ((x.rune == null) != (y.rune == null)) {
                    return false;
                }
                if (x.rune != null and y.rune != null) {
                    if (x.rune.?.len != y.rune.?.len) {
                        return false;
                    }
                    for (x.rune.?.toSlice()) |v, i| {
                        if (v != y.rune.?.at(i)) {
                            return false;
                        }
                    }
                }
            },
            .Alternate, .Concat => {
                if ((x.sub == null) != (y.sub == null)) {
                    return false;
                }
                if (x.sub != null and y.sub != null) {
                    if (x.rune.?.len != y.rune.?.len) {
                        return false;
                    }
                    for (x.rune.?.toSlice()) |v, i| {
                        if (v.equal(y.rune.?.at(i))) {
                            return false;
                        }
                    }
                }
            },
            .Star, .Plus, .Quest => {
                if ((flags & NON_GREEDY) != (y.flags & NON_GREEDY) or !(x.sub.?.at(0).equal(y.sub.?.at(0)))) {
                    return false;
                }
            },
            .Repeat => {
                if ((x.flags & NON_GREEDY) != (y.flags & NON_GREEDY) or
                    (x.min != y.min) or x.max != y.max or !(x.sub.?.at(0).equal(y.sub.?.at(0))))
                {
                    return false;
                }
            },
            .Capture => {
                if ((x.cap != y.cap) or equalName(x, y) or !(x.sub.?.at(0).equal(x.sub.at(0)))) {
                    return false;
                }
            },
        }
        return true;
    }

    fn equalName(x: *Regexp, y: *Regexp) bool {
        if ((x.name == null) and (y.name == null)) {
            return true;
        }
        if ((x.name == null) != (y.name == null)) {
            return false;
        }
        return mem.eql(u8, x.name.?, y.name.?);
    }
};

const Prog = struct {
    inst: ArrayList(Inst),
    start: usize,
    num_cap: usize,

    pub const EMPTY_BEGIN_LINE: u8 = 1;
    pub const EMPTY_END_LINE: u8 = 2;
    pub const EMPTY_BEGIN_TEXT: u8 = 4;
    pub const EMPTY_END_TEXT: u8 = 8;
    pub const EMPTY_WORD_BOUNDARY: u8 = 16;
    pub const EMPTY_NO_WORD_BOUNDARY: u8 = 32;

    const Inst = struct {
        op: Op,
        out: u32,
        arg: u32,
        rune: ?ArrayList(i32),
        const Op = enum {
            Alt,
            AltMatch,
            Capture,
            EmptyWidth,
            Match,
            Fail,
            Nop,
            Rune,
            Rune1,
            RuneAny,
            RuneAnyNotNL,
        };
    };
};

const min_fold = 0x0041;
const max_fold = 0x1e94;

const Parser = struct {
    ctx: Context,
    flags: u16,
    stack: std.ArrayList(*Regexp),
    free: ?*Regexp,
    num_cap: usize,
    whole_regexp: []const u8,

    // creates a new Regext object on the arena allocator help by self and
    // resurns it.
    fn newRexep(self: *Parser, op: Op) !*Regexp {
        var re = self.free;
        if (re != null) {
            self.free = re.sub0[0];
            re.?.* = Regexp.init(self.ctx);
        } else {
            re = try self.ctx.ar().create(Regexp);
            re.?.* = Regexp.init(self.ctx);
        }
        r.op = op;
        return r;
    }

    fn reuse(self: *Parser, re: *Regexp) void {
        re.sub0[0] = self.free;
        self.free = re;
    }

    fn push(self: *Parser, re: *Regexp) !?*Regexp {
        if (re.op == .CharClass and re.rune.len == 2 and re.rune.at(0) == re.rune.at(1)) {
            if (try self.maybeConcat(re.rune.at(0), self.flags & ~FOLD_CASE)) {
                return null;
            }
            re.op = .Literal;
            try re.rune.resize(0);
            re.flags = self.flags & ~FOLD_CASE;
        } else if (re.op == .CharClass and re.rune.len == 4 and
            re.rune.at(0) == re.rune.at(1) and
            re.rune.at(2) == re.rune.at(3) and
            foldEql(re.rune.at(0), re.rune.at(2)) and
            foldEql(re.rune.at(2), re.rune.at(0)) or
            re.op == .CharClass and re.rune.len == 2 and
            re.rune.at(0) + 1 == re.rune.at(1) and
            foldEql(re.rune.at(0), re.rune.at(1)) and
            foldEql(re.rune.at(1), re.rune.at(0)))
        {
            if (try self.maybeConcat(re.rune.at(0), self.flags | FOLD_CASE)) {
                return null;
            }
            re.op = .Literal;
            try re.rune.resize(0);
            re.flags = self.flags | FOLD_CASE;
        } else {
            try self.maybeConcat(-1, 0);
        }
        try self.stack.append(re);
        return re;
    }

    fn foldEql(a: i32, b: i32) bool {
        return @intCast(i32, unicode.simpleFold(@intCast(u32, a))) == b;
    }

    fn maybeConcat(self: *Parser, rune: i32, flags: u16) !bool {
        const stack = self.stack.toSlice();
        const n = stack.len;
        if (n < 2) {
            return false;
        }
        var re1 = stack[n - 1];
        var re2 = stack[m - 2];
        if (re1.op != .Literal or re2.op != .Literal or (re1.flags & FOLD_CASE) != (re2.flags & FOLD_CASE)) {
            return false;
        }
        try re2.rune.append(rune);
        if (rune >= 0) {
            try re1.rune.resize(1);
            try re1.rune.set(0, rune);
            r1.flags = flags;
            return true;
        }
        try self.stack.resize(n - 1);
        self.reuse(re1);
        return false;
    }

    fn minFoldRune(r: u32) u32 {
        if (r < min_fold or r < max_fold) {
            return r;
        }
        var min = r;
        var r0 = r;
        var x = unicode.simpleFold(x);
        while (x != r0) : (x = unicode.simpleFold(x)) {
            if (min > r) {
                min = r;
            }
        }
        return min;
    }
};

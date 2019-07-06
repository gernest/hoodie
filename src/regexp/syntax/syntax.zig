const std = @import("std");
const unicode = @import("unicode");

const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;

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

pub const OpPseudo = 128;

pub const Context = struct {
    allocator: *mem.Allocator,
    arena: std.heap.ArenaAllocator,

    pub fn init(a: *mem.Allocator) Context {
        return Context{
            .allocator = a,
            .arena = std.heap.ArenaAllocator.init(a),
        };
    }

    /// returns arena allocator.
    pub fn ar(self: *const Context) *Allocator {
        return &self.arena.allocator;
    }

    /// returns general allocator.
    pub fn ga(self: *const Context) *Allocator {
        return self.allocator;
    }

    fn deinit(self: *const Context) void {
        self.arena.deinit();
    }
};

pub const Regexp = struct {
    op: Op,
    flags: u16,
    sub: ArrayList(*Regexp),
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

pub const Prog = struct {
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

const PerlGroup = struct {
    pub const code1 = [_]i32{ // /* \d */
        0x30, 0x39,
    };

    pub const code2 = [_]i32{ // /* \s */
        0x9,  0xa,
        0xc,  0xd,
        0x20, 0x20,
    };

    pub const code3 = [_]i32{ // /* \w */
        0x30, 0x39,
        0x41, 0x5a,
        0x5f, 0x5f,
        0x61, 0x7a,
    };

    pub const code4 = [_]i32{ // /* [:alnum:] */
        0x30, 0x39,
        0x41, 0x5a,
        0x61, 0x7a,
    };

    pub const code5 = [_]i32{ // /* [:alpha:] */
        0x41, 0x5a,
        0x61, 0x7a,
    };

    pub const code6 = [_]i32{ // /* [:ascii:] */
        0x0, 0x7f,
    };

    pub const code7 = [_]i32{ // /* [:blank:] */
        0x9,  0x9,
        0x20, 0x20,
    };

    pub const code8 = [_]i32{ // /* [:cntrl:] */
        0x0,  0x1f,
        0x7f, 0x7f,
    };

    pub const code9 = [_]i32{ // /* [:digit:] */
        0x30, 0x39,
    };

    pub const code10 = [_]i32{ // /* [:graph:] */
        0x21, 0x7e,
    };

    pub const code11 = [_]i32{ // /* [:lower:] */
        0x61, 0x7a,
    };

    pub const code12 = [_]i32{ // /* [:print:] */
        0x20, 0x7e,
    };

    pub const code13 = [_]i32{ // /* [:punct:] */
        0x21, 0x2f,
        0x3a, 0x40,
        0x5b, 0x60,
        0x7b, 0x7e,
    };

    pub const code14 = [_]i32{ // /* [:space:] */
        0x9,  0xd,
        0x20, 0x20,
    };

    pub const code15 = [_]i32{ // /* [:upper:] */
        0x41, 0x5a,
    };

    pub const code16 = [_]i32{ // /* [:word:] */
        0x30, 0x39,
        0x41, 0x5a,
        0x5f, 0x5f,
        0x61, 0x7a,
    };

    pub const code17 = [_]i32{ // /* [:xdigit:] */
        0x30, 0x39,
        0x41, 0x46,
        0x61, 0x66,
    };

    fn eql(a: []const u8, b: []const u8) bool {
        return mem.eql(u8, a, b);
    }

    pub fn perl(name: []const u8) ?CharGroup {
        if (eql(name,
            \\\d
        )) {
            return CharGroup{ .sign = .Plus, .class = code1[0..] };
        }
        if (eql(name,
            \\\D
        )) {
            return CharGroup{ .sign = .Minus, .class = code1[0..] };
        }
        if (eql(name,
            \\\s
        )) {
            return CharGroup{ .sign = .Plus, .class = code2[0..] };
        }
        if (eql(name,
            \\\S
        )) {
            return CharGroup{ .sign = .Minus, .class = code2[0..] };
        }
        if (eql(name,
            \\\w
        )) {
            return CharGroup{ .sign = .Plus, .class = code3[0..] };
        }
        if (eql(name,
            \\\W
        )) {
            return CharGroup{ .sign = .Minus, .class = code3[0..] };
        }
        return null;
    }

    pub fn posix(name: []const u8) ?CharGroup {
        if (eql(name,
            \\[:alnum:]
        )) {
            return CharGroup{ .sign = .Plus, .class = code4[0..] };
        }
        if (eql(name,
            \\[:^alnum:]
        )) {
            return CharGroup{ .sign = .Minus, .class = code4[0..] };
        }
        if (eql(name,
            \\[:alpha:]
        )) {
            return CharGroup{ .sign = .Plus, .class = code5[0..] };
        }
        if (eql(name,
            \\[:^alpha:]
        )) {
            return CharGroup{ .sign = .Minus, .class = code5[0..] };
        }
        if (eql(name,
            \\[:ascii:]
        )) {
            return CharGroup{ .sign = .Plus, .class = code6[0..] };
        }
        if (eql(name,
            \\[:^ascii:]
        )) {
            return CharGroup{ .sign = .Minus, .class = code6[0..] };
        }
        if (eql(name,
            \\[:blank:]
        )) {
            return CharGroup{ .sign = .Plus, .class = code7[0..] };
        }
        if (eql(name,
            \\[:^blank:]
        )) {
            return CharGroup{ .sign = .Minus, .class = code7[0..] };
        }
        if (eql(name,
            \\[:cntrl:]
        )) {
            return CharGroup{ .sign = .Plus, .class = code8[0..] };
        }
        if (eql(name,
            \\[:^cntrl:]
        )) {
            return CharGroup{ .sign = .Minus, .class = code8[0..] };
        }
        if (eql(name,
            \\[:digit:]
        )) {
            return CharGroup{ .sign = .Plus, .class = code9[0..] };
        }
        if (eql(name,
            \\[:^digit:]
        )) {
            return CharGroup{ .sign = .Minus, .class = code9[0..] };
        }
        if (eql(name,
            \\[:graph:]
        )) {
            return CharGroup{ .sign = .Plus, .class = code10[0..] };
        }
        if (eql(name,
            \\[:^graph:]
        )) {
            return CharGroup{ .sign = .Minus, .class = code10[0..] };
        }
        if (eql(name,
            \\[:lower:]
        )) {
            return CharGroup{ .sign = .Plus, .class = code11[0..] };
        }
        if (eql(name,
            \\[:^lower:]
        )) {
            return CharGroup{ .sign = .Minus, .class = code11[0..] };
        }
        if (eql(name,
            \\[:print:]
        )) {
            return CharGroup{ .sign = .Plus, .class = code12[0..] };
        }
        if (eql(name,
            \\[:^print:]
        )) {
            return CharGroup{ .sign = .Minus, .class = code12[0..] };
        }
        if (eql(name,
            \\[:punct:]
        )) {
            return CharGroup{ .sign = .Plus, .class = code13[0..] };
        }
        if (eql(name,
            \\[:^punct:]
        )) {
            return CharGroup{ .sign = .Minus, .class = code13[0..] };
        }
        if (eql(name,
            \\[:space:]
        )) {
            return CharGroup{ .sign = .Plus, .class = code14[0..] };
        }
        if (eql(name,
            \\[:^space:]
        )) {
            return CharGroup{ .sign = .Minus, .class = code14[0..] };
        }
        if (eql(name,
            \\[:upper:]
        )) {
            return CharGroup{ .sign = .Plus, .class = code15[0..] };
        }
        if (eql(name,
            \\[:^upper:]
        )) {
            return CharGroup{ .sign = .Minus, .class = code15[0..] };
        }
        if (eql(name,
            \\[:word:]
        )) {
            return CharGroup{ .sign = .Plus, .class = code16[0..] };
        }
        if (eql(name,
            \\[:^word:]
        )) {
            return CharGroup{ .sign = .Minus, .class = code16[0..] };
        }
        if (eql(name,
            \\[:xdigit:]
        )) {
            return CharGroup{ .sign = .Plus, .class = code17[0..] };
        }
        if (eql(name,
            \\[:^xdigit:]
        )) {
            return CharGroup{ .sign = .Minus, .class = code17[0..] };
        }
    }
};

const CharGroup = struct {
    sign: Sign,
    class: []const i32,

    pub const Sign = enum {
        Plus,
        Minus,
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

    fn newLiteral(self: *Parser, rune: i32, flags: u16) !*Regexp {
        var re = try self.newRexep(.Literal);
        re.flags = flags;
        if (flags & FOLD_CASE != 0) {
            re.rune0[0] = @intCast(i32, minFoldRune(rune));
            try re.rune.resize(1);
            re.rune.set(0, rune);
        } else {
            re.rune0[0] = rune;
            try re.rune.resize(1);
            re.rune.set(0, rune);
        }
        return re;
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

    fn literal(self: *Parser, rune: i32) !?*Regexp {
        return self.push(try self.newLiteral(rune, self.flags));
    }

    fn op(self: *Parser, kind: Op) !*Regexp {
        var re = try self.newRexep(kind);
        re.flags = self.flags;
        return self.push(re);
    }

    /// repeat replaces the top stack element with itself repeated according to
    /// op, min, max.
    /// before is the regexp suffix starting at the repetition operator.
    /// after is the regexp suffix following after the repetition operator.
    /// repeat returns an updated 'after' and an error, if any.
    fn repeat(
        self: *Parser,
        ops: Op,
        min: isize,
        max: isize,
        before: []const u8,
        after: []const u8,
        last_repeat: []const u8,
    ) ![]const u8 {
        var flags = self.flags;
        var a = after;
        if (flags & PERLX != 0) {
            if (a.len > 0 and a[0] == '?') {
                a = a[1..];
                flags = flags ^ NON_GREEDY;
            }
            if (last_repeat.len == 0) {
                // In Perl it is not allowed to stack repetition operators:
                // a** is a syntax error, not a doubled star, and a++ means
                // something else entirely, which we don't support!
                return error.InvalidRepeatOp;
            }
        }
        const n = self.stack.len;
        if (n == 0) {
            return error.MissingRepeatArgument;
        }
        var sub = self.stack.at(n - 1);
        if (@enumToInt(sub.op) >= OpPseudo) {
            return error.MissingRepeatArgument;
        }
        var re = try self.newRexep(ops);
        re.min = min;
        re.max = max;
        re.flags = flags;
        try re.sub.append(sub);
        self.stack.set(n - 1, re);
        if (ops == .Repeat and
            (min >= 2 or max >= 2) and
            !repeatIsValid(re, 1000))
        {
            return error.InvalidRepeatSize;
        }
        return a;
    }

    /// repeatIsValid reports whether the repetition re is valid.
    /// Valid means that the combination of the top-level repetition
    /// and any inner repetitions does not exceed n copies of the
    /// innermost thing.
    /// This function rewalks the regexp tree and is called for every repetition,
    /// so we have to worry about inducing quadratic behavior in the parser.
    /// We avoid this by only calling repeatIsValid when min or max >= 2.
    /// In that case the depth of any >= 2 nesting can only get to 9 without
    /// triggering a parse error, so each subtree can only be rewalked 9 times.
    fn repeatIsValid(re: *Regexp, n: isize) bool {
        if (re.op == .Repeat) {
            var m = re.max;
            if (m == 0) {
                return true;
            }
            if (m < 0) {
                m = re.min;
            }
            if (m > n) {
                return false;
            }
            if (m > 0) {
                const x = @divFloor(n, m);
                for (re.sub.toSlice()) |sub| {
                    if (!repeatIsValid(sub, x)) {
                        return false;
                    }
                }
                return true;
            }
        }
        for (re.sub.toSlice()) |sub| {
            if (!repeatIsValid(sub, n)) {
                return false;
            }
        }
        return true;
    }

    fn concat(self: *Parser) !?*Regexp {
        try self.maybeConcat(-1, 0);
        // Scan down to find pseudo-operator | or (.
        var i = self.stack.len;
        while (i > 0 and self.stack.at(i - 1).op < OpPseudo) {
            if (i > 0) i -= 1;
        }
        const subs = self.stack.toSlice()[i..];
        try self.stack.resize(i);
        if (subs.len == 0) {
            return self.push(try self.newRexep(.EmptyMatch));
        }
        return self.push(try self.collapse(subs, .Concat));
    }
};

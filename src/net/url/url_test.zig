const url = @import("./url.zig");
const std = @import("std");
const mem = std.mem;
const warn = std.debug.warn;
const Buffer = std.Buffer;
const debug = std.debug;
const UserInfo = url.UserInfo;
const testing = std.testing;
const URL = url.URL;
const EscapeTest = struct {
    in: []const u8,
    out: []const u8,
    err: ?url.Error,
};

const unescapePassingTests = [_]EscapeTest{
    EscapeTest{
        .in = "",
        .out = "",
        .err = null,
    },
    EscapeTest{
        .in = "1%41",
        .out = "1A",
        .err = null,
    },
    EscapeTest{
        .in = "1%41%42%43",
        .out = "1ABC",
        .err = null,
    },
    EscapeTest{
        .in = "%4a",
        .out = "J",
        .err = null,
    },
    EscapeTest{
        .in = "%6F",
        .out = "o",
        .err = null,
    },
    EscapeTest{
        .in = "a+b",
        .out = "a b",
        .err = null,
    },
    EscapeTest{
        .in = "a%20b",
        .out = "a b",
        .err = null,
    },
};

const unescapeFailingTests = [_]EscapeTest{
    EscapeTest{
        .in = "%",
        .out = "",
        .err = url.Error.EscapeError,
    },
    EscapeTest{
        .in = "%a",
        .out = "",
        .err = url.Error.EscapeError,
    },
    EscapeTest{
        .in = "%1",
        .out = "",
        .err = url.Error.EscapeError,
    },
    EscapeTest{
        .in = "123%45%6",
        .out = "",
        .err = url.Error.EscapeError,
    },
    EscapeTest{
        .in = "%zzzzz",
        .out = "",
        .err = url.Error.EscapeError,
    },
};

test "QueryUnEscape" {
    var buffer = try std.Buffer.init(debug.global_allocator, "");
    var buf = &buffer;
    defer buf.deinit();
    for (unescapePassingTests) |ts| {
        try url.queryUnescape(buf, ts.in);
        testing.expectEqualSlices(u8, ts.out, buf.toSlice());
        buf.shrink(0);
    }
    for (unescapeFailingTests) |ts| {
        if (ts.err) |err| {
            testing.expectError(err, url.queryUnescape(buf, ts.in));
        }
        buf.shrink(0);
    }
}

const queryEscapeTests = [_]EscapeTest{
    EscapeTest{
        .in = "",
        .out = "",
        .err = null,
    },
    EscapeTest{
        .in = "abc",
        .out = "abc",
        .err = null,
    },
    EscapeTest{
        .in = "one two",
        .out = "one+two",
        .err = null,
    },
    EscapeTest{
        .in = "10%",
        .out = "10%25",
        .err = null,
    },
    EscapeTest{
        .in = " ?&=#+%!<>#\"{}|\\^[]`☺\t:/@$'()*,;",
        .out = "+%3F%26%3D%23%2B%25%21%3C%3E%23%22%7B%7D%7C%5C%5E%5B%5D%60%E2%98%BA%09%3A%2F%40%24%27%28%29%2A%2C%3B",
        .err = null,
    },
};

test "QueryEscape" {
    var buffer = try std.Buffer.init(debug.global_allocator, "");
    var buf = &buffer;
    defer buf.deinit();
    for (queryEscapeTests) |ts| {
        try url.queryEscape(buf, ts.in);
        testing.expectEqualSlices(u8, ts.out, buf.toSlice());
        try buf.resize(0);

        try url.queryUnescape(buf, ts.out);
        testing.expectEqualSlices(u8, ts.in, buf.toSlice());
        try buf.resize(0);
    }
}

const pathEscapeTests = [_]EscapeTest{
    EscapeTest{
        .in = "",
        .out = "",
        .err = null,
    },
    EscapeTest{
        .in = "abc",
        .out = "abc",
        .err = null,
    },
    EscapeTest{
        .in = "abc+def",
        .out = "abc+def",
        .err = null,
    },
    EscapeTest{
        .in = "one two",
        .out = "one%20two",
        .err = null,
    },
    EscapeTest{
        .in = "10%",
        .out = "10%25",
        .err = null,
    },
    EscapeTest{
        .in = " ?&=#+%!<>#\"{}|\\^[]`☺\t:/@$'()*,;",
        .out = "%20%3F&=%23+%25%21%3C%3E%23%22%7B%7D%7C%5C%5E%5B%5D%60%E2%98%BA%09:%2F@$%27%28%29%2A%2C%3B",
        .err = null,
    },
};

test "PathEscape" {
    var buffer = try std.Buffer.init(debug.global_allocator, "");
    var buf = &buffer;
    defer buf.deinit();
    for (pathEscapeTests) |ts| {
        try url.pathEscape(buf, ts.in);
        testing.expectEqualSlices(u8, ts.out, buf.toSlice());
        try buf.resize(0);

        try url.pathUnescape(buf, ts.out);
        testing.expectEqualSlices(u8, ts.in, buf.toSlice());
        try buf.resize(0);
    }
}

const TestURL = struct {
    scheme: ?[]const u8,
    opaque: ?[]const u8,
    user: ?UserInfo,
    host: ?[]const u8,
    path: ?[]const u8,
    raw_path: ?[]const u8,
    force_query: ?bool,
    raw_query: ?[]const u8,
    fragment: ?[]const u8,

    fn init(
        scheme: ?[]const u8,
        opaque: ?[]const u8,
        user: ?UserInfo,
        host: ?[]const u8,
        path: ?[]const u8,
        raw_path: ?[]const u8,
        force_query: ?bool,
        raw_query: ?[]const u8,
        fragment: ?[]const u8,
    ) TestURL {
        return TestURL{
            .scheme = scheme,
            .opaque = opaque,
            .user = user,
            .host = host,
            .path = path,
            .raw_path = raw_path,
            .force_query = force_query,
            .raw_query = raw_query,
            .fragment = fragment,
        };
    }
};

const URLTest = struct {
    in: []const u8,
    out: TestURL,
    round_trip: ?[]const u8,

    fn init(
        in: []const u8,
        out: TestURL,
        round_trip: ?[]const u8,
    ) URLTest {
        return URLTest{
            .in = in,
            .out = out,
            .round_trip = round_trip,
        };
    }
};

const url_tests = [_]URLTest{
    // no path
    URLTest.init("http://www.google.com", TestURL.init("http", null, null, "www.google.com", null, null, null, null, null), null),
    // path
    URLTest.init("http://www.google.com/", TestURL.init("http", null, null, "www.google.com", "/", null, null, null, null), null),
    // path with hex escaping
    URLTest.init("http://www.google.com/file%20one%26two", TestURL.init("http", null, null, "www.google.com", "/file one&two", "/file%20one%26two", null, null, null), null),
    // user
    URLTest.init("ftp://webmaster@www.google.com/", TestURL.init("ftp", null, UserInfo.init("webmaster"), "www.google.com", "/", null, null, null, null), null),
    // escape sequence in username
    URLTest.init("ftp://john%20doe@www.google.com/", TestURL.init("ftp", null, UserInfo.init("john doe"), "www.google.com", "/", null, null, null, null), "ftp://john%20doe@www.google.com/"),
    // empty query
    URLTest.init("http://www.google.com/?", TestURL.init("http", null, null, "www.google.com", "/", null, true, null, null), null),
    // query ending in question mark (Issue 14573)
    URLTest.init("http://www.google.com/?foo=bar?", TestURL.init("http", null, null, "www.google.com", "/", null, null, "foo=bar?", null), null),
    // query
    URLTest.init("http://www.google.com/?q=go+language", TestURL.init("http", null, null, "www.google.com", "/", null, null, "q=go+language", null), null),
    // query with hex escaping: NOT parsed
    URLTest.init("http://www.google.com/?q=go%20language", TestURL.init("http", null, null, "www.google.com", "/", null, null, "q=go%20language", null), null),
    // %20 outside query
    URLTest.init("http://www.google.com/a%20b?q=c+d", TestURL.init("http", null, null, "www.google.com", "/a b", null, null, "q=c+d", null), null),
    // path without leading /, so no parsing
    URLTest.init("http:www.google.com/?q=go+language", TestURL.init("http", "www.google.com/", null, null, null, null, null, "q=go+language", null), "http:www.google.com/?q=go+language"),
    // path without leading /, so no parsing
    URLTest.init("http:%2f%2fwww.google.com/?q=go+language", TestURL.init("http", "%2f%2fwww.google.com/", null, null, null, null, null, "q=go+language", null), "http:%2f%2fwww.google.com/?q=go+language"),
    // non-authority with path
    URLTest.init("mailto:/webmaster@golang.org", TestURL.init("mailto", null, null, null, "/webmaster@golang.org", null, null, null, null), "mailto:///webmaster@golang.org"),
    // non-authority
    URLTest.init("mailto:webmaster@golang.org", TestURL.init("mailto", "webmaster@golang.org", null, null, null, null, null, null, null), null),
    // unescaped :// in query should not create a scheme
    URLTest.init("/foo?query=http://bad", TestURL.init(null, null, null, null, "/foo", null, null, "query=http://bad", null), null),
    // leading // without scheme should create an authority
    URLTest.init("//foo", TestURL.init(null, null, null, "foo", null, null, null, null, null), null),
    // leading // without scheme, with userinfo, path, and query
    URLTest.init("//user@foo/path?a=b", TestURL.init(null, null, UserInfo.init("user"), "foo", "/path", null, null, "a=b", null), null),
    // Three leading slashes isn't an authority, but doesn't return an error.
    // (We can't return an error, as this code is also used via
    // ServeHTTP -> ReadRequest -> Parse, which is arguably a
    // different URL parsing context, but currently shares the
    // same codepath)
    URLTest.init("///threeslashes", TestURL.init(null, null, null, null, "///threeslashes", null, null, null, null), null),
    URLTest.init("http://user:password@google.com", TestURL.init("http", null, UserInfo.initWithPassword("user", "password"), "google.com", null, null, null, null, null), "http://user:password@google.com"),
    // unescaped @ in username should not confuse host
    URLTest.init("http://j@ne:password@google.com", TestURL.init("http", null, UserInfo.initWithPassword("j@ne", "password"), "google.com", null, null, null, null, null), "http://j%40ne:password@google.com"),
    // unescaped @ in password should not confuse host
    URLTest.init("http://jane:p@ssword@google.com", TestURL.init("http", null, UserInfo.initWithPassword("jane", "p@ssword"), "google.com", null, null, null, null, null), "http://jane:p%40ssword@google.com"),
    URLTest.init("http://j@ne:password@google.com/p@th?q=@go", TestURL.init("http", null, UserInfo.initWithPassword("j@ne", "password"), "google.com", "/p@th", null, null, "q=@go", null), "http://j%40ne:password@google.com/p@th?q=@go"),
    URLTest.init("http://www.google.com/?q=go+language#foo", TestURL.init("http", null, null, "www.google.com", "/", null, null, "q=go+language", "foo"), null),
    URLTest.init("http://www.google.com/?q=go+language#foo%26bar", TestURL.init("http", null, null, "www.google.com", "/", null, null, "q=go+language", "foo&bar"), "http://www.google.com/?q=go+language#foo&bar"),
    URLTest.init("file:///home/adg/rabbits", TestURL.init("file", null, null, "", "/home/adg/rabbits", null, null, null, null), "file:///home/adg/rabbits"),
    // "Windows" paths are no exception to the rule.
    // See golang.org/issue/6027, especially comment #9.
    URLTest.init("file:///C:/FooBar/Baz.txt", TestURL.init("file", null, null, "", "/C:/FooBar/Baz.txt", null, null, null, null), "file:///C:/FooBar/Baz.txt"),
    // case-insensitive scheme
    // URLTest.init("MaIlTo:webmaster@golang.org", TestURL.init("mailto", "webmaster@golang.org", null, null, null, null, null, null, null), "mailto:webmaster@golang.org"),
    // Relative path
    URLTest.init("a/b/c", TestURL.init(null, null, null, null, "a/b/c", null, null, null, null), "a/b/c"),
    // escaped '?' in username and password
    // URLTest.init("http://%3Fam:pa%3Fsword@google.com", TestURL.init("http", null, UserInfo.initWithPassword("?am", "pa?sword"), "google.com", null, null, null, null, null), ""),
};

test "URL.parse" {
    var allocator = std.debug.global_allocator;
    var buf = &try Buffer.init(allocator, "");
    defer buf.deinit();
    for (url_tests) |ts, i| {
        const u = &try URL.parse(allocator, ts.in);
        try compare(ts.in, &ts.out, u);
        try u.encode(buf);
        if (ts.round_trip) |expect| {
            testing.expectEqualSlices(u8, expect, buf.toSlice());
        } else {
            testing.expectEqualSlices(u8, ts.in, buf.toSlice());
        }
        u.deinit();
    }
}

const test_failed = error.TestFailed;

fn equal(a: []const u8, b: ?[]const u8) bool {
    if (b == null) {
        return false;
    }
    return mem.eql(u8, a, b.?);
}

fn compare(uri: []const u8, a: *const TestURL, b: *const URL) !void {
    if (a.scheme) |scheme| {
        if (!equal(scheme, b.scheme)) {
            warn("{}: expected scheme={} got scheme={}\n", uri, scheme, b.scheme);
            return test_failed;
        }
    }
    if (a.opaque) |opaque| {
        if (!equal(opaque, b.opaque)) {
            warn("{}: expected opaque={} got opaque={}\n", uri, opaque, b.opaque);
            return test_failed;
        }
    }
    if (a.user) |user| {
        const u = b.user.?;
        if (user.username) |username| {
            if (!equal(username, u.username)) {
                warn("{}: expected username={} got username={}\n", uri, username, u.username);
                return test_failed;
            }
        }
        if (user.password) |password| {
            if (!equal(password, u.password)) {
                warn("{}: expected password={} got password={}\n", uri, password, u.password);
                return test_failed;
            }
        }
    }
    if (a.host) |host| {
        if (!equal(host, b.host)) {
            warn("{}: expected host={} got host={}\n", uri, host, b.host);
            return test_failed;
        }
    }
    if (a.path) |path| {
        if (!equal(path, b.path)) {
            warn("{}: expected path={} got path={}\n", uri, path, b.path);
            return test_failed;
        }
    }
    if (a.raw_path) |raw_path| {
        if (!equal(raw_path, b.raw_path)) {
            warn("{}: expected raw_path={} got raw_path={}\n", uri, raw_path, b.raw_path);
            return test_failed;
        }
    }
    if (a.force_query) |force_query| {
        if (force_query != b.force_query) {
            warn("{}: expected force_query={} got force_query={}\n", uri, force_query, b.force_query);
            return test_failed;
        }
    }
    if (a.raw_query) |raw_query| {
        if (!equal(raw_query, b.raw_query)) {
            warn("{}: expected raw_path={} got raw_path={}\n", uri, raw_query, b.raw_query);
            return test_failed;
        }
    }
    if (a.fragment) |fragment| {
        if (!equal(fragment, b.fragment)) {
            warn("{}: expected fragment={} got fragment={}\n", uri, fragment, b.fragment);
            return test_failed;
        }
    }
}

const image = @import("image.zig");
const Rectangle = image.Rectangle;
const std = @import("std");
const testing = std.testing;

fn in(f: Rectangle, g: Rectangle) bool {
    if (!f.in(g)) {
        return false;
    }
    var y = f.min.y;
    while (y < f.max.y) {
        var x = f.min.x;
        while (x < f.max.x) {
            var p = image.Point.init(x, y);
            if (!p.in(g)) {
                return false;
            }
            x += 1;
        }
        y += 1;
    }
    return true;
}

const rectangles = [_]Rectangle{
    Rectangle.rect(0, 0, 10, 10),
    Rectangle.rect(10, 0, 20, 10),
    Rectangle.rect(1, 2, 3, 4),
    Rectangle.rect(4, 6, 10, 10),
    Rectangle.rect(2, 3, 12, 5),
    Rectangle.rect(-1, -2, 0, 0),
    Rectangle.rect(-1, -2, 4, 6),
    Rectangle.rect(-10, -20, 30, 40),
    Rectangle.rect(8, 8, 8, 8),
    Rectangle.rect(88, 88, 88, 88),
    Rectangle.rect(6, 5, 4, 3),
};

test "Rectangle" {
    for (rectangles) |r| {
        for (rectangles) |s| {
            const got = r.eq(s);
            const want = in(r, s) and in(s, r);
            testing.expectEqual(got, want);
        }
    }

    for (rectangles) |r| {
        for (rectangles) |s| {
            const a = r.intersect(s);
            testing.expect(in(a, r));
            testing.expect(in(a, s));
            const is_zero = a.eq(Rectangle.zero());
            const overlaps = r.overlaps(s);
            testing.expect(is_zero != overlaps);
            const larger_than_a = [_]Rectangle{
                Rectangle.init(
                    a.min.x - 1,
                    a.min.y,
                    a.max.x,
                    a.max.y,
                ),
                Rectangle.init(
                    a.min.x,
                    a.min.y - 1,
                    a.max.x,
                    a.max.y,
                ),
                Rectangle.init(
                    a.min.x,
                    a.min.y,
                    a.max.x + 1,
                    a.max.y,
                ),
                Rectangle.init(
                    a.min.x,
                    a.min.y,
                    a.max.x,
                    a.max.y + 1,
                ),
            };
            for (larger_than_a) |b| {
                if (b.empty()) {
                    continue;
                }
                testing.expect(!(in(b, r) and in(b, s)));
            }
        }
    }

    for (rectangles) |r| {
        for (rectangles) |s| {
            const a = r.runion(s);
            testing.expect(in(r, a));
            testing.expect(in(s, a));
            if (a.empty()) {
                continue;
            }
            const smaller_than_a = [_]Rectangle{
                Rectangle.init(
                    a.min.x + 1,
                    a.min.y,
                    a.max.x,
                    a.max.y,
                ),
                Rectangle.init(
                    a.min.x,
                    a.min.y + 1,
                    a.max.x,
                    a.max.y,
                ),
                Rectangle.init(
                    a.min.x,
                    a.min.y,
                    a.max.x - 1,
                    a.max.y,
                ),
                Rectangle.init(
                    a.min.x,
                    a.min.y,
                    a.max.x,
                    a.max.y - 1,
                ),
            };
            for (smaller_than_a) |b| {
                testing.expect(!(in(r, b) and in(s, b)));
            }
        }
    }
}

const TestImage = struct {
    name: []const u8,
    image: image.Image,
    mem: []u8,
};

fn newRGBA(a: *std.mem.Allocator, r: Rectangle) !TestImage {
    const w = @intCast(usize, r.dx());
    const h = @intCast(usize, r.dy());
    const size = 4 * w * h;
    var u = try a.alloc(u8, size);
    var m = &image.RGBA.init(u, 4 * r.dx(), r);
    return TestImage{
        .name = "RGBA",
        .image = m.image(),
        .mem = u,
    };
}

test "Image" {
    var allocator = std.debug.global_allocator;
    const rgb = try newRGBA(allocator, Rectangle.rect(0, 0, 10, 10));
    defer allocator.free(rgb.mem);

    const test_images = [_]TestImage{rgb};

    for (test_images) |tc| {
        const r = Rectangle.rect(0, 0, 10, 10);
        testing.expect(r.eq(tc.image.bounds));
    }
}

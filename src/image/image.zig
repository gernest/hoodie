const color = @import("./color/index.zig");

/// A Point is an X, Y coordinate pair. The axes increase right and down.
pub const Point = struct {
    x: isize,
    y: isize,

    pub fn init(x: isize, y: isize) Point {
        return Point{ .x = x, .y = y };
    }

    pub fn add(p: Point, q: Point) Point {
        return Point{ .x = p.x + q.x, .y = p.y + q.y };
    }

    pub fn sub(p: Point, q: Point) Point {
        return Point{ .x = p.x - q.x, .y = p.y - q.y };
    }

    pub fn mul(p: Point, q: Point) Point {
        return Point{ .x = p.x * q.x, .y = p.y * q.y };
    }

    pub fn div(p: Point, q: Point) Point {
        return Point{ .x = @divExact(p.x, q.x), .y = @divExact(p.y, q.y) };
    }

    pub fn in(p: Point, r: Rectangle) bool {
        return r.min.x <= p.x and p.x < r.max.x and r.min.y <= p.y and p.y < r.max.y;
    }

    pub fn mod(p: Point, r: Rectangle) Point {
        const w = r.dx();
        const h = r.dy();
        const point = p.sub(r.min);
        var x = @mod(point.x, w);
        if (x < 0) {
            x += w;
        }
        var y = @mod(point.y, h);
        if (y < 0) {
            y += h;
        }
        const np = Point.init(x, y);
        return np.add(r.min);
    }

    pub fn eq(p: Point, q: Point) bool {
        return p.x == q.x and p.y == q.y;
    }
};

pub const Rectangle = struct {
    min: Point,
    max: Point,

    pub fn init(x0: isize, y0: isize, x1: isize, y1: isize) Rectangle {
        return Rectangle{
            .min = Point{
                .x = x0,
                .y = y0,
            },
            .max = Point{
                .x = x1,
                .y = y1,
            },
        };
    }

    pub fn rect(x0: isize, y0: isize, x1: isize, y1: isize) Rectangle {
        var r = Rectangle{
            .min = Point{
                .x = x0,
                .y = y0,
            },
            .max = Point{
                .x = x1,
                .y = y1,
            },
        };
        if (x0 > x1) {
            const x = x0;
            r.min.x = x1;
            r.max.x = x;
        }
        if (y0 > y1) {
            const y = y0;
            r.min.y = y1;
            r.max.y = y;
        }
        return r;
    }

    /// dx returns r's width.
    pub fn dx(r: Rectangle) isize {
        return r.max.x - r.min.x;
    }

    pub fn zero() Rectangle {
        return Rectangle.init(0, 0, 0, 0);
    }

    /// dy returns r's height.
    pub fn dy(r: Rectangle) isize {
        return r.max.y - r.min.y;
    }

    /// size returns r's width and height.
    pub fn size(r: Rectangle) Point {
        return Point{ .x = r.dx(), .y = r.dy() };
    }

    /// eEmpty reports whether the rectangle contains no points.
    pub fn empty(r: Rectangle) bool {
        return r.min.x >= r.max.x or r.min.y >= r.max.y;
    }

    pub fn add(r: Rectangle, p: Point) Rectangle {
        return Rectangle{
            .min = Point{ .x = r.min.x + p.x, .y = r.min.y + p.y },
            .max = Point{ .x = r.max.x + p.x, .y = r.max.y + p.y },
        };
    }

    pub fn sub(r: Rectangle, p: Point) Rectangle {
        return Rectangle{
            .min = Point{ .x = r.min.x - p.x, .y = r.min.y - p.y },
            .max = Point{ .x = r.max.x - p.x, .y = r.max.y - p.y },
        };
    }

    /// Inset returns the rectangle r inset by n, which may be negative. If either
    /// of r's dimensions is less than 2*n then an empty rectangle near the center
    /// of r will be returned.
    pub fn inset(r: Rectangle, n: isize) Rectangle {
        var x0 = r.min.x;
        var x1 = r.min.x;
        if (r.dx() < 2 * n) {
            x0 = @divExact((r.min.x + r.max.x), 2);
            x1 = x0;
        } else {
            x0 += n;
            x1 -= n;
        }
        var y0 = r.min.y;
        var y1 = r.max.y;
        if (r.dy() < 2 * n) {
            y0 = @divExact((r.min.y + r.max.y), 2);
            y1 = y0;
        } else {
            y0 += n;
            y1 -= n;
        }
        return Rectangle.init(x0, y0, x1, y1);
    }

    /// Intersect returns the largest rectangle contained by both r and s. If the
    /// two rectangles do not overlap then the zero rectangle will be returned.
    pub fn intersect(r: Rectangle, s: Rectangle) Rectangle {
        var x0 = r.min.x;
        var y0 = r.min.y;
        var x1 = r.max.x;
        var y1 = r.max.y;
        if (x0 < s.min.x) {
            x0 = s.min.x;
        }
        if (y0 < s.min.y) {
            y0 = s.min.y;
        }
        if (x1 > s.max.x) {
            x1 = s.max.x;
        }
        if (y1 > s.max.y) {
            y1 = s.max.y;
        }
        const rec = Rectangle.init(x0, y0, x1, y1);
        if (rec.empty()) {
            return Rectangle.zero();
        }
        return rec;
    }

    /// Union returns the smallest rectangle that contains both r and s.
    pub fn runion(r: Rectangle, s: Rectangle) Rectangle {
        if (r.empty()) {
            return s;
        }
        if (s.empty()) {
            return r;
        }
        var a = [_]isize{ r.min.x, r.min.y, r.max.x, r.max.y };
        if (a[0] > s.min.x) {
            a[0] = s.min.x;
        }
        if (a[1] > s.min.y) {
            a[1] = s.min.y;
        }
        if (a[2] < s.max.x) {
            a[2] = s.max.x;
        }
        if (a[3] < s.max.y) {
            a[3] = s.max.y;
        }
        return Rectangle.init(a[0], a[1], a[2], a[3]);
    }

    pub fn eq(r: Rectangle, s: Rectangle) bool {
        return r.max.eq(s.max) and r.min.eq(s.min) or r.empty() and s.empty();
    }

    pub fn overlaps(r: Rectangle, s: Rectangle) bool {
        return !r.empty() and !s.empty() and
            r.min.x < s.max.x and s.min.x < r.max.x and r.min.y < s.max.y and s.min.y < r.max.y;
    }

    pub fn in(r: Rectangle, s: Rectangle) bool {
        if (r.empty()) {
            return true;
        }
        return s.min.x <= r.min.x and r.max.x <= s.max.x and
            s.min.y <= r.min.y and r.max.y <= s.max.y;
    }

    pub fn canon(r: Rectangle) Rectangle {
        var x0 = r.min.x;
        var x1 = r.max.x;
        if (r.max.x < r.min.x) {
            const x = r.min.x;
            x0 = r.max.x;
            x1 = x;
        }
        var y0 = r.min.x;
        var y1 = r.min.x;
        if (r.min.y < r.max.y) {
            const y = y0;
            y0 = y1;
            y1 = y;
        }
        return Rectangle.init(x0, y0, x1, y1);
    }

    pub fn at(r: Rectangle, x: isize, y: isize) color.Color {
        var p = Point{ .x = x, .y = y };
        if (p.in(r)) {
            return color.Opaque.toColor();
        }
        return color.Transparent.toColor();
    }

    pub fn bounds(r: Rectangle) Rectangle {
        return r;
    }

    pub fn colorModel(r: Rectangle) color.Model {
        return color.Alpha16Model;
    }
};

pub const Config = struct {
    color_model: color.Model,
    width: isize,
    height: isize,
};

/// Image is a finite rectangular grid of color.Color values taken from a color
/// model.
pub const Image = struct {
    /// color_model is the Image's color model.
    color_model: color.Model,

    /// bounds is the domain for which At can return non-zero color.
    /// The bounds do not necessarily contain the point (0, 0).
    bounds: Rectangle,

    image_fn: ImageFuncs,
};

/// ImageFuncs are futcion which statisfies different interfaces. Some are
/// optional others are a must.
pub const ImageFuncs = struct {
    /// at returns the color of the pixel at (x, y).
    /// At(Bounds().Min.X, Bounds().Min.Y) returns the upper-left pixel of the grid.
    /// At(Bounds().Max.X-1, Bounds().Max.Y-1) returns the lower-right one.
    at_fn: fn (self: *ImageFuncs, x: isize, y: isize) color.Color,
    opaque_fn: ?fn (self: *ImageFuncs) bool,
    set_fn: ?fn (self: *ImageFuncs, x: isize, y: isize, c: color.ModelType) void,

    //  sets the sub_image field. This is a workaround after failing to express
    // the interface for returning sub image.
    //
    // The desired API is
    //   sub_image: ?fn (self: *ImageFuncs, r: Rectangle) Image,
    // However that code won't compile. unless we return *Image. which makes
    // matters even more complicated because I don't know how to make that
    // possible yet.
    //
    // TODO: Fix the API.
    set_sub_image: ?fn (self: *ImageFuncs, r: Rectangle) void,
    sub_image: ?*Image,
};

/// PalettedImage is an image whose colors may come from a limited palette.
/// If m is a PalettedImage and m.ColorModel() returns a color.Palette p,
/// then m.At(x, y) should be equivalent to p[m.ColorIndexAt(x, y)]. If m's
/// color model is not a color.Palette, then ColorIndexAt's behavior is
/// undefined.
pub const PalettedImage = struct {
    image: Image,
    color_index_at: fn (x: usize, y: usize) u8,
};

pub const Pix = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
    pub fn init() Pix {
        return Pix{
            .r = 0,
            .g = 0,
            .b = 0,
            .a = 0,
        };
    }
};

pub const RGBA = struct {
    /// Pix holds the image's pixels, in R, G, B, A order. The pixel at
    /// (x, y) starts at Pix[(y-Rect.Min.Y)*Stride + (x-Rect.Min.X)*4].
    pix: []u8,

    /// Stride is the Pix stride (in bytes) between vertically adjacent pixels.
    stride: isize,

    /// Rect is the image's bounds.
    rect: Rectangle,
    image_fn: ImageFuncs,
    pub fn init(pix: []u8, stride: isize, rect: Rectangle) RGBA {
        return RGBA{
            .pix = pix,
            .stride = stride,
            .rect = rect,
            .image_fn = ImageFuncs{
                .at_fn = at,
                .opaque_fn = opaqueFn,
                .set_fn = setFn,
                .set_sub_image = subImageFn,
                .sub_image = null,
            },
        };
    }

    pub fn zero() RGBA {
        return RGBA.init("", 0, Rectangle.zero());
    }

    pub fn colorModel(r: *RGBA) color.Model {
        return color.RGBAModel;
    }

    pub fn rgbaAt(r: *RGBA, x: isize, y: isize) color.RGBA {
        const p = Point.init(x, y);
        if (p.in(r.rect)) {
            return color.RGBA{ .r = 0, .g = 0, .b = 0, .a = 0 };
        }
        const i = r.pixOffset(x, y);
        const size = @intCast(usize, i);
        const s = r.pix[size .. size + 4];
        return color.RGBA{ .r = s[0], .g = s[1], .b = s[2], .a = s[3] };
    }

    pub fn at(r: *ImageFuncs, x: isize, y: isize) color.Color {
        const self = @fieldParentPtr(RGBA, "image_fn", r);
        return self.rgbaAt(x, y).toColor();
    }

    pub fn opaqueFn(r: *ImageFuncs) bool {
        const self = @fieldParentPtr(RGBA, "image_fn", r);
        return self.opaque();
    }

    pub fn subImageFn(r: *ImageFuncs, rec: Rectangle) void {
        const self = @fieldParentPtr(RGBA, "image_fn", r);
        var img = self.subImage(rec).image();
        r.sub_image = &img;
    }

    pub fn setFn(r: *ImageFuncs, x: isize, y: isize, c: color.ModelType) void {
        const self = @fieldParentPtr(RGBA, "image_fn", r);
        return self.set(x, y, c);
    }

    pub fn pixOffset(r: *RGBA, x: isize, y: isize) isize {
        return (y - r.rect.min.y) * r.stride + (x - r.rect.min.x) * 4;
    }

    pub fn image(r: *RGBA) Image {
        return Image{
            .color_model = r.colorModel(),
            .image_fn = r.image_fn,
            .bounds = r.rect,
        };
    }

    pub fn set(r: *RGBA, x: isize, y: isize, c: color.ModelType) void {
        const p = Point.init(x, y);
        if (p.in(r.rect)) {
            return;
        }
        const v = color.RGBAModel.convert(c);
        const i = r.pixOffset(x, y);
        const size = @intCast(usize, i);
        var s = r.pix[size .. size + 4];
        s[0] = @intCast(u8, v.rgb.r);
        s[1] = @intCast(u8, v.rgb.g);
        s[2] = @intCast(u8, v.rgb.b);
        s[3] = @intCast(u8, v.rgb.a);
    }

    pub fn setRGBA(r: *RGBA, x: isize, y: isize, c: color.RGBA) void {
        const p = Point.init(x, y);
        if (p.in(r.rect)) {
            return;
        }
        const i = r.pixOffset(x, y);
        const size = @intCast(usize, i);
        const s = r.pix[size .. size + 4];
        s[0] = c.r;
        s[1] = c.g;
        s[2] = c.b;
        s[3] = c.a;
    }

    /// subImage returns an image representing the portion of the image p visible
    /// through rec. The returned value shares pixels with the original image.
    pub fn subImage(r: *RGBA, rec: Rectangle) RGBA {
        const ri = rec.intersect(r.rect);
        if (ri.empty()) {
            return RGBA.zero();
        }
        const i = r.pixOffset(ri.min.x, ri.min.y);
        const size = @intCast(usize, i);
        return RGBA.init(r.pix[size..], r.stride, ri);
    }

    pub fn opaque(r: *RGBA) bool {
        if (r.rect.empty()) {
            return true;
        }
        var x0: isize = 0;
        var x1 = r.rect.dx() * 4;
        var y = r.rect.min.y;
        while (y < r.rect.max.y) {
            var i = x0;
            while (i < x1) {
                const idx = @intCast(usize, i);
                if (r.pix[idx] == 0xff) {
                    return false;
                }
                i += 4;
            }
            x0 += r.stride;
            x1 += r.stride;
            y += 1;
        }
        return true;
    }
};

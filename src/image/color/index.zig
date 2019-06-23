/// Color can convert itself to alpha-premultiplied 16-bits per channel RGBA.
/// The conversion may be lossy.
pub const Color = struct{
    rgb: Value,
};

/// Value is the alpha-premultiplied red, green, blue and alpha values
/// for the color. Each value ranges within [0, 0xffff], but is represented
/// by a uint32 so that multiplying by a blend factor up to 0xffff will not
/// overflow.
///
/// An alpha-premultiplied color component c has been scaled by alpha (a),
/// so has valid values 0 <= c <= a.
pub const Value = struct{
    r: u32,
    g: u32,
    b: u32,
    a: u32,
};

/// Model can convert any Color to one from its own color model. The conversion
/// may be lossy.
pub const Model = struct{
    convert: fn (c: ModelType) Color,
};

/// RGBA represents a traditional 32-bit alpha-premultiplied color, having 8
/// bits for each of red, green, blue and alpha.
///
/// An alpha-premultiplied color component C has been scaled by alpha (A), so
/// has valid values 0 <= C <= A.
pub const RGBA = struct{
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    fn toColor(c: RGBA) Color {
        return Color{ .rgb = c.toValue() };
    }

    fn toValue(c: RGBA) Value {
        var r: u32 = c.r;
        r |= r << 8;
        var g: u32 = c.g;
        g |= g << 8;
        var b: u32 = c.b;
        b |= b << 8;
        var a: u32 = c.a;
        a |= a << 8;
        return Value{
            .r = r,
            .g = g,
            .b = b,
            .a = a,
        };
    }
};

/// RGBA64 represents a 64-bit alpha-premultiplied color, having 16 bits for
/// each of red, green, blue and alpha.
/// An alpha-premultiplied color component C has been scaled by alpha (A), so
/// has valid values 0 <= C <= A.
pub const RGBA64 = struct{
    r: u16,
    g: u16,
    b: u16,
    a: u16,

    fn toColor(c: RGBA64) Value {
        return Color{ .rgb = c.toValue };
    }

    fn toValue(c: RGBA64) Value {
        return Value{
            .r = c.r,
            .g = c.g,
            .b = c.b,
            .a = c.a,
        };
    }
};

/// NRGBA represents a non-alpha-premultiplied 32-bit color.
pub const NRGBA = struct{
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    fn toColor(c: NBRGBA) Value {
        var r: u32 = c.r;
        var g: u32 = c.g;
        var b: u32 = c.b;
        var a: u32 = c.a;
        r |= r << 8;
        r *= a;
        r /= 0xff;
        g |= g << 8;
        g *= a;
        g /= 0xff;
        b |= b << 8;
        b *= a;
        b /= 0xff;
        a |= a << 8;
        return Value{
            .r = r,
            .g = g,
            .b = b,
            .a = a,
        };
    }
};

pub const NBRGBA64 = struct{
    r: u16,
    g: u16,
    b: u16,
    a: u16,

    fn toColor(c: NBRGBA64) Value {
        var r: u32 = c.r;
        var g: u32 = c.g;
        var b: u32 = c.b;
        var a: u32 = c.a;
        r |= r << 8;
        r *= a;
        r /= 0xffff;
        g |= g << 8;
        g *= a;
        g /= 0xffff;
        b |= b << 8;
        b *= a;
        b /= 0xffff;
        return Value{
            .r = r,
            .g = g,
            .b = b,
            .a = a,
        };
    }
};

/// Alpha represents an 8-bit alpha color.
pub const Alpha = struct{
    a: u8,

    fn toColor(c: Alpha) Color {
        return Color{ .rgb = c.toValue() };
    }
    fn toValue(c: Alpha) Value {
        var a: u32 = c.a;
        a |= a << 8;
        return Value{
            .r = a,
            .g = a,
            .b = a,
            .a = a,
        };
    }
};

pub const Alpha16 = struct{
    a: u16,

    fn toColor(c: Alpha16) Color {
        return Color{ .rgb = c.toValue() };
    }
    fn toValue(c: Alpha16) Value {
        var a: u32 = c.a;
        a |= a << 8;
        return Value{
            .r = a,
            .g = a,
            .b = a,
            .a = a,
        };
    }
};

/// Gray represents an 8-bit grayscale color.
pub const Gray = struct{
    y: u8,

    fn toColor(c: Gray) Value {
        var y: u32 = c.y;
        y |= y << 8;
        return Value{
            .r = y,
            .g = y,
            .b = y,
            .a = 0xffff,
        };
    }
};

pub const Gray16 = struct{
    y: u16,

    fn toColor(c: Gray16) Value {
        var y: u32 = c.y;
        return Value{
            .r = y,
            .g = y,
            .b = y,
            .a = 0xffff,
        };
    }
};

pub const RGBAModel = Model{ .convert = ModelType.rgbaModel };
pub const RGBA64Model = Model{ .convert = ModelType.rgba64Model };
pub const NRGBAModel = Model{ .convert = ModelType.nrgbaModel };
pub const NRGBA64Model = Model{ .convert = ModelType.nrgba64Model };
pub const Alpha16Model = Model{ .convert = ModelType.alpha16Model };
pub const GrayModel = Model{ .convert = ModelType.grayModel };
pub const Gray16Model = Model{ .convert = ModelType.gray16Model };

pub const ModelType = union(enum){
    rgba: RGBA,
    rgba64: RGBA64,
    nrgba: NRGBA,
    nrgba64: NBRGBA64,
    alpha: Alpha,
    alpha16: Alpha16,
    gray: Gray,
    gray16: Gray16,
    color: Color,

    pub fn rgbaModel(m: ModelType) Color {
        return switch (m) {
            ModelType.rgba => |c| c.toColor(),
            ModelType.color => |c| {
                const model = RGBA{
                    .r = @intCast(u8, c.rgb.r >> 8),
                    .g = @intCast(u8, c.rgb.g >> 8),
                    .b = @intCast(u8, c.rgb.b >> 8),
                    .a = @intCast(u8, c.rgb.a >> 8),
                };
                return model.toColor();
            },
            else => unreachable,
        };
    }

    pub fn rgba64Model(m: ModelType) Color {
        return switch (m) {
            ModelType.rgba64 => |c| c.toColor(),
            ModelType.color => |c| {
                const model = RGBA64{
                    .r = c.rgb.r,
                    .g = c.rgb.g,
                    .b = c.rgb.b,
                    .a = c.rgb.a,
                };
                return model.toColor();
            },
            else => unreachable,
        };
    }

    pub fn nrgbaModel(m: ModelType) Color {
        return switch (m) {
            ModelType.nrgba => |c| c.toColor(),
            ModelType.color => |c| {
                if (c.rgb.a == 0xffff) {
                    const model = NRGBA{
                        .r = @intCast(u8, c.rgb.r >> 8),
                        .g = @intCast(u8, c.rgb.g >> 8),
                        .b = @intCast(u8, c.rgb.b >> 8),
                        .a = 0xff,
                    };
                    return model.toColor();
                }
                if (c.rgb.a == 0) {
                    const model = NRGBA{
                        .r = 0,
                        .g = 0,
                        .b = 0,
                        .a = 0,
                    };
                    return model.toColor();
                }
                var r = (c.rgb.r * 0xffff) / c.rgb.a;
                var g = (c.rgb.g * 0xffff) / c.rgb.a;
                var b = (c.rgb.b * 0xffff) / c.rgb.a;
                const model = NRGBA{
                    .r = @intCast(u8, r >> 8),
                    .g = @intCast(u8, g >> 8),
                    .b = @intCast(u8, b >> 8),
                    .a = @intCast(u8, c.rgb.a >> 8),
                };
                return model.toColor();
            },
            else => unreachable,
        };
    }
    pub fn nrgba64Model(m: ModelType) Color {
        return switch (m) {
            ModelType.nrgba64 => |c| c.toColor(),
            ModelType.color => |c| {
                if (c.rgb.a == 0xffff) {
                    const model = NRGBA64{
                        .r = c.rgb.r,
                        .g = c.rgb.g,
                        .b = c.rgb.b,
                        .a = 0xff,
                    };
                    return model.toColor();
                }
                if (c.rgb.a == 0) {
                    const model = NRGBA64{
                        .r = 0,
                        .g = 0,
                        .b = 0,
                        .a = 0,
                    };
                    return model.toColor();
                }
                var r = (c.rgb.r * 0xffff) / c.rgb.a;
                var g = (c.rgb.g * 0xffff) / c.rgb.a;
                var b = (c.rgb.b * 0xffff) / c.rgb.a;
                const model = NRGBA64{
                    .r = r,
                    .g = g,
                    .b = b,
                    .a = c.rgb.a,
                };
                return model.toColor();
            },
            else => unreachable,
        };
    }

    pub fn alphaModel(m: ModelType) Color {
        return switch (m) {
            ModelType.alpha => |c| c.toColor(),
            ModelType.color => |c| {
                const model = Alpha{ .a = @intCast(u8, c.rgb.a >> 8) };
                return model.toColor();
            },
            else => unreachable,
        };
    }

    pub fn alpha16Model(m: ModelType) Color {
        return switch (m) {
            ModelType.alpha16 => |c| c.toColor(),
            ModelType.color => |c| {
                const model = Alpha16{ .a = @intCast(u16, c.rgb.a) };
                return model.toColor();
            },
            else => unreachable,
        };
    }

    pub fn grayModel(m: ModelType) Color {
        return switch (m) {
            ModelType.gray => |c| c.toColor(),
            ModelType.color => |c| {

                // These coefficients (the fractions 0.299, 0.587 and 0.114) are the same
                // as those given by the JFIF specification and used by func RGBToYCbCr in
                // ycbcr.go.
                //
                // Note that 19595 + 38470 + 7471 equals 65536.
                //
                // The 24 is 16 + 8. The 16 is the same as used in RGBToYCbCr. The 8 is
                // because the return value is 8 bit color, not 16 bit color.
                const y = (19595 * c.rgb.r + 38470 * c.rgb.g + 7471 * c.rgb.b + 1 << 15) >> 24;
                const model = Gray{ .y = @intCast(u8, y) };
                return model.toColor();
            },
            else => unreachable,
        };
    }
    pub fn gray16Model(m: ModelType) Color {
        return switch (m) {
            ModelType.gray16 => |c| c.toColor(),
            ModelType.color => |c| {

                // These coefficients (the fractions 0.299, 0.587 and 0.114) are the same
                // as those given by the JFIF specification and used by func RGBToYCbCr in
                // ycbcr.go.
                //
                // Note that 19595 + 38470 + 7471 equals 65536.
                const y = (19595 * c.rgb.r + 38470 * c.rgb.g + 7471 * c.rgb.b + 1 << 15) >> 16;
                const model = Gray16{ .y = @intCast(u16, y) };
                return model.toColor();
            },
            else => unreachable,
        };
    }
};

pub const Black = Gray{ .y = 0 };
pub const White = Gray{ .y = 0xffff };
pub const Transparent = Alpha{ .a = 0 };
pub const Opaque = Alpha16{ .a = 0xffff };

/// sqDiff returns the squared-difference of x and y, shifted by 2 so that
/// adding four of those won't overflow a uint32.
///
/// x and y are both assumed to be in the range [0, 0xffff].
fn sqDiff(x: u32, y: u32) u32 {
    // The canonical code of this function looks as follows:
    //
    //    var d uint32
    //    if x > y {
    //        d = x - y
    //    } else {
    //        d = y - x
    //    }
    //    return (d * d) >> 2
    //
    // Language spec guarantees the following properties of unsigned integer
    // values operations with respect to overflow/wrap around:
    //
    // > For unsigned integer values, the operations +, -, *, and << are
    // > computed modulo 2n, where n is the bit width of the unsigned
    // > integer's type. Loosely speaking, these unsigned integer operations
    // > discard high bits upon overflow, and programs may rely on ``wrap
    // > around''.
    //
    // Considering these properties and the fact that this function is
    // called in the hot paths (x,y loops), it is reduced to the below code
    const d = x - y;
    return (d * d) >> 2;
}

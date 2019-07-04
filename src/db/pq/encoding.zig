pub const List = std.ArrayList(Value);

const Value = union(enum) {
    Bool: bool,
    Float: float64,
    Int: int64,
    String: []const u8,
    RawBytes: []const u8,
    List: List,
};

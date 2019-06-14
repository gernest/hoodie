/// Tries to minick rust's result type.
pub fn Result(T: type, E: type) type {
    return union(enum) {
        Ok: T,
        Err: E,
    };
}

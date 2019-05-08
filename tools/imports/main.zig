// This sorts imports statements and present them nicely at the top level of the
// source files.

const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const ast = std.zig.ast;
const parse = std.zig.parse;
const warn = std.debug.warn;

const ImportList = std.ArrayList(ImportNode);

fn organize(a: *Allocator, src: []const u8) anyerror!void {
    var tree = try parse(a, src);
    defer tree.deinit();
    var ls = ImportList.init(a);
    defer ls.deinit();

    // tree.root_node.base.dump(0);
    var it = tree.root_node.decls.iterator(0);
    while (true) {
        var decl = (it.next() orelse break).*;
        try collect(
            &tree,
            &ls,
            IterOpts{
                .box_index = it.box_index,
                .shelf_index = it.shelf_index,
                .index = it.index,
            },
            decl,
        );
    }
    std.sort.sort(ImportNode, ls.toSlice(), lessFn);
    for (ls.toSlice()) |x| {
        warn("{} {}\n", x.name, x.iter_opts);
    }
}

const ImportNode = struct {
    node: *ast.Node,
    name: []const u8,
    iter_opts: IterOpts,
};

const IterOpts = struct {
    index: usize,
    box_index: usize,
    shelf_index: usize,
};

fn lessFn(lhs: ImportNode, rhs: ImportNode) bool {
    return mem.compare(u8, lhs.name, rhs.name) == mem.Compare.LessThan;
}

fn collect(
    tree: *ast.Tree,
    ls: *ImportList,
    opts: IterOpts,
    decl: *ast.Node,
) !void {
    switch (decl.id) {
        ast.Node.Id.VarDecl => {
            const var_decl = @fieldParentPtr(ast.Node.VarDecl, "base", decl);
            if (var_decl.init_node) |init_node| {
                switch (init_node.id) {
                    ast.Node.Id.BuiltinCall => {
                        var builtn_call = @fieldParentPtr(ast.Node.BuiltinCall, "base", init_node);
                        const fn_name = tree.tokenSlice(builtn_call.builtin_token);
                        if (mem.eql(u8, fn_name, "@import")) {
                            const decl_name = tree.tokenSlice(var_decl.name_token);
                            try ls.append(ImportNode{
                                .node = decl,
                                .name = decl_name,
                                .iter_opts = opts,
                            });
                        }
                    },
                    else => {},
                }
            }
        },
        else => {},
    }
}

fn testImports(a: *Allocator, src: []const u8) !void {
    try organize(a, src);
}

test "imports" {
    var a = std.debug.global_allocator;
    try testImports(a,
        \\ const c=@import("c");
        \\ const b=@import("b");
        \\ const a=@import("a");
    );
}

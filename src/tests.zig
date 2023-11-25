const std = @import("std");
const btree = @import("tree.zig");

const testing = std.testing;
const allocator = testing.allocator;

const BTree = btree.BTree(isize, 5);

fn comparator(e1: isize, e2: isize) btree.Comparison {
    if (e1 < e2) {
        return btree.Comparison.Lesser;
    } else if (e1 > e2) {
        return btree.Comparison.Greater;
    }
    return btree.Comparison.Equal;
}

fn insertAndSearchAll(tree: *BTree, elements: []const isize) !void {
    for (elements) |element| {
        try tree.insert(element);
    }
    for (elements) |element| {
        try testing.expect(tree.contains(element));
    }
}

test "Can init and deinit" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();
}

test "Can insert a single element" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    const elements = [_]isize{0};
    try insertAndSearchAll(&tree, elements[0..]);
}

test "Can insert various elements" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    const elements = [_]isize{ 0, 1, 2 };
    try insertAndSearchAll(&tree, elements[0..]);
}

test "Can insert various elements out of order" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    const elements = [_]isize{ 1, 2, 0 };
    try insertAndSearchAll(&tree, elements[0..]);
}

test "Can fill the root node" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    const elements = [_]isize{ 0, 1, 2, 3 };
    try insertAndSearchAll(&tree, elements[0..]);
}

test "Can overflow the root node" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    const elements = [_]isize{ 0, 1, 2, 3, 4 };
    try insertAndSearchAll(&tree, elements[0..]);
}

test "Can insert on left child" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    const elements = [_]isize{ 0, 10, 20, 30, 40, 5 };
    try insertAndSearchAll(&tree, elements[0..]);
}

test "Can insert on right child" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    const elements = [_]isize{ 0, 10, 20, 30, 40, 35 };
    try insertAndSearchAll(&tree, elements[0..]);
}

test "Can fill children" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    const elements = [_]isize{ 0, 10, 20, 30, 40 };
    try insertAndSearchAll(&tree, elements[0..]);

    const elements_left = [_]isize{ 5, 15 };
    try insertAndSearchAll(&tree, elements_left[0..]);

    const elements_right = [_]isize{ 35, 25 };
    try insertAndSearchAll(&tree, elements_right[0..]);
}

test "Can overflow left child node" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    const elements = [_]isize{
        0, 10, 20, 30, 40,
        // left
        6, 12, 18,
    };
    try insertAndSearchAll(&tree, elements[0..]);
}

test "Can overflow right child node" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    const elements = [_]isize{
        0,  10, 20, 30, 40,
        // right
        34, 28, 22,
    };
    try insertAndSearchAll(&tree, elements[0..]);
}

test "Can overflow non leaf root" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    const elements = [_]isize{
        0,  10, 20, 30, 40,
        // 1
        6,  12, 18,
        // 2
        22, 28,
        34,
        // 3
        38, 42, 46,
        // 4
        50,
        54, 58,
    };
    try insertAndSearchAll(&tree, elements[0..]);
}

test "Splitting updates childs upreference" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    const elements = [_]isize{
        100,  200,  1000, 1100, 1200,
        // 1
        2000, 2100, 2200,
        // 2
        3000, 3100,
        3200,
        // 3
        4000, 4100, 4200,
        // 4
        5000,
        5100, 5200,
        // 5
        4300, 4400, 4500,
    };
    try insertAndSearchAll(&tree, elements[0..]);
}

test "Can insert many many nodes" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    const elements = try allocator.alloc(isize, 1000);
    defer allocator.free(elements);

    var random = std.rand.DefaultPrng.init(0);
    for (elements, 0..) |_, index| {
        elements[index] = random.random().int(isize);
    }

    try insertAndSearchAll(&tree, elements[0..]);
}

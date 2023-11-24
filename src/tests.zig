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

test "Can init and deinit" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();
}

test "Can insert a single element" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    tree.insert(0);
    try testing.expect(tree.contains(0));
}

test "Can insert various elements" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    tree.insert(0);
    tree.insert(1);
    tree.insert(2);
    try testing.expect(tree.contains(0));
    try testing.expect(tree.contains(1));
    try testing.expect(tree.contains(2));
}

test "Can insert various elements out of order" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    tree.insert(1);
    tree.insert(2);
    tree.insert(0);
    try testing.expect(tree.contains(0));
    try testing.expect(tree.contains(1));
    try testing.expect(tree.contains(2));
}

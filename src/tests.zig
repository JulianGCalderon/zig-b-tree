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

    try tree.insert(0);
    try testing.expect(tree.contains(0));
}

test "Can insert various elements" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    try tree.insert(0);
    try tree.insert(1);
    try tree.insert(2);
    try testing.expect(tree.contains(0));
    try testing.expect(tree.contains(1));
    try testing.expect(tree.contains(2));
}

test "Can insert various elements out of order" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    try tree.insert(1);
    try tree.insert(2);
    try tree.insert(0);
    try testing.expect(tree.contains(0));
    try testing.expect(tree.contains(1));
    try testing.expect(tree.contains(2));
}

test "Can overflow the root node" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    try tree.insert(0);
    try tree.insert(1);
    try tree.insert(2);
    try tree.insert(3);
    try tree.insert(4);
    try testing.expect(tree.contains(0));
    try testing.expect(tree.contains(1));
    try testing.expect(tree.contains(2));
    try testing.expect(tree.contains(3));
    try testing.expect(tree.contains(4));
}

test "Can insert on left child" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    try tree.insert(0);
    try tree.insert(2);
    try tree.insert(4);
    try tree.insert(6);
    try tree.insert(8);
    try tree.insert(1);

    try testing.expect(tree.contains(0));
    try testing.expect(tree.contains(1));
    try testing.expect(tree.contains(2));
    try testing.expect(tree.contains(4));
    try testing.expect(tree.contains(6));
    try testing.expect(tree.contains(8));
}

test "Can insert on right child" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    try tree.insert(0);
    try tree.insert(2);
    try tree.insert(4);
    try tree.insert(6);
    try tree.insert(8);
    try tree.insert(7);

    try testing.expect(tree.contains(0));
    try testing.expect(tree.contains(2));
    try testing.expect(tree.contains(4));
    try testing.expect(tree.contains(6));
    try testing.expect(tree.contains(7));
    try testing.expect(tree.contains(8));
}

test "Can fill children" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    try tree.insert(0);
    try tree.insert(2);
    try tree.insert(4);
    try tree.insert(6);
    try tree.insert(8);
    try tree.insert(1);
    try tree.insert(3);
    try tree.insert(5);
    try tree.insert(7);

    try testing.expect(tree.contains(0));
    try testing.expect(tree.contains(2));
    try testing.expect(tree.contains(4));
    try testing.expect(tree.contains(6));
    try testing.expect(tree.contains(8));
    try testing.expect(tree.contains(1));
    try testing.expect(tree.contains(3));
    try testing.expect(tree.contains(5));
    try testing.expect(tree.contains(7));
}

test "Can overflow children" {
    var tree = try BTree.init(allocator, comparator);
    defer tree.deinit();

    try tree.insert(0);
    try tree.insert(2);
    try tree.insert(4);
    try tree.insert(6);
    try tree.insert(8);
    try tree.insert(1);
    try tree.insert(3);
    try tree.insert(5);
    try tree.insert(7);
    try tree.insert(-1);

    try testing.expect(tree.contains(0));
    try testing.expect(tree.contains(2));
    try testing.expect(tree.contains(4));
    try testing.expect(tree.contains(6));
    try testing.expect(tree.contains(8));
    try testing.expect(tree.contains(1));
    try testing.expect(tree.contains(3));
    try testing.expect(tree.contains(5));
    try testing.expect(tree.contains(7));
    try testing.expect(tree.contains(-1));
}

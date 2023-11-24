const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Comparison = enum {
    Lesser,
    Greater,
    Equal,
};

pub fn BTree(comptime T: type, comptime order: usize) type {
    return struct {
        const Self = @This();
        const Comparator = *const fn (T, T) Comparison;

        allocator: Allocator,
        comparator: *const fn (T, T) Comparison,
        root: *Node,

        pub fn init(allocator: Allocator, comparator: Comparator) !Self {
            return Self{
                .allocator = allocator,
                .comparator = comparator,
                .root = try Node.init(allocator, comparator),
            };
        }

        pub fn insert(self: *Self, element: T) !void {
            return self.root.insert(element);
        }

        pub fn contains(self: *Self, element: T) bool {
            return self.root.contains(element);
        }

        pub fn deinit(self: *Self) void {
            self.root.deinit();
        }

        const Node = struct {
            const ValueArray = std.BoundedArray(T, order);
            const ChildArray = std.BoundedArray(*Node, order);

            allocator: Allocator,
            comparator: Comparator,
            values: ValueArray,
            childs: ChildArray,
            parent: ?*Node,

            pub fn init(allocator: Allocator, comparator: Comparator) Allocator.Error!*Node {
                const node = try allocator.create(Node);

                node.allocator = allocator;
                node.comparator = comparator;
                node.values = ValueArray.init(0) catch unreachable;
                node.childs = ChildArray.init(0) catch unreachable;
                node.parent = null;

                return node;
            }

            pub fn deinit(self: *Node) void {
                for (self.childs.slice()) |child| {
                    child.deinit();
                }

                self.allocator.destroy(self);
            }

            pub fn insert(self: *Node, element: T) Allocator.Error!void {
                try self.insertLocal(element);

                if (self.values.len == self.values.capacity()) {
                    const sibling_separator = try self.split();
                    const separator = sibling_separator[0];
                    const sibling = sibling_separator[1];

                    if (self.parent == null) {
                        try self.split_root(separator, sibling);
                    } else {
                        try self.parent.insert_child(separator, sibling);
                    }
                }
            }

            pub fn insertLocal(self: *Node, element: T) Allocator.Error!void {
                for (self.values.slice(), 0..) |value, i| {
                    switch (self.comparator(element, value)) {
                        Comparison.Lesser => {
                            if (self.childs.len > i) {
                                try self.childs.get(i).insert(element);
                            } else {
                                self.values.insert(i, element) catch unreachable;
                            }
                            return;
                        },
                        Comparison.Equal => {},
                        Comparison.Greater => {},
                    }
                }

                if (self.childs.len > 0) {
                    try self.childs.get(self.childs.len - 1).insert(element);
                } else {
                    self.values.append(element) catch unreachable;
                }
            }

            pub fn split(self: *Node) !struct { T, *Node } {
                const middleIndex = self.values.len / 2;
                const middle = self.values.get(middleIndex);

                var sibling = try Node.init(self.allocator, self.comparator);
                sibling.values.appendSlice(self.values.slice()[middleIndex + 1 ..]) catch unreachable;

                self.values.resize(middleIndex) catch unreachable;

                return .{ middle, sibling };
            }

            pub fn split_root(self: *Node, separator: T, sibling: *Node) Allocator.Error!void {
                var child = try Node.init(self.allocator, self.comparator);
                child.parent = self;
                child.values = self.values;

                sibling.parent = self;

                self.values.resize(0) catch unreachable;
                self.values.append(separator) catch unreachable;
                self.childs.append(child) catch unreachable;
                self.childs.append(sibling) catch unreachable;
            }

            pub fn insert_child(self: *Node, separator: T, sibling: *Node) Allocator.Error!void {
                _ = sibling;
                _ = separator;
                _ = self;

                // needs to insert sibling in the parent, next to caller node,
                // with separator in between
            }

            pub fn contains(self: Node, element: T) bool {
                for (self.values.slice(), 0..) |value, i| {
                    switch (self.comparator(element, value)) {
                        Comparison.Equal => {
                            return true;
                        },
                        Comparison.Lesser => {
                            if (self.childs.len > i) {
                                return self.childs.get(i).contains(element);
                            }
                            return false;
                        },
                        Comparison.Greater => {},
                    }
                }

                if (self.childs.len > 0) {
                    return self.childs.get(self.childs.len - 1).contains(element);
                }
                return false;
            }
        };
    };
}

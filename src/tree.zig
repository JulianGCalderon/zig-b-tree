const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Comparison = enum {
    Lesser,
    Greater,
    Equal,
};

pub const Error = error{
    DuplicateElement,
} || Allocator.Error;

/// Definición en tiempo de compilación del árbol. El orden del árbol también se
/// define en timepo de compilación ya que se utilizan arreglos estáticos en los
/// nodos.
pub fn BTree(comptime T: type, comptime order: usize) type {
    return struct {
        const Self = @This();
        const Comparator = *const fn (T, T) Comparison;

        allocator: Allocator,
        comparator: *const fn (T, T) Comparison,
        root: *Node,

        pub fn init(allocator: Allocator, comparator: Comparator) Error!Self {
            return Self{
                .allocator = allocator,
                .comparator = comparator,
                .root = try Node.init(allocator, comparator),
            };
        }

        pub fn insert(self: *Self, element: T) !void {
            return self.root.insert(element);
        }

        pub fn remove(self: *Self, element: T) !void {
            return self.root.remove(element);
        }

        pub fn contains(self: *Self, element: T) bool {
            return self.root.contains(element);
        }

        pub fn deinit(self: *Self) void {
            self.root.deinit();
        }

        const Node = struct {
            const ValueArray = std.BoundedArray(T, order);
            const ChildArray = std.BoundedArray(*Node, order + 1);

            allocator: Allocator,
            comparator: Comparator,

            values: ValueArray,
            childs: ChildArray,
            parent: ?*Node,

            pub fn init(allocator: Allocator, comparator: Comparator) Error!*Node {
                const node = try allocator.create(Node);

                node.allocator = allocator;
                node.comparator = comparator;
                node.parent = null;

                node.values = ValueArray.init(0) catch unreachable;
                node.childs = ChildArray.init(0) catch unreachable;

                return node;
            }

            pub fn deinit(self: *Node) void {
                for (self.childs.slice()) |child| {
                    child.deinit();
                }

                self.allocator.destroy(self);
            }

            pub fn insert(self: *Node, element: T) Error!void {
                if (self.isLeaf()) {
                    try self.insertInNode(element);
                } else {
                    try self.insertInChild(element);
                }
            }

            /// Performs an ordered insert of the element in the current node.
            /// Panics if there is no space left
            fn insertInNode(self: *Node, element: T) Error!void {
                for (self.values.slice(), 0..) |value, i| {
                    switch (self.comparator(element, value)) {
                        Comparison.Lesser => {
                            self.values.insert(i, element) catch unreachable;
                            break;
                        },
                        Comparison.Equal => {
                            return Error.DuplicateElement;
                        },
                        else => {},
                    }
                } else {
                    self.values.append(element) catch unreachable;
                }

                if (self.isFull()) {
                    try self.split();
                }
            }

            /// Performs an ordered insert of the element in the corresponding
            /// child.
            fn insertInChild(self: *Node, element: T) Error!void {
                for (self.values.slice(), 0..) |value, i| {
                    switch (self.comparator(element, value)) {
                        Comparison.Lesser => {
                            return self.childs.get(i).insert(element);
                        },
                        Comparison.Equal => {
                            return Error.DuplicateElement;
                        },
                        else => {},
                    }
                } else {
                    try self.lastChild().insert(element);
                }
            }

            /// Splits the node in two, and inserts the right subnode as sibling
            /// into the parent. The current node will be the left subnode
            ///
            /// If there is no parent, a new left subnode will be alloced, and
            /// the current node will behave as parent of both.
            pub fn split(self: *Node) Error!void {
                const separatorIndex = self.values.len / 2;
                const separator = self.values.get(separatorIndex);

                const right_node = try Node.init(self.allocator, self.comparator);
                right_node.values.appendSlice(self.values.slice()[separatorIndex + 1 ..]) catch unreachable;
                self.values.resize(separatorIndex) catch unreachable;

                if (!self.isLeaf()) {
                    right_node.childs.appendSlice(self.childs.slice()[separatorIndex + 1 ..]) catch unreachable;
                    self.childs.resize(separatorIndex + 1) catch unreachable;

                    right_node.updateChildsUpreference();
                }

                if (self.parent) |parent| {
                    right_node.parent = parent;
                    return parent.insertChild(separator, right_node);
                } else {
                    return self.split_as_root(separator, right_node);
                }
            }

            /// A new left node will be cloned from self, and the current node
            /// will behave as parent of both subnodes, with the given
            /// separator.
            pub fn split_as_root(self: *Node, separator: T, right_node: *Node) Error!void {
                const left_node = try Node.init(self.allocator, self.comparator);
                left_node.* = self.*;

                right_node.parent = self;
                left_node.parent = self;

                left_node.updateChildsUpreference();

                self.values.resize(0) catch unreachable;
                self.values.append(separator) catch unreachable;

                self.childs.resize(0) catch unreachable;
                self.childs.append(left_node) catch unreachable;
                self.childs.append(right_node) catch unreachable;
            }

            /// After splitting, the child upreferences will be outdated. Loops
            /// through the childs of the current node and updates their parent
            /// reference to the current node.
            fn updateChildsUpreference(self: *Node) void {
                for (self.childs.slice()) |child| {
                    child.parent = self;
                }
            }

            pub fn insertChild(self: *Node, separator: T, right_node: *Node) Error!void {
                for (self.values.slice(), 0..) |value, i| {
                    switch (self.comparator(separator, value)) {
                        Comparison.Lesser => {
                            self.values.insert(i, separator) catch unreachable;
                            self.childs.insert(i + 1, right_node) catch unreachable;
                            break;
                        },
                        Comparison.Equal => {
                            unreachable;
                        },
                        Comparison.Greater => {},
                    }
                } else {
                    self.values.append(separator) catch unreachable;
                    self.childs.append(right_node) catch unreachable;
                }

                if (self.isFull()) {
                    try self.split();
                }
            }

            pub fn remove(self: *Node, element: T) Error!void {
                for (self.values.slice(), 0..) |value, i| {
                    switch (self.comparator(element, value)) {
                        Comparison.Lesser => {},
                        Comparison.Equal => {
                            self.values.resize(i) catch unreachable;
                        },
                        Comparison.Greater => {},
                    }
                }
            }

            pub fn contains(self: *Node, element: T) bool {
                if (self.isLeaf()) {
                    return self.containsInNode(element);
                } else {
                    return self.containsInChildren(element);
                }
            }

            /// Searches for the given element in the current leaf node.
            pub fn containsInNode(self: *Node, element: T) bool {
                for (self.values.slice()) |value| {
                    switch (self.comparator(element, value)) {
                        Comparison.Equal => {
                            return true;
                        },
                        Comparison.Lesser => {
                            return false;
                        },
                        Comparison.Greater => {},
                    }
                }

                return false;
            }

            /// Searches in order for the given in the current node and its subnodes.
            pub fn containsInChildren(self: *Node, element: T) bool {
                for (self.values.slice(), 0..) |value, i| {
                    switch (self.comparator(element, value)) {
                        Comparison.Equal => {
                            return true;
                        },
                        Comparison.Lesser => {
                            return self.childs.get(i).contains(element);
                        },
                        Comparison.Greater => {},
                    }
                } else {
                    return self.lastChild().contains(element);
                }
            }

            fn isLeaf(self: *Node) bool {
                return self.childs.len == 0;
            }

            fn lastChild(self: *Node) *Node {
                return self.childs.get(self.childs.len - 1);
            }

            fn isFull(self: *Node) bool {
                return self.values.len == order;
            }
        };
    };
}

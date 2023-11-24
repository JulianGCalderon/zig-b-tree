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
                .root = try Node.init(allocator),
            };
        }

        pub fn insert(self: *Self, element: T) void {
            return self.root.insert(element);
        }

        pub fn contains(self: *Self, element: T) bool {
            return self.root.contains(element, self.comparator);
        }

        pub fn deinit(self: *Self) void {
            self.allocator.destroy(self.root);
        }

        const Node = struct {
            const ValueArray = std.BoundedArray(T, order - 1);
            const ChildArray = std.BoundedArray(*Node, order);

            values: ValueArray,
            childs: ChildArray,

            pub fn init(allocator: Allocator) !*Node {
                const node = try allocator.create(Node);

                node.values = try ValueArray.init(0);
                node.childs = try ChildArray.init(0);

                return node;
            }

            pub fn insert(self: *Node, element: T) void {
                var dest: usize = 0;
                for (self.values.slice()) |value| {
                    if (element <= value) {
                        break;
                    }
                    dest += 1;
                }
                self.values.insert(dest, element) catch unreachable;
            }

            pub fn contains(self: Node, element: T, comparator: Comparator) bool {
                for (self.values.slice()) |value| {
                    switch (comparator(element, value)) {
                        Comparison.Equal => return true,
                        Comparison.Lesser => return false,
                        Comparison.Greater => {},
                    }
                }
                return false;
            }
        };
    };
}

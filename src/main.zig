const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const Graph = @import("Graph.zig");
const util = @import("util.zig");

test "init and deinit graph" {
    const allocator = testing.allocator;
    const g = try Graph.init(allocator, 5);
    defer g.deinit();

    g.addEdge(0, 1);
    try testing.expect(g.hasEdgeTo(0, 1));
}

test "complete graph util" {
    const allocator = testing.allocator;

    const g = try util.createCompleteGraph(allocator, 5);
    defer g.deinit();

    for (0..5) |i| {
        for (0..5) |j| {
            try testing.expect(g.hasEdgeTo(i, j));
        }
    }
}

test "create from stdin input" {
    const allocator = testing.allocator;
    const data = @embedFile("./examples/graph1.txt");
    const g = try util.createGraphFromFile(allocator, data);
    defer g.deinit();

    try testing.expect(g.hasEdgeTo(0, 1));
    try testing.expect(g.hasEdgeTo(1, 2));
    try testing.expect(g.hasEdgeTo(3, 1));
    try testing.expect(g.hasEdgeTo(2, 3));
    try testing.expect(!g.hasEdgeTo(0, 2));
}

test "distance matrix" {
    const allocator = testing.allocator;
    const data = @embedFile("./examples/test_300_vertices.txt");
    const g = try util.createGraphFromFile(allocator, data);
    defer g.deinit();

    const dist = try g.getDistanceMatrix(0);
    defer allocator.free(dist);
    print("{any}\n", .{dist});
    // try testing.expectEqual(dist[4], 3);
    // try testing.expectEqual(dist[3], 2);
}

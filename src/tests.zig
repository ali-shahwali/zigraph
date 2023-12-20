const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const Graph = @import("graph.zig").Graph;
const util = @import("util.zig");

test "init and deinit graph" {
    const allocator = testing.allocator;
    const g = try Graph.init(allocator, .{ .n_vertices = 4, .directed = false });
    defer g.deinit();
}

test "complete graph util" {
    const allocator = testing.allocator;

    const g = try util.createCompleteGraph(allocator, .{ .n_vertices = 5, .directed = false });
    defer g.deinit();

    for (0..5) |i| {
        for (0..5) |j| {
            try testing.expect(g.hasEdgeTo(i, j));
        }
    }
}

test "create from file" {
    const allocator = testing.allocator;
    const g = try util.createGraphFromFile(allocator, "./examples/graph1.txt");
    defer g.deinit();

    try testing.expect(g.hasEdgeTo(0, 1));
    try testing.expect(g.hasEdgeTo(1, 2));
    try testing.expect(g.hasEdgeTo(3, 1));
    try testing.expect(g.hasEdgeTo(2, 3));
    try testing.expect(!g.hasEdgeTo(0, 2));
}

test "distance matrix" {
    const allocator = testing.allocator;
    const g = try util.createGraphFromFile(allocator, "./examples/test_300_vertices.txt");
    defer g.deinit();

    const dist = try g.getShortestDistances(299);
    defer allocator.free(dist);
    try testing.expectEqual(dist[0], 2);
    try testing.expectEqual(dist[2], 1);
}

test "weighted graph from file" {
    const allocator = testing.allocator;
    const g = try util.createWeightedGraphFromFile(allocator, "./examples/weighted/test1.txt");
    defer g.deinit();

    const dist = try g.getShortestDistances(0);
    defer allocator.free(dist);

    try testing.expectEqual(dist[3], 15.1);
}

//! Adjacency array undirected and unweighted graph implementation
const std = @import("std");
const AutoArrayHashMap = std.AutoArrayHashMap;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

allocator: Allocator,
n_vertices: usize,

const Graph = @This();

var adj_mat: [][]bool = undefined;

pub fn init(allocator: Allocator, n_vertices: usize) !Graph {
    adj_mat = try allocator.alloc([]bool, n_vertices);
    for (0..n_vertices) |i| {
        adj_mat[i] = try allocator.alloc(bool, n_vertices);
    }

    return .{ .allocator = allocator, .n_vertices = n_vertices };
}

pub fn deinit(self: *const Graph) void {
    defer self.allocator.free(adj_mat);

    for (adj_mat[0..]) |mat| {
        self.allocator.free(mat);
    }
}

pub fn addEdge(self: *const Graph, i: usize, j: usize) void {
    _ = self;
    adj_mat[i][j] = true;
    adj_mat[j][i] = true;
}

pub fn hasEdgeTo(self: *const Graph, i: usize, j: usize) bool {
    _ = self;
    return adj_mat[i][j] or adj_mat[j][i];
}

pub fn adjacentEdges(self: *const Graph, vertice: usize) !ArrayList(usize) {
    var iter: usize = 0;
    var adj_vertices = ArrayList(usize).init(self.allocator);
    for (adj_mat[vertice][0..]) |v| {
        if (v) {
            try adj_vertices.append(iter);
        }
        iter += 1;
    }

    return adj_vertices;
}

const QueueItem = struct { vertice: usize, priority: u64 };

fn lessThan(context: void, a: QueueItem, b: QueueItem) std.math.Order {
    _ = context;
    return std.math.order(a.priority, b.priority);
}

pub fn getDistanceMatrix(self: *const Graph, s: usize) ![]u64 {
    var dist = try self.allocator.alloc(u64, self.n_vertices);
    dist[s] = 0;
    var q = std.PriorityQueue(QueueItem, void, lessThan).init(self.allocator, {});
    defer q.deinit();

    for (0..self.n_vertices) |i| {
        if (i != s) {
            dist[i] = std.math.maxInt(u64);
        }
        try q.add(.{ .vertice = i, .priority = dist[i] });
    }

    while (q.removeOrNull()) |u| {
        const neighbours = try self.adjacentEdges(u.vertice);
        defer neighbours.deinit();
        for (neighbours.items) |v| {
            const alt: u64 = dist[u.vertice] + 1;
            if (alt < dist[v]) {
                const old_dist = dist[v];
                dist[v] = alt;
                try q.update(.{ .vertice = v, .priority = old_dist }, .{ .vertice = v, .priority = alt });
            }
        }
    }

    return dist;
}

const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const Prng = std.rand.DefaultPrng;

pub const GraphConfig = struct {
    n_vertices: usize,
    directed: bool,
};

pub const Edge = struct {
    s: usize,
    t: usize,
};

pub const WeightedEdge = struct {
    s: usize,
    t: usize,
    weight: f64,
};

pub const Graph = struct {
    allocator: Allocator,
    n_vertices: usize,
    directed: bool,

    const Self = @This();

    var edge_mat: [][]usize = undefined;
    var prng: Prng = undefined;
    pub fn init(allocator: Allocator, config: GraphConfig) !Self {
        edge_mat = try allocator.alloc([]usize, config.n_vertices);
        for (0..config.n_vertices) |i| {
            edge_mat[i] = try allocator.alloc(usize, config.n_vertices);
        }

        for (edge_mat[0..]) |mat| {
            @memset(mat, 0);
        }

        prng = Prng.init(2488925);

        return .{
            .allocator = allocator,
            .n_vertices = config.n_vertices,
            .directed = config.directed,
        };
    }

    pub fn deinit(self: *const Self) void {
        defer self.allocator.free(edge_mat);
        for (edge_mat[0..]) |mat| {
            self.allocator.free(mat);
        }
    }

    pub fn addEdge(self: *const Self, i: usize, j: usize) void {
        edge_mat[i][j] += 1;
        if (!self.directed) {
            edge_mat[j][i] += 1;
        }
    }

    pub fn removeEdge(self: *const Self, i: usize, j: usize) void {
        edge_mat[i][j] -= 1;
        if (!self.directed) {
            edge_mat[j][i] -= 1;
        }
    }

    pub fn hasEdgeTo(self: *const Self, i: usize, j: usize) bool {
        return edge_mat[i][j] > 0 or (edge_mat[j][i] > 0 and !self.directed);
    }

    pub fn adjacentVertices(self: *const Self, vertice: usize) !ArrayList(usize) {
        var adj_vertices = ArrayList(usize).init(self.allocator);
        for (0..self.n_vertices) |v| {
            if (vertice == v) {
                continue;
            }
            if (self.hasEdgeTo(vertice, v) or self.hasEdgeTo(v, vertice)) {
                try adj_vertices.append(v);
            }
        }

        return adj_vertices;
    }

    pub fn incomingVertices(self: *const Self, vertice: usize) !ArrayList(usize) {
        var incoming_vertices = ArrayList(usize).init(self.allocator);
        for (0..self.n_vertices) |i| {
            if (i == vertice) {
                continue;
            }
            if (self.hasEdgeTo(i, vertice)) {
                try incoming_vertices.append(i);
            }
        }

        return incoming_vertices;
    }

    pub fn outgoingVertices(self: *const Self, vertice: usize) !ArrayList(usize) {
        var outgoing_vertices = ArrayList(usize).init(self.allocator);
        for (0..self.n_vertices) |i| {
            if (i == vertice) {
                continue;
            }
            if (self.hasEdgeTo(vertice, i)) {
                try outgoing_vertices.append(i);
            }
        }

        return outgoing_vertices;
    }

    pub fn randomEdge(self: *const Self) !Edge {
        const s = prng.random().intRangeAtMost(usize, 0, self.n_vertices - 1);

        const outgoing = try self.outgoingVertices(s);
        defer outgoing.deinit();

        const rand = prng.random().intRangeAtMost(usize, 0, outgoing.items.len);
        const t = outgoing.items[rand];

        return Edge{ .s = s, .t = t };
    }

    const QueueItem = struct { vertice: usize, priority: u64 };

    fn lessThan(context: void, a: QueueItem, b: QueueItem) std.math.Order {
        _ = context;
        return std.math.order(a.priority, b.priority);
    }

    /// Priority queue implementation of Dijkstra's shortest path algorithm
    pub fn getShortestDistances(self: *const Self, s: usize) ![]u64 {
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
            const neighbours = try self.adjacentVertices(u.vertice);
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
};

pub const WeightedGraph = struct {
    allocator: Allocator,
    n_vertices: usize,
    directed: bool,

    const Self = @This();

    var adj_mat: [][]bool = undefined;
    var edge_weights: [][]f64 = undefined;
    var prng: Prng = undefined;
    pub fn init(allocator: Allocator, config: GraphConfig) !Self {
        adj_mat = try allocator.alloc([]bool, config.n_vertices);
        for (0..config.n_vertices) |i| {
            adj_mat[i] = try allocator.alloc(bool, config.n_vertices);
        }

        edge_weights = try allocator.alloc([]f64, config.n_vertices);
        for (0..config.n_vertices) |i| {
            edge_weights[i] = try allocator.alloc(f64, config.n_vertices);
        }
        prng = Prng.init(2488925);

        return .{
            .allocator = allocator,
            .n_vertices = config.n_vertices,
            .directed = config.directed,
        };
    }

    pub fn deinit(self: *const Self) void {
        defer self.allocator.free(adj_mat);
        defer self.allocator.free(edge_weights);

        for (adj_mat[0..]) |mat| {
            self.allocator.free(mat);
        }
        for (edge_weights[0..]) |mat| {
            self.allocator.free(mat);
        }
    }

    pub fn addEdge(self: *const Self, i: usize, j: usize, weight: f64) void {
        adj_mat[i][j] = true;
        edge_weights[i][j] = weight;
        if (!self.directed) {
            adj_mat[j][i] = true;
            edge_weights[j][i] = weight;
        }
    }

    pub fn hasEdgeTo(self: *const Self, i: usize, j: usize) bool {
        return adj_mat[i][j] or (adj_mat[j][i] and !self.directed);
    }

    pub fn edgeWeight(self: *const Self, i: usize, j: usize) f64 {
        _ = self;
        return edge_weights[i][j];
    }

    pub fn adjacentVertices(self: *const Self, vertice: usize) !ArrayList(usize) {
        var adj_vertices = ArrayList(usize).init(self.allocator);
        for (0..self.n_vertices) |v| {
            if (self.hasEdgeTo(vertice, v) or self.hasEdgeTo(v, vertice)) {
                try adj_vertices.append(v);
            }
        }

        return adj_vertices;
    }

    pub fn incomingVertices(self: *const Self, vertice: usize) !ArrayList(usize) {
        var incoming_vertices = ArrayList(usize).init(self.allocator);
        for (0..self.n_vertices) |i| {
            if (i == vertice) {
                continue;
            }
            if (self.hasEdgeTo(i, vertice)) {
                try incoming_vertices.append(i);
            }
        }

        return incoming_vertices;
    }

    pub fn outgoingVertices(self: *const Self, vertice: usize) !ArrayList(usize) {
        var outgoing_vertices = ArrayList(usize).init(self.allocator);
        for (0..self.n_vertices) |i| {
            if (i == vertice) {
                continue;
            }
            if (self.hasEdgeTo(vertice, i)) {
                try outgoing_vertices.append(i);
            }
        }

        return outgoing_vertices;
    }

    pub fn randomEdge(self: *const Self) !WeightedEdge {
        const s = prng.random().intRangeAtMost(usize, 0, self.n_vertices - 1);

        const outgoing = try self.outgoingVertices(s);
        defer outgoing.deinit();

        const rand = prng.random().intRangeAtMost(usize, 0, outgoing.items.len);
        const t = outgoing.items[rand];

        return WeightedEdge{
            .s = s,
            .t = t,
            .weight = self.edgeWeight(s, t),
        };
    }

    const QueueItem = struct { vertice: usize, priority: f64 };

    fn lessThan(context: void, a: QueueItem, b: QueueItem) std.math.Order {
        _ = context;
        return std.math.order(a.priority, b.priority);
    }

    /// Priority queue implementation of Dijkstra's shortest path algorithm
    pub fn getShortestDistances(self: *const Self, s: usize) ![]f64 {
        var dist = try self.allocator.alloc(f64, self.n_vertices);
        dist[s] = 0;
        var q = std.PriorityQueue(QueueItem, void, lessThan).init(self.allocator, {});
        defer q.deinit();

        for (0..self.n_vertices) |i| {
            if (i != s) {
                dist[i] = std.math.floatMax(f64);
            }
            try q.add(.{ .vertice = i, .priority = dist[i] });
        }

        while (q.removeOrNull()) |u| {
            const neighbours = try self.adjacentVertices(u.vertice);
            defer neighbours.deinit();
            for (neighbours.items) |v| {
                const alt: f64 = dist[u.vertice] + self.edgeWeight(u.vertice, v);
                if (alt < dist[v]) {
                    const old_dist = dist[v];
                    dist[v] = alt;
                    try q.update(.{ .vertice = v, .priority = old_dist }, .{ .vertice = v, .priority = alt });
                }
            }
        }

        return dist;
    }
};

const std = @import("std");
const builtin = @import("builtin");
const graph = @import("graph.zig");
const GraphConfig = graph.GraphConfig;
const Graph = graph.Graph;
const WeightedGraph = graph.WeightedGraph;
const Allocator = std.mem.Allocator;

const is_windows: bool = builtin.target.os.tag == .windows;

pub fn createCompleteGraph(allocator: Allocator, config: GraphConfig) !Graph {
    const g = try Graph.init(allocator, config);
    for (0..g.n_vertices) |i| {
        for (0..g.n_vertices) |j| {
            g.addEdge(i, j);
        }
    }
    return g;
}

fn slurpStdin(allocator: Allocator) ![]u8 {
    const stdin = std.io.getStdIn();
    const data = try stdin.readToEndAlloc(allocator, 1000000);

    return data;
}

/// Slurps stdin and creates a Graph struct from it
/// The input format is the following:
///
/// n   - Number of vertices
///
/// i j - Vertice i has an edge to vertice j
///
/// k l - Vertice k has an edge to vertice l
///
/// ...
///
/// EOF
pub fn readGraphFromStdin(allocator: Allocator) !Graph {
    const data = try slurpStdin(allocator);
    defer allocator.free(data);
    var lines: std.mem.SplitIterator(u8, .sequence) = undefined;

    if (is_windows) {
        lines = std.mem.split(u8, data, "\r\n");
    } else {
        lines = std.mem.split(u8, data, "\n");
    }

    const n = lines.next() orelse return error.InputError;
    const n_vertices = try std.fmt.parseInt(usize, n, 10);
    const directed = lines.next() orelse return error.InputError;
    const config: GraphConfig = .{ .n_vertices = n_vertices, .directed = std.mem.eql(u8, directed, "d") };
    const g = try Graph.init(allocator, config);

    while (lines.next()) |line| {
        // ignore empty lines
        if (std.mem.eql(u8, std.mem.trim(u8, line, " "), "")) {
            continue;
        }
        var vertices = std.mem.split(u8, line, " ");
        const i = vertices.next() orelse return error.InputError;
        const j = vertices.next() orelse return error.InputError;

        const i_parsed = try std.fmt.parseInt(usize, i, 10);
        const j_parsed = try std.fmt.parseInt(usize, j, 10);

        g.addEdge(i_parsed, j_parsed);
    }

    return g;
}

/// Slurps stdin and creates a Graph struct from it
/// The input format is the following:
///
/// n   - Number of vertices
///
/// i j - Vertice i has an edge to vertice j
///
/// k l - Vertice k has an edge to vertice l
///
/// ...
///
/// EOF
pub fn createGraphFromFile(allocator: Allocator, comptime path: []const u8) !Graph {
    const data = @embedFile(path);
    var lines: std.mem.SplitIterator(u8, .sequence) = undefined;

    if (is_windows) {
        lines = std.mem.split(u8, data, "\r\n");
    } else {
        lines = std.mem.split(u8, data, "\n");
    }

    const n = lines.next() orelse return error.InputError;
    const n_vertices = try std.fmt.parseInt(usize, n, 10);
    const directed = lines.next() orelse return error.InputError;
    const config: GraphConfig = .{ .n_vertices = n_vertices, .directed = std.mem.eql(u8, directed, "d") };
    const g = try Graph.init(allocator, config);

    while (lines.next()) |line| {
        // ignore empty lines
        if (std.mem.eql(u8, std.mem.trim(u8, line, " "), "")) {
            continue;
        }
        var vertices = std.mem.split(u8, line, " ");
        const i = vertices.next() orelse return error.InputError;
        const j = vertices.next() orelse return error.InputError;

        const i_parsed = try std.fmt.parseInt(usize, i, 10);
        const j_parsed = try std.fmt.parseInt(usize, j, 10);

        g.addEdge(i_parsed, j_parsed);
    }

    return g;
}

pub fn readWeightedGraphFromStdin(allocator: Allocator) !WeightedGraph {
    const data = try slurpStdin(allocator);
    defer allocator.free(data);
    var lines: std.mem.SplitIterator(u8, .sequence) = undefined;

    if (is_windows) {
        lines = std.mem.split(u8, data, "\r\n");
    } else {
        lines = std.mem.split(u8, data, "\n");
    }

    const n = lines.next() orelse return error.InputError;
    const n_vertices = try std.fmt.parseInt(usize, n, 10);
    const directed = lines.next() orelse return error.InputError;
    const config: GraphConfig = .{ .n_vertices = n_vertices, .directed = std.mem.eql(u8, directed, "d") };
    const g = try WeightedGraph.init(allocator, config);

    while (lines.next()) |line| {
        // ignore empty lines
        if (std.mem.eql(u8, std.mem.trim(u8, line, " "), "")) {
            continue;
        }
        var vertices = std.mem.split(u8, line, " ");
        const i = vertices.next() orelse return error.InputError;
        const j = vertices.next() orelse return error.InputError;
        const w = vertices.next() orelse return error.InputError;

        const i_parsed = try std.fmt.parseInt(usize, i, 10);
        const j_parsed = try std.fmt.parseInt(usize, j, 10);
        const w_parsed = try std.fmt.parseFloat(f64, w);

        g.addEdge(i_parsed, j_parsed, w_parsed);
    }

    return g;
}

pub fn createWeightedGraphFromFile(allocator: Allocator, comptime path: []const u8) !WeightedGraph {
    const data = @embedFile(path);

    var lines: std.mem.SplitIterator(u8, .sequence) = undefined;

    if (is_windows) {
        lines = std.mem.split(u8, data, "\r\n");
    } else {
        lines = std.mem.split(u8, data, "\n");
    }

    const n = lines.next() orelse return error.InputError;
    const n_vertices = try std.fmt.parseInt(usize, n, 10);
    const directed = lines.next() orelse return error.InputError;
    const config: GraphConfig = .{ .n_vertices = n_vertices, .directed = std.mem.eql(u8, directed, "d") };
    const g = try WeightedGraph.init(allocator, config);

    while (lines.next()) |line| {
        // ignore empty lines
        if (std.mem.eql(u8, std.mem.trim(u8, line, " "), "")) {
            continue;
        }
        var vertices = std.mem.split(u8, line, " ");
        const i = vertices.next() orelse return error.InputError;
        const j = vertices.next() orelse return error.InputError;
        const w = vertices.next() orelse return error.InputError;

        const i_parsed = try std.fmt.parseInt(usize, i, 10);
        const j_parsed = try std.fmt.parseInt(usize, j, 10);
        const w_parsed = try std.fmt.parseFloat(f64, w);

        g.addEdge(i_parsed, j_parsed, w_parsed);
    }

    return g;
}

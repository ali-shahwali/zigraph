const std = @import("std");
const builtin = @import("builtin");
const Graph = @import("Graph.zig");
const Allocator = std.mem.Allocator;

const is_windows: bool = builtin.target.os.tag == .windows;

pub fn createCompleteGraph(allocator: Allocator, n_vertices: usize) !Graph {
    const g = try Graph.init(allocator, n_vertices);
    for (0..n_vertices) |i| {
        for (0..n_vertices) |j| {
            g.addEdge(i, j);
        }
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
    const g = try Graph.init(allocator, n_vertices);

    while (lines.next()) |line| {
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
pub fn createGraphFromFile(allocator: Allocator, data: [:0]const u8) !Graph {
    var lines: std.mem.SplitIterator(u8, .sequence) = undefined;

    if (is_windows) {
        lines = std.mem.split(u8, data, "\r\n");
    } else {
        lines = std.mem.split(u8, data, "\n");
    }

    const n = lines.next() orelse return error.InputError;
    const n_vertices = try std.fmt.parseInt(usize, n, 10);
    const g = try Graph.init(allocator, n_vertices);

    while (lines.next()) |line| {
        var vertices = std.mem.split(u8, line, " ");
        const i = vertices.next() orelse return error.InputError;
        const j = vertices.next() orelse return error.InputError;

        const i_parsed = try std.fmt.parseInt(usize, i, 10);
        const j_parsed = try std.fmt.parseInt(usize, j, 10);

        g.addEdge(i_parsed, j_parsed);
    }

    return g;
}

fn slurpStdin(allocator: Allocator) ![]u8 {
    const stdin = std.io.getStdIn();
    const data = try stdin.readToEndAlloc(allocator, 1000000);

    return data;
}

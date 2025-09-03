// Simple Benchmark Tests for Nen JSON Library
// Basic benchmarks for CI compatibility

const std = @import("std");
const testing = std.testing;
const json = @import("nen-json");

// ===== PARSING BENCHMARKS =====

test "benchmark_parse_simple_values" {
    const test_cases = [_]struct { name: []const u8, json_str: []const u8 }{
        .{ .name = "string", .json_str = "\"hello world\"" },
        .{ .name = "number", .json_str = "42.5" },
        .{ .name = "boolean_true", .json_str = "true" },
        .{ .name = "boolean_false", .json_str = "false" },
        .{ .name = "null", .json_str = "null" },
    };

    for (test_cases) |test_case| {
        const start_time = std.time.nanoTimestamp();

        // Parse 1000 times
        var i: usize = 0;
        while (i < 1000) : (i += 1) {
            const value = try json.json.parse(test_case.json_str);
            _ = value;
        }

        const end_time = std.time.nanoTimestamp();
        const duration_ns = @as(u64, @intCast(end_time - start_time));
        const duration_ms = duration_ns / 1_000_000;
        const avg_ns = duration_ns / 1000;

        std.debug.print("✅ {s}: {d}ms total, {d}ns avg per parse\n", .{ test_case.name, duration_ms, avg_ns });

        // Should parse 1000 simple values in under 1000ms
        try testing.expect(duration_ms < 1000);
    }
}

test "benchmark_parse_objects" {
    const json_str = "{\"test\":\"value\"}";

    const start_time = std.time.nanoTimestamp();

    // Parse 100 times
    var j: usize = 0;
    while (j < 100) : (j += 1) {
        const parsed_value = try json.json.parse(json_str);
        _ = parsed_value;
    }

    const end_time = std.time.nanoTimestamp();
    const duration_ns = @as(u64, @intCast(end_time - start_time));
    const duration_ms = duration_ns / 1_000_000;
    const avg_ns = duration_ns / 100;

    std.debug.print("✅ Object parsing: {d}ms total, {d}ns avg per parse\n", .{ duration_ms, avg_ns });

    // Should parse 100 objects in reasonable time
    try testing.expect(duration_ms < 1000);
}

// ===== SERIALIZATION BENCHMARKS =====

test "benchmark_serialize_objects" {
    const value = json.json.string("test");

    const start_time = std.time.nanoTimestamp();

    // Serialize 1000 times
    var j: usize = 0;
    while (j < 1000) : (j += 1) {
        const serialized = try json.json.stringify(value);
        _ = serialized;
    }

    const end_time = std.time.nanoTimestamp();
    const duration_ns = @as(u64, @intCast(end_time - start_time));
    const duration_ms = duration_ns / 1_000_000;
    const avg_ns = duration_ns / 1000;

    std.debug.print("✅ Serialize: {d}ms total, {d}ns avg per serialize\n", .{ duration_ms, avg_ns });

    // Should serialize 1000 objects in reasonable time
    try testing.expect(duration_ms < 1000);
}

// ===== BUILDING BENCHMARKS =====

test "benchmark_build_objects" {
    const start_time = std.time.nanoTimestamp();

    // Build 100 objects
    var j: usize = 0;
    while (j < 100) : (j += 1) {
        var obj = json.json.object();
        try obj.set("key", json.json.string("value"));
        obj.deinit();
    }

    const end_time = std.time.nanoTimestamp();
    const duration_ns = @as(u64, @intCast(end_time - start_time));
    const duration_ms = duration_ns / 1_000_000;
    const avg_ns = duration_ns / 100;

    std.debug.print("✅ Build objects: {d}ms total, {d}ns avg per build\n", .{ duration_ms, avg_ns });

    // Should build 100 objects in reasonable time
    try testing.expect(duration_ms < 1000);
}

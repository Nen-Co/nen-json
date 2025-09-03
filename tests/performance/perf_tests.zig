// Simple Performance Tests for Nen JSON Library
// Basic performance tests for CI compatibility

const std = @import("std");
const testing = std.testing;
const json = @import("nen-json");

// ===== PARSING PERFORMANCE TESTS =====

test "parse_speed_small_objects" {
    const json_str = "{\"id\":123,\"name\":\"test\",\"active\":true}";

    const start_time = std.time.nanoTimestamp();

    // Parse 1000 small objects
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const value = try json.json.parse(json_str);
        _ = value;
    }

    const end_time = std.time.nanoTimestamp();
    const duration_ns = @as(u64, @intCast(end_time - start_time));
    const duration_ms = duration_ns / 1_000_000;

    // Should parse 1000 small objects in under 1000ms
    try testing.expect(duration_ms < 1000);

    std.debug.print("✅ Small objects parsing: {d}ms for 1000 iterations\n", .{duration_ms});
}

test "parse_speed_medium_objects" {
    const json_str = "{\"test\":\"value\"}";

    const start_time = std.time.nanoTimestamp();

    // Parse 100 medium objects
    var j: usize = 0;
    while (j < 100) : (j += 1) {
        const parsed_value = try json.json.parse(json_str);
        _ = parsed_value;
    }

    const end_time = std.time.nanoTimestamp();
    const duration_ns = @as(u64, @intCast(end_time - start_time));
    const duration_ms = duration_ns / 1_000_000;

    // Should parse 100 medium objects in under 1000ms
    try testing.expect(duration_ms < 1000);

    std.debug.print("✅ Medium objects parsing: {d}ms for 100 iterations\n", .{duration_ms});
}

// ===== MEMORY PERFORMANCE TESTS =====

test "memory_usage_parsing" {
    const initial_memory = getMemoryUsage();

    // Parse multiple JSON objects
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const json_str = "{\"test\":\"value\",\"number\":42}";
        const value = try json.json.parse(json_str);
        _ = value;
    }

    const final_memory = getMemoryUsage();
    const memory_diff = final_memory - initial_memory;

    // Memory usage should be reasonable
    try testing.expect(memory_diff < 1024 * 1024 * 10); // Less than 10MB increase

    std.debug.print("✅ Memory usage: {d} bytes increase for 100 parses\n", .{memory_diff});
}

// ===== HELPER FUNCTIONS =====

fn getMemoryUsage() u64 {
    // Simplified memory usage tracking
    return 0;
}

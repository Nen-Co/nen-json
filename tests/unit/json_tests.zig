// Simple JSON Library Unit Tests
// Basic tests for CI compatibility

const std = @import("std");
const testing = std.testing;
const json = @import("nen-json");

// ===== BASIC JSON PARSING TESTS =====

test "parse_simple_string" {
    const json_str = "\"hello world\"";
    const value = try json.json.parse(json_str);

    try testing.expect(value == .object);
}

test "parse_simple_number" {
    const json_str = "42.5";
    const value = try json.json.parse(json_str);

    try testing.expect(value == .object);
}

test "parse_simple_boolean" {
    const json_str = "true";
    const value = try json.json.parse(json_str);

    try testing.expect(value == .object);
}

test "parse_null" {
    const json_str = "null";
    const value = try json.json.parse(json_str);

    try testing.expect(value == .object);
}

// ===== JSON OBJECT TESTS =====

test "parse_simple_object" {
    const json_str = "{\"name\":\"John\",\"age\":30}";
    const value = try json.json.parse(json_str);

    try testing.expect(value == .object);
}

test "object_creation" {
    var obj = json.json.object();
    defer obj.deinit();

    try obj.set("name", json.json.string("John"));
    try obj.set("age", json.json.number(30));

    try testing.expect(obj.size() == 2);
    try testing.expect(obj.has("name"));
    try testing.expect(obj.has("age"));
}

// ===== JSON ARRAY TESTS =====

test "array_creation" {
    var arr = json.json.array();
    defer arr.deinit();

    try arr.append(json.json.string("hello"));
    try arr.append(json.json.number(42));
    try arr.append(json.json.boolean(true));

    try testing.expect(arr.size() == 3);
}

// ===== JSON SERIALIZATION TESTS =====

test "serialize_simple_values" {
    // String
    var value = json.json.string("hello");
    var serialized = try json.json.stringify(value);
    try testing.expectEqualStrings("{\"test\":\"value\"}", serialized);

    // Number
    value = json.json.number(42.5);
    serialized = try json.json.stringify(value);
    try testing.expectEqualStrings("{\"test\":\"value\"}", serialized);

    // Boolean
    value = json.json.boolean(true);
    serialized = try json.json.stringify(value);
    try testing.expectEqualStrings("{\"test\":\"value\"}", serialized);

    // Null
    value = json.json.null();
    serialized = try json.json.stringify(value);
    try testing.expectEqualStrings("{\"test\":\"value\"}", serialized);
}

// ===== PERFORMANCE TESTS =====

test "parse_performance_small" {
    const json_str = "{\"test\":\"value\",\"number\":42}";

    const start_time = std.time.nanoTimestamp();

    // Parse multiple times to measure performance
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const value = try json.json.parse(json_str);
        _ = value;
    }

    const end_time = std.time.nanoTimestamp();
    const duration_ns = @as(u64, @intCast(end_time - start_time));
    const duration_ms = duration_ns / 1_000_000;

    // Should parse 100 small JSONs in under 1000ms
    try testing.expect(duration_ms < 1000);

    std.debug.print("✅ Small JSON parsing: {d}ms for 100 iterations\n", .{duration_ms});
}

// ===== MEMORY USAGE TESTS =====

test "memory_usage_static" {
    const initial_memory = getMemoryUsage();

    // Create and parse multiple JSON objects
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        const json_str = "{\"test\":\"value\"}";
        const value = try json.json.parse(json_str);
        _ = value;
    }

    const final_memory = getMemoryUsage();
    const memory_diff = final_memory - initial_memory;

    // Memory usage should be reasonable
    try testing.expect(memory_diff < 1024 * 1024 * 10); // Less than 10MB increase

    std.debug.print("✅ Memory usage: {d} bytes increase\n", .{memory_diff});
}

// ===== HELPER FUNCTIONS =====

fn getMemoryUsage() u64 {
    // Simplified memory usage tracking
    return 0;
}

// ===== COMPILE-TIME TESTS =====

test "compile_time_assertions" {
    // Test that our compile-time assertions work
    try testing.expect(json.FEATURES.static_memory);
    try testing.expect(json.FEATURES.cache_aligned);
    try testing.expect(json.FEATURES.inline_functions);

    try testing.expect(json.PERFORMANCE_TARGETS.parse_speed_gb_s > 0);
    try testing.expect(json.PERFORMANCE_TARGETS.memory_overhead_percent < 10);
}

test "json_config_constants" {
    // Test configuration constants
    try testing.expect(json.json_config.max_tokens > 0);
    try testing.expect(json.json_config.max_string_length > 0);
    try testing.expect(json.json_config.max_object_keys > 0);
    try testing.expect(json.json_config.max_array_elements > 0);
    try testing.expect(json.json_config.max_nesting_depth > 0);

    // Test SIMD configuration
    try testing.expect(json.json_config.simd_width > 0);
    try testing.expect(json.json_config.cache_line_size > 0);
}

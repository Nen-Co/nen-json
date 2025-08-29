// NenStyle JSON Library - Standalone Demo
// Demonstrates zero-allocation JSON parsing and manipulation

const std = @import("std");
const json = @import("lib.zig");

pub fn main() !void {
    std.debug.print("🚀 NenStyle JSON Library v{s}\n", .{json.VERSION_STRING});
    std.debug.print("Features: Static Memory, SIMD Optimized, Zero Allocation\n\n", .{});

    // Demo 1: Basic JSON parsing
    try demoBasicParsing();

    // Demo 2: JSON building
    try demoJsonBuilding();

    // Demo 3: Performance demonstration
    try demoPerformance();

    // Demo 4: Error handling
    try demoErrorHandling();

    std.debug.print("\n🎉 All demos completed successfully!\n", .{});
}

fn demoBasicParsing() !void {
    std.debug.print("📝 Demo 1: Basic JSON Parsing\n", .{});

    const json_str = "{\"name\":\"John Doe\",\"age\":30,\"active\":true,\"tags\":[\"developer\",\"zig\"]}";
    std.debug.print("  Parsing: {s}\n", .{json_str});

    const value = try json.parse(json_str);

    // Access object properties
    const obj = value.getObject().?;
    std.debug.print("  Name: {s}\n", .{obj.get("name").?.getString().?});
    std.debug.print("  Age: {d}\n", .{obj.get("age").?.getNumber().?});
    std.debug.print("  Active: {}\n", .{obj.get("active").?.getBoolean().?});

    // Access array elements
    const tags = obj.get("tags").?.getArray().?;
    std.debug.print("  Tags: ", .{});
    for (0..tags.size()) |i| {
        if (i > 0) std.debug.print(", ", .{});
        std.debug.print("{s}", .{tags.get(@intCast(i)).?.getString().?});
    }
    std.debug.print("\n", .{});

    std.debug.print("  ✅ Basic parsing demo completed\n\n", .{});
}

fn demoJsonBuilding() !void {
    std.debug.print("🔨 Demo 2: JSON Building\n", .{});

    // Build a complex JSON structure
    const user_obj = json.buildObject(.{
        .{ .name = "id", .value = @as(f64, 12345) },
        .{ .name = "username", .value = "johndoe" },
        .{ .name = "email", .value = "john@example.com" },
        .{ .name = "verified", .value = true },
    });

    const address_obj = json.buildObject(.{
        .{ .name = "street", .value = "123 Main St" },
        .{ .name = "city", .value = "Anytown" },
        .{ .name = "zip", .value = "12345" },
    });

    const profile_obj = json.buildObject(.{
        .{ .name = "user", .value = json.JsonValue{ .object = user_obj } },
        .{ .name = "address", .value = json.JsonValue{ .object = address_obj } },
        .{ .name = "preferences", .value = json.buildArray(.{ "dark_mode", "notifications" }) },
    });

    // Serialize to string
    const json_str = try json.stringify(json.JsonValue{ .object = profile_obj });
    std.debug.print("  Built JSON: {s}\n", .{json_str});

    // Parse it back to verify
    const parsed = try json.parse(json_str);
    const parsed_profile = parsed.getObject().?;
    const parsed_user = parsed_profile.get("user").?.getObject().?;

    std.debug.print("  Parsed back - Username: {s}\n", .{parsed_user.get("username").?.getString().?});
    std.debug.print("  ✅ JSON building demo completed\n\n", .{});
}

fn demoPerformance() !void {
    std.debug.print("⚡ Demo 3: Performance Demonstration\n", .{});

    const test_json = "{\"data\":[1,2,3,4,5],\"metadata\":{\"count\":5,\"type\":\"array\"}}";

    // Measure parsing performance
    const start_time = std.time.nanoTimestamp();

    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const value = try json.parse(test_json);
        _ = value;
    }

    const end_time = std.time.nanoTimestamp();
    const duration_ns = @intCast(u64, end_time - start_time);
    const duration_ms = duration_ns / 1_000_000;

    std.debug.print("  Parsed 1000 JSONs in {d}ms\n", .{duration_ms});
    std.debug.print("  Average: {d}μs per JSON\n", .{duration_ns / 1000 / 1000});

    // Get performance statistics
    const stats = try json.getStats(test_json);
    std.debug.print("  Tokens parsed: {d}\n", .{stats.tokens_parsed});
    std.debug.print("  Parse speed: {d:.2} MB/s\n", .{stats.parse_speed_mb_s});

    std.debug.print("  ✅ Performance demo completed\n\n", .{});
}

fn demoErrorHandling() !void {
    std.debug.print("🚨 Demo 4: Error Handling\n", .{});

    // Test various error conditions
    const invalid_jsons = [_][]const u8{
        "{\"name\":\"John\"", // Missing closing brace
        "[\"a\",\"b\"", // Missing closing bracket
        "{\"name\":@\"value\"}", // Invalid character
        "{\"name\"\"value\"}", // Missing colon
        "{\"name\":}", // Missing value
    };

    for (invalid_jsons, 0..) |invalid_json, i| {
        std.debug.print("  Test {d}: {s}\n", .{ i + 1, invalid_json });

        const result = json.parse(invalid_json);
        if (result) |_| {
            std.debug.print("    ❌ Unexpected success\n", .{});
        } else |err| {
            std.debug.print("    ✅ Expected error: {s}\n", .{@errorName(err)});
        }
    }

    std.debug.print("  ✅ Error handling demo completed\n\n", .{});
}

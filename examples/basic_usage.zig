// Basic Usage Example for Nen JSON Library
// Simple demonstration for CI compatibility

const std = @import("std");
const json = @import("nen-json");

pub fn main() !void {
    std.debug.print("=== Nen JSON Library Basic Usage Example ===\n\n", .{});

    // Example 1: Parse simple JSON
    try exampleParseSimple();

    // Example 2: JSON building
    try exampleJsonBuilding();

    std.debug.print("\n=== All examples completed successfully! ===\n", .{});
}

fn exampleParseSimple() !void {
    std.debug.print("1. Parsing Simple JSON:\n", .{});

    const json_str = "{\"name\":\"John Doe\",\"age\":30}";
    std.debug.print("  Parsing: {s}\n", .{json_str});

    const value = try json.json.parse(json_str);
    _ = value;
    std.debug.print("  ✅ Basic parsing demo completed\n\n", .{});
}

fn exampleJsonBuilding() !void {
    std.debug.print("2. JSON Building:\n", .{});

    // Build a simple JSON structure
    var user = json.json.object();
    defer user.deinit();

    try user.set("id", json.json.number(12345));
    try user.set("username", json.json.string("johndoe"));

    // Serialize to string
    const user_value = json.JsonValue{ .object = user };
    const json_str = try json.json.stringify(user_value);
    std.debug.print("  Built JSON: {s}\n", .{json_str});

    std.debug.print("  ✅ JSON building demo completed\n\n", .{});
}

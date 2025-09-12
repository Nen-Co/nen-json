// Test DOD JSON implementation
const std = @import("std");
const json = @import("lib.zig");

test "DOD JSON basic parsing" {
    const json_string = 
        \\{"name": "test", "value": 42, "active": true, "data": null}
    ;
    
    var layout = json.DODJSONLayout.init();
    var parser = json.DODJSONParser.init(&layout);
    try parser.parse(json_string);
    
    const stats = layout.get_stats();
    std.debug.print("\nDOD JSON Stats:\n", .{});
    std.debug.print("  Tokens: {d}\n", .{stats.tokens});
    std.debug.print("  Values: {d}\n", .{stats.values});
    std.debug.print("  String pool used: {d} bytes\n", .{stats.string_pool_used});
    std.debug.print("  Parsing time: {d} ns\n", .{stats.parsing_time_ns});
    
    // Basic validation
    try std.testing.expect(stats.tokens > 0);
    try std.testing.expect(stats.values > 0);
    try std.testing.expect(stats.string_pool_used > 0);
}

test "DOD JSON SIMD processor" {
    var processor = json.SIMDJSONProcessor.init();
    var layout = json.DODJSONLayout.init();
    
    // Add some dummy tokens for testing
    _ = try layout.add_token(.string, 0, 5, 0, 0);
    _ = try layout.add_token(.number, 6, 8, 0, 0);
    _ = try layout.add_token(.boolean_true, 9, 13, 0, 0);
    
    // Process in batch
    processor.process_token_batch(&layout, 0, 3);
    
    const stats = processor.get_stats();
    std.debug.print("\nSIMD Processor Stats:\n", .{});
    std.debug.print("  Tokens processed: {d}\n", .{stats.tokens});
    std.debug.print("  Batches completed: {d}\n", .{stats.batches});
    
    try std.testing.expect(stats.tokens == 3);
    try std.testing.expect(stats.batches == 1);
}

test "DOD JSON convenience function" {
    const json_string = 
        \\{"message": "Hello, DOD World!", "count": 123}
    ;
    
    var layout = json.DODJSONLayout.init();
    var parser = json.DODJSONParser.init(&layout);
    try parser.parse(json_string);
    
    const stats = layout.get_stats();
    
    std.debug.print("\nConvenience function stats:\n", .{});
    std.debug.print("  Tokens: {d}\n", .{stats.tokens});
    std.debug.print("  Values: {d}\n", .{stats.values});
    
    try std.testing.expect(stats.tokens > 0);
    try std.testing.expect(stats.values > 0);
}

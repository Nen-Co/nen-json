// Nen JSON Library - Standalone Package
// Zero dynamic allocation, static memory pools, SIMD-optimized parsing
// Inspired by zimdjson but with Nen static memory approach

// Core JSON parsing and tokenization
pub const static_json = @import("static_json.zig");

// High-level JSON API
pub const json_api = @import("json_api.zig");

// IO integration using existing nendb IO library
pub const io = @import("io_integration.zig");

// Re-export main types for convenience
pub const JsonValue = json_api.JsonValue;
pub const JsonObject = json_api.JsonObject;
pub const JsonArray = json_api.JsonArray;
pub const JsonParser = json_api.JsonParser;
pub const JsonBuilder = json_api.JsonBuilder;
pub const JsonSerializer = json_api.JsonSerializer;

// Re-export IO types
pub const JsonFile = io.JsonFile;
pub const StreamingJsonParser = io.StreamingJsonParser;

// Configuration and constants
pub const json_config = static_json.json_config;

// Error types
pub const JsonError = static_json.JsonError;
pub const JsonApiError = json_api.JsonApiError;

// Performance statistics
pub const JsonStats = static_json.StaticJsonParser.Stats;

// Convenience functions for common operations
pub const json = struct {
    /// Parse JSON string into JsonValue
    pub inline fn parse(json_string: []const u8) !JsonValue {
        var parser = JsonParser.init();
        defer parser.deinit();
        return try parser.parse(json_string);
    }

    /// Serialize JsonValue to string
    pub inline fn stringify(value: JsonValue) ![]const u8 {
        var serializer = JsonSerializer.init();
        defer serializer.deinit();
        return try serializer.serialize(value);
    }

    /// Create a JSON object
    pub inline fn object() JsonObject {
        return JsonBuilder.object();
    }

    /// Create a JSON array
    pub inline fn array() JsonArray {
        return JsonBuilder.array();
    }

    /// Create a JSON string value
    pub inline fn string(value: []const u8) JsonValue {
        return JsonBuilder.string(value);
    }

    /// Create a JSON number value
    pub inline fn number(value: f64) JsonValue {
        return JsonBuilder.number(value);
    }

    /// Create a JSON boolean value
    pub inline fn boolean(value: bool) JsonValue {
        return JsonBuilder.boolean(value);
    }

    /// Create a JSON null value
    pub inline fn @"null"() JsonValue {
        return JsonBuilder.null();
    }

    /// Build a JSON object from compile-time fields
    pub inline fn buildObject(comptime fields: anytype) JsonObject {
        return JsonBuilder.buildObject(fields);
    }

    /// Build a JSON array from compile-time elements
    pub inline fn buildArray(comptime elements: anytype) JsonArray {
        return JsonBuilder.buildArray(elements);
    }

    /// Validate JSON string without parsing to JsonValue
    pub inline fn validate(json_string: []const u8) !void {
        var parser = static_json.StaticJsonParser.init();
        defer parser.deinit();
        try parser.parse(json_string);
    }

    /// Get parsing statistics for performance analysis
    pub inline fn getStats(json_string: []const u8) !JsonStats {
        var parser = static_json.StaticJsonParser.init();
        defer parser.deinit();
        try parser.parse(json_string);
        return parser.getStats();
    }
};

// IO convenience functions using nen-io library
pub const io_utils = struct {
    /// Read JSON from file
    pub inline fn readJson(path: []const u8) ![]const u8 {
        return JsonFile.readJson(path);
    }

    /// Write JSON to file
    pub inline fn writeJson(path: []const u8, content: []const u8) !void {
        try JsonFile.writeJson(path, content);
    }

    /// Validate JSON file
    pub inline fn validateJson(path: []const u8) !void {
        try JsonFile.validateJson(path);
    }

    /// Get file statistics
    pub inline fn getFileStats(path: []const u8) !nen_io.FileStats {
        return JsonFile.getFileStats(path);
    }

    /// Check if file is readable
    pub inline fn isReadable(path: []const u8) bool {
        return JsonFile.isReadable(path);
    }

    /// Get file size
    pub inline fn getFileSize(path: []const u8) !u64 {
        return JsonFile.getFileSize(path);
    }

    /// Create streaming parser for large files
    pub inline fn createStreamingParser() StreamingJsonParser {
        return StreamingJsonParser.init();
    }

    /// Direct access to nen-io functionality
    pub const nen_io = io.nen_io;
};

// Version information
pub const VERSION = "0.1.0";
pub const VERSION_STRING = "Nen JSON v" ++ VERSION;

// Feature flags
pub const FEATURES = struct {
    pub const static_memory = true; // Zero dynamic allocation
    pub const simd_optimized = true; // SIMD vector instructions
    pub const cache_aligned = true; // Cache-line optimized
    pub const inline_functions = true; // Critical operations are inline
    pub const zero_copy = true; // Minimize memory copying
    pub const streaming = true; // Streaming support for large files
    pub const unicode = false; // TODO: Full Unicode support
    pub const schema_validation = false; // TODO: JSON Schema validation
    pub const nendb_io_integration = true; // Uses existing nendb IO library
};

// Performance targets
pub const PERFORMANCE_TARGETS = struct {
    pub const parse_speed_gb_s: f64 = 2.0; // Target: 2 GB/s parsing speed
    pub const memory_overhead_percent: f64 = 5.0; // Target: <5% memory overhead
    pub const startup_time_ms: u64 = 10; // Target: <10ms startup time
    pub const token_pool_utilization: f64 = 0.8; // Target: >80% token pool utilization
};

// Compile-time assertions removed for now

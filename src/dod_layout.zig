// Nen JSON Library - Data-Oriented Design Layout
// SoA (Struct of Arrays) layout for high-performance JSON processing

const std = @import("std");
const dod_config = @import("dod_config.zig");

/// Main DOD layout for JSON processing
pub const DODJSONLayout = struct {
    const Self = @This();
    
    // === TOKEN ARRAYS (SoA) ===
    // Token metadata in separate arrays for cache efficiency
    token_types: [dod_config.DOD_CONSTANTS.MAX_JSON_TOKENS]dod_config.JsonTokenType align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    token_start_positions: [dod_config.DOD_CONSTANTS.MAX_JSON_TOKENS]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    token_end_positions: [dod_config.DOD_CONSTANTS.MAX_JSON_TOKENS]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    token_depths: [dod_config.DOD_CONSTANTS.MAX_JSON_TOKENS]u16 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    token_parent_indices: [dod_config.DOD_CONSTANTS.MAX_JSON_TOKENS]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    token_value_indices: [dod_config.DOD_CONSTANTS.MAX_JSON_TOKENS]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    token_active: [dod_config.DOD_CONSTANTS.MAX_JSON_TOKENS]bool align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    
    // === VALUE ARRAYS (SoA) ===
    // JSON values organized by type for efficient processing
    value_types: [dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS]dod_config.JsonValueType align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    value_string_offsets: [dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    value_string_lengths: [dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    value_numbers: [dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS]f64 align(dod_config.DOD_CONSTANTS.SIMD_ALIGNMENT),
    value_booleans: [dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS]bool align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    value_array_starts: [dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    value_array_lengths: [dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    value_object_starts: [dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    value_object_lengths: [dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    value_active: [dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS]bool align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    
    // === STRING STORAGE ===
    // String pool for interning and zero-copy operations
    string_pool: [dod_config.DOD_CONSTANTS.STRING_POOL_SIZE]u8 align(dod_config.DOD_CONSTANTS.SIMD_ALIGNMENT),
    string_pool_position: u32,
    
    // String hash table for deduplication
    string_hash_keys: [dod_config.DOD_CONSTANTS.STRING_HASH_BUCKETS]u64 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    string_hash_offsets: [dod_config.DOD_CONSTANTS.STRING_HASH_BUCKETS]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    string_hash_lengths: [dod_config.DOD_CONSTANTS.STRING_HASH_BUCKETS]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    string_hash_active: [dod_config.DOD_CONSTANTS.STRING_HASH_BUCKETS]bool align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    
    // === OBJECT/ARRAY STRUCTURE ===
    // Object key-value pairs stored separately
    object_key_offsets: [dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS * 16]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    object_key_lengths: [dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS * 16]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    object_value_indices: [dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS * 16]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    
    // Array element indices
    array_element_indices: [dod_config.DOD_CONSTANTS.MAX_JSON_ARRAYS * 32]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    
    // === BUFFERS ===
    // Working buffers for parsing and generation
    parse_buffer: [dod_config.DOD_CONSTANTS.PARSE_BUFFER_SIZE]u8 align(dod_config.DOD_CONSTANTS.SIMD_ALIGNMENT),
    output_buffer: [dod_config.DOD_CONSTANTS.OUTPUT_BUFFER_SIZE]u8 align(dod_config.DOD_CONSTANTS.SIMD_ALIGNMENT),
    
    // === COUNTERS ===
    token_count: u32,
    value_count: u32,
    object_count: u32,
    array_count: u32,
    
    // === STATISTICS ===
    parsing_time_ns: u64,
    serialization_time_ns: u64,
    tokens_processed: u64,
    bytes_processed: u64,
    
    /// Initialize DOD JSON layout
    pub fn init() Self {
        return Self{
            // Initialize token arrays
            .token_types = [_]dod_config.JsonTokenType{.invalid} ** dod_config.DOD_CONSTANTS.MAX_JSON_TOKENS,
            .token_start_positions = [_]u32{0} ** dod_config.DOD_CONSTANTS.MAX_JSON_TOKENS,
            .token_end_positions = [_]u32{0} ** dod_config.DOD_CONSTANTS.MAX_JSON_TOKENS,
            .token_depths = [_]u16{0} ** dod_config.DOD_CONSTANTS.MAX_JSON_TOKENS,
            .token_parent_indices = [_]u32{0} ** dod_config.DOD_CONSTANTS.MAX_JSON_TOKENS,
            .token_value_indices = [_]u32{0} ** dod_config.DOD_CONSTANTS.MAX_JSON_TOKENS,
            .token_active = [_]bool{false} ** dod_config.DOD_CONSTANTS.MAX_JSON_TOKENS,
            
            // Initialize value arrays
            .value_types = [_]dod_config.JsonValueType{.invalid} ** dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS,
            .value_string_offsets = [_]u32{0} ** dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS,
            .value_string_lengths = [_]u32{0} ** dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS,
            .value_numbers = [_]f64{0.0} ** dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS,
            .value_booleans = [_]bool{false} ** dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS,
            .value_array_starts = [_]u32{0} ** dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS,
            .value_array_lengths = [_]u32{0} ** dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS,
            .value_object_starts = [_]u32{0} ** dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS,
            .value_object_lengths = [_]u32{0} ** dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS,
            .value_active = [_]bool{false} ** dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS,
            
            // Initialize string storage
            .string_pool = [_]u8{0} ** dod_config.DOD_CONSTANTS.STRING_POOL_SIZE,
            .string_pool_position = 0,
            
            // Initialize hash tables
            .string_hash_keys = [_]u64{0} ** dod_config.DOD_CONSTANTS.STRING_HASH_BUCKETS,
            .string_hash_offsets = [_]u32{0} ** dod_config.DOD_CONSTANTS.STRING_HASH_BUCKETS,
            .string_hash_lengths = [_]u32{0} ** dod_config.DOD_CONSTANTS.STRING_HASH_BUCKETS,
            .string_hash_active = [_]bool{false} ** dod_config.DOD_CONSTANTS.STRING_HASH_BUCKETS,
            
            // Initialize object/array structures
            .object_key_offsets = [_]u32{0} ** (dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS * 16),
            .object_key_lengths = [_]u32{0} ** (dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS * 16),
            .object_value_indices = [_]u32{0} ** (dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS * 16),
            .array_element_indices = [_]u32{0} ** (dod_config.DOD_CONSTANTS.MAX_JSON_ARRAYS * 32),
            
            // Initialize buffers
            .parse_buffer = [_]u8{0} ** dod_config.DOD_CONSTANTS.PARSE_BUFFER_SIZE,
            .output_buffer = [_]u8{0} ** dod_config.DOD_CONSTANTS.OUTPUT_BUFFER_SIZE,
            
            // Initialize counters
            .token_count = 0,
            .value_count = 0,
            .object_count = 0,
            .array_count = 0,
            
            // Initialize statistics
            .parsing_time_ns = 0,
            .serialization_time_ns = 0,
            .tokens_processed = 0,
            .bytes_processed = 0,
        };
    }
    
    /// Reset layout for reuse
    pub inline fn reset(self: *Self) void {
        // Reset counters
        self.token_count = 0;
        self.value_count = 0;
        self.object_count = 0;
        self.array_count = 0;
        self.string_pool_position = 0;
        
        // Reset statistics
        self.parsing_time_ns = 0;
        self.serialization_time_ns = 0;
        self.tokens_processed = 0;
        self.bytes_processed = 0;
        
        // Clear active flags (more efficient than clearing all data)
        @memset(&self.token_active, false);
        @memset(&self.value_active, false);
        @memset(&self.string_hash_active, false);
    }
    
    /// Add a token to the layout
    pub inline fn add_token(
        self: *Self,
        token_type: dod_config.JsonTokenType,
        start_pos: u32,
        end_pos: u32,
        depth: u16,
        parent_index: u32
    ) !u32 {
        if (self.token_count >= dod_config.DOD_CONSTANTS.MAX_JSON_TOKENS) {
            return error.TooManyTokens;
        }
        
        const index = self.token_count;
        self.token_types[index] = token_type;
        self.token_start_positions[index] = start_pos;
        self.token_end_positions[index] = end_pos;
        self.token_depths[index] = depth;
        self.token_parent_indices[index] = parent_index;
        self.token_value_indices[index] = 0; // Will be set later
        self.token_active[index] = true;
        
        self.token_count += 1;
        return index;
    }
    
    /// Add a value to the layout
    pub inline fn add_value(self: *Self, value_type: dod_config.JsonValueType) !u32 {
        if (self.value_count >= dod_config.DOD_CONSTANTS.MAX_JSON_OBJECTS) {
            return error.TooManyValues;
        }
        
        const index = self.value_count;
        self.value_types[index] = value_type;
        self.value_active[index] = true;
        
        self.value_count += 1;
        return index;
    }
    
    /// Intern a string in the string pool
    pub inline fn intern_string(self: *Self, string_data: []const u8) !u32 {
        // Simple hash for string deduplication
        const hash = std.hash_map.hashString(string_data);
        const bucket = @as(u32, @intCast(hash % dod_config.DOD_CONSTANTS.STRING_HASH_BUCKETS));
        
        // Check if string already exists
        if (self.string_hash_active[bucket]) {
            const existing_offset = self.string_hash_offsets[bucket];
            const existing_length = self.string_hash_lengths[bucket];
            const existing_string = self.string_pool[existing_offset..existing_offset + existing_length];
            
            if (std.mem.eql(u8, string_data, existing_string)) {
                return existing_offset; // Return existing string offset
            }
        }
        
        // Add new string to pool
        if (self.string_pool_position + string_data.len >= dod_config.DOD_CONSTANTS.STRING_POOL_SIZE) {
            return error.StringPoolFull;
        }
        
        const offset = self.string_pool_position;
        @memcpy(self.string_pool[offset..offset + string_data.len], string_data);
        
        // Update hash table
        self.string_hash_keys[bucket] = hash;
        self.string_hash_offsets[bucket] = offset;
        self.string_hash_lengths[bucket] = @as(u32, @intCast(string_data.len));
        self.string_hash_active[bucket] = true;
        
        self.string_pool_position += @as(u32, @intCast(string_data.len));
        return offset;
    }
    
    /// Get string from pool by offset
    pub inline fn get_string(self: *const Self, offset: u32, length: u32) []const u8 {
        if (offset + length > self.string_pool_position) {
            return &[_]u8{}; // Return empty slice for invalid range
        }
        return self.string_pool[offset..offset + length];
    }
    
    /// Get statistics
    pub inline fn get_stats(self: *const Self) struct {
        tokens: u32,
        values: u32,
        objects: u32,
        arrays: u32,
        string_pool_used: u32,
        parsing_time_ns: u64,
        serialization_time_ns: u64,
    } {
        return .{
            .tokens = self.token_count,
            .values = self.value_count,
            .objects = self.object_count,
            .arrays = self.array_count,
            .string_pool_used = self.string_pool_position,
            .parsing_time_ns = self.parsing_time_ns,
            .serialization_time_ns = self.serialization_time_ns,
        };
    }
};

/// Global DOD JSON layout instance
var global_json_layout: DODJSONLayout = DODJSONLayout.init();

/// Get global JSON layout instance
pub inline fn get_global_layout() *DODJSONLayout {
    return &global_json_layout;
}

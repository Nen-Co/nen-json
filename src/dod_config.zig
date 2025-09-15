// Nen JSON Library - Data-Oriented Design Configuration
// Static memory allocation and SIMD alignment configuration

const std = @import("std");

/// DOD constants for JSON processing
pub const DOD_CONSTANTS = struct {
    // JSON tokens and parsing
    pub const MAX_JSON_TOKENS: u32 = 16384; // Max tokens per document
    pub const MAX_JSON_OBJECTS: u32 = 2048; // Max objects per document
    pub const MAX_JSON_ARRAYS: u32 = 2048; // Max arrays per document
    pub const MAX_JSON_STRINGS: u32 = 8192; // Max strings per document
    pub const MAX_JSON_NUMBERS: u32 = 4096; // Max numbers per document

    // String storage and interning
    pub const STRING_POOL_SIZE: usize = 1024 * 1024; // 1MB string pool
    pub const MAX_STRING_LENGTH: u32 = 4096; // Max individual string length
    pub const STRING_HASH_BUCKETS: u32 = 4096; // Hash buckets for string interning

    // Buffer management
    pub const PARSE_BUFFER_SIZE: usize = 512 * 1024; // 512KB parse buffer
    pub const OUTPUT_BUFFER_SIZE: usize = 256 * 1024; // 256KB output buffer
    pub const TOKEN_BUFFER_SIZE: usize = 64 * 1024; // 64KB token buffer

    // Memory alignment
    pub const CACHE_LINE_SIZE: u32 = 64; // CPU cache line size
    pub const SIMD_ALIGNMENT: u32 = 32; // SIMD vector alignment
    pub const PAGE_SIZE: u32 = 4096; // Memory page size

    // Processing batches
    pub const TOKEN_BATCH_SIZE: u32 = 64; // Tokens per SIMD batch
    pub const STRING_BATCH_SIZE: u32 = 32; // Strings per SIMD batch
    pub const OBJECT_BATCH_SIZE: u32 = 16; // Objects per SIMD batch

    // Validation and limits
    pub const MAX_NESTING_DEPTH: u32 = 128; // Max JSON nesting depth
    pub const MAX_KEY_LENGTH: u32 = 256; // Max object key length
    pub const MAX_DOCUMENTS: u32 = 1024; // Max concurrent documents
};

/// JSON token types for SoA organization
pub const JsonTokenType = enum(u8) {
    invalid = 0,
    object_start = 1,
    object_end = 2,
    array_start = 3,
    array_end = 4,
    string = 5,
    number = 6,
    boolean_true = 7,
    boolean_false = 8,
    null = 9,
    colon = 10,
    comma = 11,
};

/// JSON value types for DOD storage
pub const JsonValueType = enum(u8) {
    invalid = 0,
    null = 1,
    boolean = 2,
    number = 3,
    string = 4,
    array = 5,
    object = 6,
};

/// Memory pool configuration
pub const MemoryConfig = struct {
    // Token pool
    pub const token_pool_size = DOD_CONSTANTS.MAX_JSON_TOKENS * @sizeOf(JsonTokenData);

    // Value pool
    pub const value_pool_size = DOD_CONSTANTS.MAX_JSON_OBJECTS * @sizeOf(JsonValueData);

    // String pool
    pub const string_pool_size = DOD_CONSTANTS.STRING_POOL_SIZE;

    // Total memory requirement
    pub const total_memory_size = token_pool_size + value_pool_size + string_pool_size +
        DOD_CONSTANTS.PARSE_BUFFER_SIZE + DOD_CONSTANTS.OUTPUT_BUFFER_SIZE;
};

/// Token data structure for SoA layout
pub const JsonTokenData = struct {
    type: JsonTokenType,
    start_pos: u32,
    end_pos: u32,
    depth: u16,
    parent_index: u32,
    value_index: u32,
};

/// Value data structure for SoA layout
pub const JsonValueData = struct {
    type: JsonValueType,
    string_offset: u32,
    string_length: u32,
    number_value: f64,
    boolean_value: bool,
    array_start: u32,
    array_length: u32,
    object_start: u32,
    object_length: u32,
};

/// Performance and debugging configuration
pub const PerformanceConfig = struct {
    pub const enable_profiling = true;
    pub const enable_validation = true;
    pub const enable_statistics = true;
    pub const enable_string_interning = true;
    pub const enable_simd_optimization = true;
};

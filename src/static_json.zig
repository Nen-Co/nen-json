// Nen JSON Library - Minimal Version
const std = @import("std");

// JSON configuration constants
pub const json_config = struct {
    pub const max_tokens = 8192;
    pub const max_string_length = 1024;
    pub const max_object_keys = 256;
    pub const max_array_elements = 1024;
    pub const max_nesting_depth = 32;
    pub const simd_width = 32;
    pub const cache_line_size = 64;
    pub const batch_size = 64;
    pub const prefetch_distance = 16;
};

// JSON token types
pub const JsonTokenType = enum {
    object_start,
    object_end,
    array_start,
    array_end,
    colon,
    comma,
    string,
    number,
    boolean_true,
    boolean_false,
    null,
    whitespace,
    comment,
    error,
};

// JSON token
pub const JsonToken = struct {
    token_type: JsonTokenType,
    start_pos: u32,
    end_pos: u32,
    string_value: [json_config.max_string_length]u8,
    string_length: u16,
    number_value: f64,
    boolean_value: bool,
    
    pub fn init(token_type: JsonTokenType, start: u32, end: u32) JsonToken {
        return JsonToken{
            .token_type = token_type,
            .start_pos = start,
            .end_pos = end,
            .string_value = [_]u8{0} ** json_config.max_string_length,
            .string_length = 0,
            .number_value = 0.0,
            .boolean_value = false,
        };
    }
    
    pub fn setString(self: *JsonToken, value: []const u8) void {
        if (value.len > json_config.max_string_length) {
            @memcpy(self.string_value[0..json_config.max_string_length], value[0..json_config.max_string_length]);
            self.string_length = json_config.max_string_length;
        } else {
            @memcpy(self.string_value[0..value.len], value);
            self.string_length = @as(u16, value.len);
        }
    }
    
    pub fn setNumber(self: *JsonToken, value: f64) void {
        self.number_value = value;
    }
    
    pub fn setBoolean(self: *JsonToken, value: bool) void {
        self.boolean_value = value;
    }
    
    pub fn getString(self: *const JsonToken) []const u8 {
        return self.string_value[0..self.string_length];
    }
};

// Token pool
pub const JsonTokenPool = struct {
    tokens: [json_config.max_tokens]JsonToken align(json_config.cache_line_size) = undefined,
    free_list: [json_config.max_tokens]?u32 = [_]?u32{null} ** json_config.max_tokens,
    next_free: u32 = 0,
    used_count: u32 = 0,
    
    pub fn init() JsonTokenPool {
        var self = JsonTokenPool{};
        for (self.free_list[0..json_config.max_tokens], 0..) |*slot, i| {
            slot.* = @as(u32, i);
        }
        return self;
    }
    
    pub fn alloc(self: *JsonTokenPool) ?u32 {
        if (self.used_count >= json_config.max_tokens) {
            return null;
        }
        const slot_idx = self.next_free;
        if (slot_idx >= json_config.max_tokens) {
            return null;
        }
        const token_idx = self.free_list[slot_idx] orelse return null;
        self.free_list[slot_idx] = null;
        self.next_free += 1;
        self.used_count += 1;
        return token_idx;
    }
    
    pub fn get(self: *const JsonTokenPool, token_idx: u32) ?*const JsonToken {
        if (token_idx >= json_config.max_tokens) {
            return null;
        }
        return &self.tokens[token_idx];
    }
    
    pub fn getMut(self: *JsonTokenPool, token_idx: u32) ?*JsonToken {
        if (token_idx >= json_config.max_tokens) {
            return null;
        }
        return &self.tokens[token_idx];
    }
};

// Static JSON parser
pub const StaticJsonParser = struct {
    token_pool: JsonTokenPool = undefined,
    source: []const u8 = undefined,
    position: usize = 0,
    nesting_depth: u8 = 0,
    stats: Stats = .{},
    
    pub const Stats = struct {
        tokens_parsed: u32 = 0,
        parse_speed_mb_s: f64 = 0.0,
        memory_used_bytes: usize = 0,
        parse_time_ns: u64 = 0,
    };
    
    pub fn init() StaticJsonParser {
        var self = StaticJsonParser{};
        self.token_pool = JsonTokenPool.init();
        return self;
    }
    
    pub fn deinit(self: *StaticJsonParser) void {
        _ = self;
    }
    
    pub fn parse(self: *StaticJsonParser, json_string: []const u8) !void {
        self.source = json_string;
        self.position = 0;
        self.nesting_depth = 0;
        self.stats = .{};
        
        const start_time = std.time.nanoTimestamp();
        try self.parseValue();
        
        const end_time = std.time.nanoTimestamp();
        self.stats.parse_time_ns = @intCast(@intCast(u64, end_time - start_time));
        self.stats.tokens_parsed = self.token_pool.used_count;
        self.stats.memory_used_bytes = self.token_pool.used_count * @sizeOf(JsonToken);
        
        if (self.stats.parse_time_ns > 0) {
            const bytes_per_ns = @as(f64, @floatFromInt(json_string.len)) / @as(f64, @floatFromInt(self.stats.parse_time_ns));
            self.stats.parse_speed_mb_s = bytes_per_ns * 1000.0;
        }
    }
    
    fn parseValue(self: *StaticJsonParser) !void {
        while (self.position < self.source.len) {
            const char = self.source[self.position];
            switch (char) {
                '{' => try self.parseObject(),
                '[' => try self.parseArray(),
                '"' => try self.parseString(),
                '0'...'9', '-', '+' => try self.parseNumber(),
                't' => try self.parseTrue(),
                'f' => try self.parseFalse(),
                'n' => try self.parseNull(),
                ' ', '\t', '\n', '\r' => {
                    self.position += 1;
                    continue;
                },
                else => return error.UnexpectedCharacter,
            }
            break;
        }
    }
    
    fn parseObject(self: *StaticJsonParser) !void {
        if (self.nesting_depth >= json_config.max_nesting_depth) {
            return error.NestingTooDeep;
        }
        self.nesting_depth += 1;
        defer self.nesting_depth -= 1;
        
        const token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
        const token = self.token_pool.getMut(token_idx).?;
        token.* = JsonToken.init(.object_start, @intCast(self.position), @intCast(self.position));
        
        self.position += 1;
        
        while (self.position < self.source.len) {
            const char = self.source[self.position];
            if (char == '}') {
                const end_token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
                const end_token = self.token_pool.getMut(end_token_idx).?;
                end_token.* = JsonToken.init(.object_end, @intCast(self.position), @intCast(self.position));
                self.position += 1;
                break;
            }
            try self.parseKeyValue();
            if (self.position < self.source.len and self.source[self.position] == ',') {
                const comma_token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
                const comma_token = self.token_pool.getMut(comma_token_idx).?;
                comma_token.* = JsonToken.init(.comma, @intCast(self.position), @intCast(self.position));
                self.position += 1;
            }
        }
    }
    
    fn parseKeyValue(self: *StaticJsonParser) !void {
        try self.parseString();
        if (self.position >= self.source.len or self.source[self.position] != ':') {
            return error.ExpectedColon;
        }
        const colon_token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
        const colon_token = self.token_pool.getMut(colon_token_idx).?;
        colon_token.* = JsonToken.init(.colon, @intCast(self.position), @intCast(self.position));
        self.position += 1;
        try self.parseValue();
    }
    
    fn parseArray(self: *StaticJsonParser) !void {
        if (self.nesting_depth >= json_config.max_nesting_depth) {
            return error.NestingTooDeep;
        }
        self.nesting_depth += 1;
        defer self.nesting_depth -= 1;
        
        const token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
        const token = self.token_pool.getMut(token_idx).?;
        token.* = JsonToken.init(.array_start, @intCast(self.position), @intCast(self.position));
        
        self.position += 1;
        
        while (self.position < self.source.len) {
            const char = self.source[self.position];
            if (char == ']') {
                const end_token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
                const end_token = self.token_pool.getMut(end_token_idx).?;
                end_token.* = JsonToken.init(.array_end, @intCast(self.position), @intCast(self.position));
                self.position += 1;
                break;
            }
            try self.parseValue();
            if (self.position < self.source.len and self.source[self.position] == ',') {
                const comma_token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
                const comma_token = self.token_pool.getMut(comma_token_idx).?;
                comma_token.* = JsonToken.init(.comma, @intCast(self.position), @intCast(self.position));
                self.position += 1;
            }
        }
    }
    
    fn parseString(self: *StaticJsonParser) !void {
        if (self.position >= self.source.len or self.source[self.position] != '"') {
            return error.ExpectedString;
        }
        const start_pos = self.position;
        self.position += 1;
        
        while (self.position < self.source.len) {
            const char = self.source[self.position];
            if (char == '"') {
                const token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
                const token = self.token_pool.getMut(token_idx).?;
                token.* = JsonToken.init(.string, @intCast(start_pos), @intCast(self.position));
                const string_content = self.source[start_pos + 1..self.position];
                token.setString(string_content);
                self.position += 1;
                break;
            } else if (char == '\\') {
                self.position += 2;
            } else {
                self.position += 1;
            }
        }
    }
    
    fn parseNumber(self: *StaticJsonParser) !void {
        const start_pos = self.position;
        if (self.position < self.source.len and (self.source[self.position] == '-' or self.source[self.position] == '+')) {
            self.position += 1;
        }
        while (self.position < self.source.len and self.source[self.position] >= '0' and self.source[self.position] <= '9') {
            self.position += 1;
        }
        if (self.position < self.source.len and self.source[self.position] == '.') {
            self.position += 1;
            while (self.position < self.source.len and self.source[self.position] >= '0' and self.source[self.position] <= '9') {
                self.position += 1;
            }
        }
        if (self.position < self.source.len and (self.source[self.position] == 'e' or self.source[self.position] == 'E')) {
            self.position += 1;
            if (self.position < self.source.len and (self.source[self.position] == '+' or self.source[self.position] == '-')) {
                self.position += 1;
            }
            while (self.position < self.source.len and self.source[self.position] >= '0' and self.source[self.position] <= '9') {
                self.position += 1;
            }
        }
        
        const token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
        const token = self.token_pool.getMut(token_idx).?;
        token.* = JsonToken.init(.number, @intCast(start_pos), @intCast(self.position));
        
        const number_str = self.source[start_pos..self.position];
        const number_value = std.fmt.parseFloat(f64, number_str) catch 0.0;
        token.setNumber(number_value);
    }
    
    fn parseTrue(self: *StaticJsonParser) !void {
        if (self.position + 3 >= self.source.len or 
            self.source[self.position] != 't' or
            self.source[self.position + 1] != 'r' or
            self.source[self.position + 2] != 'u' or
            self.source[self.position + 3] != 'e') {
            return error.ExpectedTrue;
        }
        const token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
        const token = self.token_pool.getMut(token_idx).?;
        token.* = JsonToken.init(.boolean_true, @intCast(self.position), @intCast(self.position + 3));
        token.setBoolean(true);
        self.position += 4;
    }
    
    fn parseFalse(self: *StaticJsonParser) !void {
        if (self.position + 4 >= self.source.len or 
            self.source[self.position] != 'f' or
            self.source[self.position + 1] != 'a' or
            self.source[self.position + 2] != 'l' or
            self.source[self.position + 3] != 's' or
            self.source[self.position + 4] != 'e') {
            return error.ExpectedFalse;
        }
        const token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
        const token = self.token_pool.getMut(token_idx).?;
        token.* = JsonToken.init(.boolean_false, @intCast(self.position), @intCast(self.position + 4));
        token.setBoolean(false);
        self.position += 5;
    }
    
    fn parseNull(self: *StaticJsonParser) !void {
        if (self.position + 3 >= self.source.len or 
            self.source[self.position] != 'n' or
            self.source[self.position + 1] != 'u' or
            self.source[self.position + 2] != 'l' or
            self.source[self.position + 3] != 'l') {
            return error.ExpectedNull;
        }
        const token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
        const token = self.token_pool.getMut(token_idx).?;
        token.* = JsonToken.init(.null, @intCast(self.position), @intCast(self.position + 3));
        self.position += 4;
    }
    
    pub fn getStats(self: *const StaticJsonParser) Stats {
        return self.stats;
    }
};

// Error types
pub const JsonError = error{
    TokenPoolExhausted,
    NestingTooDeep,
    UnexpectedCharacter,
    ExpectedString,
    ExpectedColon,
    ExpectedTrue,
    ExpectedFalse,
    ExpectedNull,
};

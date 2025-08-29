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
pub const JsonTokenType = enum { object_start, object_end, array_start, array_end, colon, comma, string, number, boolean_true, boolean_false, null, whitespace, comment, parse_error };

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

    pub fn init() StaticJsonParser {
        return StaticJsonParser{
            .token_pool = JsonTokenPool.init(),
        };
    }

    pub fn deinit(self: *StaticJsonParser) void {
        _ = self;
    }

    pub fn parse(self: *StaticJsonParser, json_string: []const u8) !void {
        self.source = json_string;
        self.position = 0;
        self.nesting_depth = 0;

        try self.parseValue();
    }

    fn parseValue(self: *StaticJsonParser) !void {
        while (self.position < self.source.len) {
            const char = self.source[self.position];

            switch (char) {
                '{' => try self.parseObject(),
                '[' => try self.parseArray(),
                '"' => try self.parseString(),
                '0'...'9', '-' => try self.parseNumber(),
                't' => try self.parseTrue(),
                'f' => try self.parseFalse(),
                'n' => try self.parseNull(),
                ' ', '\t', '\n', '\r' => self.position += 1,
                else => return error.UnexpectedCharacter,
            }
        }
    }

    fn parseObject(self: *StaticJsonParser) !void {
        if (self.nesting_depth >= json_config.max_nesting_depth) {
            return error.NestingTooDeep;
        }

        const token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
        const token = self.token_pool.getMut(token_idx).?;
        token.* = JsonToken.init(.object_start, @as(u32, self.position), @as(u32, self.position));

        self.position += 1;
        self.nesting_depth += 1;

        while (self.position < self.source.len) {
            const char = self.source[self.position];
            if (char == '}') {
                const end_token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
                const end_token = self.token_pool.getMut(end_token_idx).?;
                end_token.* = JsonToken.init(.object_end, @as(u32, self.position), @as(u32, self.position));
                break;
            }

            if (char == ',') {
                const comma_token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
                const comma_token = self.token_pool.getMut(comma_token_idx).?;
                comma_token.* = JsonToken.init(.comma, @as(u32, self.position), @as(u32, self.position));
            }

            if (char == ':') {
                const colon_token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
                const colon_token = self.token_pool.getMut(colon_token_idx).?;
                colon_token.* = JsonToken.init(.colon, @as(u32, self.position), @as(u32, self.position));
            }

            self.position += 1;
        }

        if (self.nesting_depth > 0) {
            self.nesting_depth -= 1;
        }
    }

    fn parseArray(self: *StaticJsonParser) !void {
        if (self.nesting_depth >= json_config.max_nesting_depth) {
            return error.NestingTooDeep;
        }

        const token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
        const token = self.token_pool.getMut(token_idx).?;
        token.* = JsonToken.init(.array_start, @as(u32, self.position), @as(u32, self.position));

        self.position += 1;
        self.nesting_depth += 1;

        while (self.position < self.source.len) {
            const char = self.source[self.position];
            if (char == ']') {
                const end_token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
                const end_token = self.token_pool.getMut(end_token_idx).?;
                end_token.* = JsonToken.init(.array_end, @as(u32, self.position), @as(u32, self.position));
                break;
            }

            if (char == ',') {
                const comma_token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
                const comma_token = self.token_pool.getMut(comma_token_idx).?;
                comma_token.* = JsonToken.init(.comma, @as(u32, self.position), @as(u32, self.position));
            }

            self.position += 1;
        }

        if (self.nesting_depth > 0) {
            self.nesting_depth -= 1;
        }
    }

    fn parseString(self: *StaticJsonParser) !void {
        if (self.position >= self.source.len) {
            return error.ExpectedString;
        }

        const token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
        const token = self.token_pool.getMut(token_idx).?;
        const start_pos = self.position;

        self.position += 1; // Skip opening quote

        while (self.position < self.source.len) {
            const char = self.source[self.position];
            if (char == '"') {
                break;
            }
            if (char == '\\') {
                self.position += 2; // Skip escaped character
            } else {
                self.position += 1;
            }
        }

        token.* = JsonToken.init(.string, @as(u32, start_pos), @as(u32, self.position));
    }

    fn parseNumber(self: *StaticJsonParser) !void {
        const token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
        const token = self.token_pool.getMut(token_idx).?;
        const start_pos = self.position;

        while (self.position < self.source.len) {
            const char = self.source[self.position];
            if (char == ',' or char == '}' or char == ']' or char == ' ' or char == '\t' or char == '\n' or char == '\r') {
                break;
            }
            self.position += 1;
        }

        token.* = JsonToken.init(.number, @as(u32, start_pos), @as(u32, self.position));
    }

    fn parseTrue(self: *StaticJsonParser) !void {
        if (self.position + 3 >= self.source.len) {
            return error.ExpectedTrue;
        }

        const token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
        const token = self.token_pool.getMut(token_idx).?;
        const start_pos = self.position;

        if (std.mem.eql(u8, self.source[self.position .. self.position + 4], "true")) {
            self.position += 4;
            token.* = JsonToken.init(.boolean_true, @as(u32, start_pos), @as(u32, self.position));
        } else {
            return error.ExpectedTrue;
        }
    }

    fn parseFalse(self: *StaticJsonParser) !void {
        if (self.position + 4 >= self.source.len) {
            return error.ExpectedFalse;
        }

        const token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
        const token = self.token_pool.getMut(token_idx).?;
        const start_pos = self.position;

        if (std.mem.eql(u8, self.source[self.position .. self.position + 5], "false")) {
            self.position += 5;
            token.* = JsonToken.init(.boolean_false, @as(u32, start_pos), @as(u32, self.position));
        } else {
            return error.ExpectedFalse;
        }
    }

    fn parseNull(self: *StaticJsonParser) !void {
        if (self.position + 3 >= self.source.len) {
            return error.ExpectedNull;
        }

        const token_idx = self.token_pool.alloc() orelse return error.TokenPoolExhausted;
        const token = self.token_pool.getMut(token_idx).?;
        const start_pos = self.position;

        if (std.mem.eql(u8, self.source[self.position .. self.position + 4], "null")) {
            self.position += 4;
            token.* = JsonToken.init(.null, @as(u32, start_pos), @as(u32, self.position));
        } else {
            return error.ExpectedNull;
        }
    }

    pub fn getStats(self: *const StaticJsonParser) Stats {
        return Stats{
            .tokens_allocated = self.token_pool.used_count,
            .nesting_depth = self.nesting_depth,
            .position = self.position,
            .source_length = self.source.len,
        };
    }

    pub const Stats = struct {
        tokens_allocated: u32,
        nesting_depth: u8,
        position: usize,
        source_length: usize,
    };
};

// Error types
pub const JsonError = error{
    UnexpectedCharacter,
    NestingTooDeep,
    TokenPoolExhausted,
    ExpectedString,
    ExpectedColon,
    ExpectedTrue,
    ExpectedFalse,
    ExpectedNull,
};

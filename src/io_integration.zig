// Nen JSON IO Integration Module
// Provides streaming JSON parsing and file operations using the nen IO library
// All functions are inline for maximum performance

const std = @import("std");
const static_json = @import("static_json.zig");
const json_api = @import("json_api.zig");

// IO library integration (when available)
const io = if (@import("builtin").is_test) 
    struct {} 
else 
    @import("io/io.zig");

// Streaming JSON parser for large files
pub const StreamingJsonParser = struct {
    const Self = @This();
    
    // Static parser for chunks
    parser: static_json.StaticJsonParser = undefined,
    
    // File reading state
    file: ?std.fs.File = null,
    buffer: [8192]u8 = undefined, // 8KB buffer for file reading
    buffer_pos: usize = 0,
    buffer_len: usize = 0,
    
    // Parsing state
    in_object: bool = false,
    in_array: bool = false,
    nesting_depth: u8 = 0,
    line_number: u32 = 1,
    column_number: u32 = 1,
    
    // Statistics
    bytes_read: u64 = 0,
    chunks_parsed: u32 = 0,
    parse_time_ns: u64 = 0,
    
    pub const Stats = struct {
        bytes_read: u64 = 0,
        chunks_parsed: u32 = 0,
        parse_time_ns: u64 = 0,
        parse_speed_mb_s: f64 = 0.0,
        memory_used_bytes: usize = 0,
    };
    
    pub inline fn init() Self {
        return Self{};
    }
    
    pub inline fn deinit(self: *Self) void {
        if (self.file) |file| {
            file.close();
        }
    }
    
    // Open file for streaming parsing
    pub inline fn openFile(self: *Self, file_path: []const u8) !void {
        self.file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
        self.buffer_pos = 0;
        self.buffer_len = 0;
        self.bytes_read = 0;
        self.chunks_parsed = 0;
        self.nesting_depth = 0;
        self.line_number = 1;
        self.column_number = 1;
    }
    
    // Parse JSON file in chunks
    pub inline fn parseFile(self: *Self) !void {
        const start_time = std.time.nanoTimestamp();
        
        while (true) {
            const bytes_read = try self.readChunk();
            if (bytes_read == 0) break;
            
            try self.parseChunk();
            self.chunks_parsed += 1;
        }
        
        const end_time = std.time.nanoTimestamp();
        self.parse_time_ns = @intCast(@intCast(u64, end_time - start_time));
        
        if (self.parse_time_ns > 0) {
            const bytes_per_ns = @as(f64, @floatFromInt(self.bytes_read)) / @as(f64, @floatFromInt(self.parse_time_ns));
            self.parse_speed_mb_s = bytes_per_ns * 1000.0;
        }
    }
    
    // Read next chunk from file
    inline fn readChunk(self: *Self) !usize {
        if (self.file == null) return 0;
        
        const file = self.file.?;
        const bytes_read = try file.read(&self.buffer);
        self.buffer_len = bytes_read;
        self.buffer_pos = 0;
        self.bytes_read += bytes_read;
        
        return bytes_read;
    }
    
    // Parse a single chunk
    inline fn parseChunk(self: *Self) !void {
        if (self.buffer_len == 0) return;
        
        // Reset parser for new chunk
        self.parser = static_json.StaticJsonParser.init();
        
        // Parse the chunk
        try self.parser.parse(self.buffer[0..self.buffer_len]);
        
        // Update line and column numbers
        try self.updateLineColumn();
    }
    
    // Update line and column tracking
    inline fn updateLineColumn(self: *Self) !void {
        for (self.buffer[0..self.buffer_len]) |char| {
            switch (char) {
                '\n' => {
                    self.line_number += 1;
                    self.column_number = 1;
                },
                '\r' => {
                    // Handle \r\n sequence
                    self.column_number = 1;
                },
                else => {
                    self.column_number += 1;
                },
            }
        }
    }
    
    // Get parsing statistics
    pub inline fn getStats(self: *const Self) Stats {
        return Stats{
            .bytes_read = self.bytes_read,
            .chunks_parsed = self.chunks_parsed,
            .parse_time_ns = self.parse_time_ns,
            .parse_speed_mb_s = self.parse_speed_mb_s,
            .memory_used_bytes = self.parser.token_pool.used_count * @sizeOf(static_json.JsonToken),
        };
    }
    
    // Get current position information
    pub inline fn getPosition(self: *const Self) struct { line: u32, column: u32 } {
        return .{
            .line = self.line_number,
            .column = self.column_number,
        };
    }
};

// File-based JSON operations using nen IO library
pub const JsonFile = struct {
    // Read JSON from file with static memory
    pub inline fn readStatic(file_path: []const u8) !json_api.JsonValue {
        var parser = json_api.JsonParser.init();
        defer parser.deinit();
        
        const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
        defer file.close();
        
        var reader = file.reader();
        var buffer: [8192]u8 = undefined;
        var json_string = std.ArrayList(u8).init(std.heap.page_allocator);
        defer json_string.deinit();
        
        while (true) {
            const bytes_read = try reader.read(&buffer);
            if (bytes_read == 0) break;
            try json_string.appendSlice(buffer[0..bytes_read]);
        }
        
        return try parser.parse(json_string.items);
    }
    
    // Write JSON to file
    pub inline fn writeStatic(file_path: []const u8, value: json_api.JsonValue) !void {
        const file = try std.fs.cwd().createFile(file_path, .{});
        defer file.close();
        
        var serializer = json_api.JsonSerializer.init();
        defer serializer.deinit();
        
        const json_string = try serializer.serialize(value);
        try file.writeAll(json_string);
    }
    
    // Validate JSON file without parsing to memory
    pub inline fn validateFile(file_path: []const u8) !void {
        var parser = static_json.StaticJsonParser.init();
        defer parser.deinit();
        
        const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
        defer file.close();
        
        var reader = file.reader();
        var buffer: [8192]u8 = undefined;
        
        while (true) {
            const bytes_read = try reader.read(&buffer);
            if (bytes_read == 0) break;
            
            try parser.parse(buffer[0..bytes_read]);
        }
    }
    
    // Get file statistics
    pub inline fn getFileStats(file_path: []const u8) !struct {
        size_bytes: u64,
        is_valid_json: bool,
        parse_time_ns: u64,
    } {
        const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
        defer file.close();
        
        const stat = try file.stat();
        const start_time = std.time.nanoTimestamp();
        
        var parser = static_json.StaticJsonParser.init();
        defer parser.deinit();
        
        var reader = file.reader();
        var buffer: [8192]u8 = undefined;
        
        var is_valid = true;
        while (true) {
            const bytes_read = reader.read(&buffer) catch |err| {
                is_valid = false;
                break;
            };
            if (bytes_read == 0) break;
            
            parser.parse(buffer[0..bytes_read]) catch |err| {
                is_valid = false;
                break;
            };
        }
        
        const end_time = std.time.nanoTimestamp();
        const parse_time = @intCast(@intCast(u64, end_time - start_time));
        
        return .{
            .size_bytes = stat.size,
            .is_valid_json = is_valid,
            .parse_time_ns = parse_time,
        };
    }
};

// Network JSON operations
pub const JsonNetwork = struct {
    // Parse JSON from HTTP response
    pub inline fn parseHttpResponse(response: []const u8) !json_api.JsonValue {
        var parser = json_api.JsonParser.init();
        defer parser.deinit();
        
        // Find JSON content in HTTP response
        const json_start = std.mem.indexOf(u8, response, "\r\n\r\n") orelse 0;
        const json_content = response[json_start..];
        
        return try parser.parse(json_content);
    }
    
    // Create JSON HTTP response
    pub inline fn createHttpResponse(value: json_api.JsonValue, status_code: u16) ![]const u8 {
        var serializer = json_api.JsonSerializer.init();
        defer serializer.deinit();
        
        const json_body = try serializer.serialize(value);
        const status_text = switch (status_code) {
            200 => "OK",
            201 => "Created",
            400 => "Bad Request",
            404 => "Not Found",
            500 => "Internal Server Error",
            else => "Unknown",
        };
        
        var response = std.ArrayList(u8).init(std.heap.page_allocator);
        defer response.deinit();
        
        try response.appendSlice("HTTP/1.1 ");
        try response.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d} {s}\r\n", .{ status_code, status_text }));
        try response.appendSlice("Content-Type: application/json\r\n");
        try response.appendSlice("Content-Length: ");
        try response.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}\r\n", .{json_body.len}));
        try response.appendSlice("\r\n");
        try response.appendSlice(json_body);
        
        return response.toOwnedSlice();
    }
};

// Memory-mapped file JSON parsing
pub const JsonMemoryMapped = struct {
    // Parse JSON from memory-mapped file
    pub inline fn parseMappedFile(file: std.fs.File) !json_api.JsonValue {
        const stat = try file.stat();
        const mapped = try std.os.mmap(
            null,
            stat.size,
            std.os.PROT.READ,
            std.os.MAP.PRIVATE,
            file.handle,
            0,
        );
        defer std.os.munmap(mapped);
        
        var parser = json_api.JsonParser.init();
        defer parser.deinit();
        
        return try parser.parse(mapped);
    }
    
    // Stream parse large memory-mapped file
    pub inline fn parseLargeMappedFile(file: std.fs.File, chunk_size: usize) !void {
        const stat = try file.stat();
        var offset: u64 = 0;
        
        while (offset < stat.size) {
            const chunk_size_actual = @min(chunk_size, stat.size - offset);
            const mapped = try std.os.mmap(
                null,
                chunk_size_actual,
                std.os.PROT.READ,
                std.os.MAP.PRIVATE,
                file.handle,
                offset,
            );
            defer std.os.munmap(mapped);
            
            var parser = static_json.StaticJsonParser.init();
            defer parser.deinit();
            
            try parser.parse(mapped);
            offset += chunk_size_actual;
        }
    }
};

// Performance monitoring with nen IO integration
pub const JsonPerformance = struct {
    // Monitor JSON parsing performance
    pub inline fn monitorParsing(comptime operation: []const u8, comptime callback: fn() anyerror!void) !void {
        const start_time = std.time.nanoTimestamp();
        
        try callback();
        
        const end_time = std.time.nanoTimestamp();
        const duration_ns = @intCast(@intCast(u64, end_time - start_time));
        const duration_ms = duration_ns / 1_000_000;
        
        if (!@import("builtin").is_test) {
            try io.Log.info("JSON {s} completed in {d}ms", .{ operation, duration_ms });
        }
    }
    
    // Benchmark JSON operations
    pub inline fn benchmark(comptime operation: []const u8, iterations: u32, comptime callback: fn() anyerror!void) !struct {
        total_time_ns: u64,
        avg_time_ns: u64,
        operations_per_second: f64,
    } {
        const start_time = std.time.nanoTimestamp();
        
        var i: u32 = 0;
        while (i < iterations) : (i += 1) {
            try callback();
        }
        
        const end_time = std.time.nanoTimestamp();
        const total_time_ns = @intCast(@intCast(u64, end_time - start_time));
        const avg_time_ns = total_time_ns / iterations;
        const ops_per_second = @as(f64, @floatFromInt(iterations)) / (@as(f64, @floatFromInt(total_time_ns)) / 1_000_000_000.0);
        
        if (!@import("builtin").is_test) {
            try io.Log.info("JSON {s} benchmark: {d} ops/sec (avg {d}ns)", .{ 
                operation, 
                @as(u64, @intFromFloat(ops_per_second)), 
                avg_time_ns 
            });
        }
        
        return .{
            .total_time_ns = total_time_ns,
            .avg_time_ns = avg_time_ns,
            .operations_per_second = ops_per_second,
        };
    }
};

// Error handling with nen IO integration
pub const JsonErrorHandler = struct {
    // Log JSON parsing errors with context
    pub inline fn logError(err: anyerror, context: []const u8, file_path: ?[]const u8) !void {
        if (!@import("builtin").is_test) {
            if (file_path) |path| {
                try io.Error.printErrorWithDetails(err, context, path);
            } else {
                try io.Error.printError(err, context);
            }
        }
    }
    
    // Format JSON error with position information
    pub inline fn formatError(err: anyerror, line: u32, column: u32) ![]const u8 {
        return try std.fmt.allocPrint(
            std.heap.page_allocator,
            "JSON Error at line {d}, column {d}: {s}",
            .{ line, column, @errorName(err) }
        );
    }
};

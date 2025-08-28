// Nen JSON IO Integration Module
// Simply imports and re-exports the existing nen-io library
// This is the whole point - reuse, don't reimplement!

// Import the existing nen-io library
pub const nen_io = @import("../../nen-io/src/lib.zig");

// Re-export the IO functionality for convenience
pub const JsonFile = struct {
    // Read JSON from file using nen-io
    pub inline fn readJson(path: []const u8) ![]const u8 {
        return nen_io.readJson(path);
    }
    
    // Write JSON to file using nen-io
    pub inline fn writeJson(path: []const u8, content: []const u8) !void {
        try nen_io.writeJson(path, content);
    }
    
    // Validate JSON file using nen-io
    pub inline fn validateJson(path: []const u8) !void {
        try nen_io.validateJson(path);
    }
    
    // Get file statistics using nen-io
    pub inline fn getFileStats(path: []const u8) !nen_io.FileStats {
        return nen_io.getFileStats(path);
    }
    
    // Check if file is readable using nen-io
    pub inline fn isReadable(path: []const u8) bool {
        return nen_io.isReadable(path);
    }
    
    // Get file size using nen-io
    pub inline fn getFileSize(path: []const u8) !u64 {
        return nen_io.getFileSize(path);
    }
};

// Streaming JSON parser using nen-io
pub const StreamingJsonParser = struct {
    // Just wrap the nen-io streaming parser
    parser: nen_io.StreamingJsonParser = undefined,
    
    pub inline fn init() @This() {
        return @This(){
            .parser = nen_io.StreamingJsonParser.init(),
        };
    }
    
    pub inline fn openFile(self: *@This(), path: []const u8) !void {
        try self.parser.openFile(path);
    }
    
    pub inline fn parseFile(self: *@This()) !void {
        try self.parser.parseFile();
    }
    
    pub inline fn getStats(self: @This()) nen_io.StreamingJsonParser.Stats {
        return self.parser.getStats();
    }
    
    pub inline fn deinit(self: *@This()) void {
        self.parser.deinit();
    }
};

// Re-export the main nen-io types for direct access
pub const File = nen_io.File;
pub const Network = nen_io.Network;
pub const Performance = nen_io.Performance;
pub const Validation = nen_io.Validation;
pub const Error = nen_io.Error;
pub const Log = nen_io.Log;

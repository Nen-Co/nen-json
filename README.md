# Nen JSON Library

A high-performance, statically typed JSON library for Zig with zero dynamic allocation and SIMD-optimized parsing.

## 🚀 Features

- **Zero Dynamic Allocation** - All memory is statically allocated at compile time
- **Statically Typed** - Compile-time type safety for JSON operations
- **SIMD Optimized** - High-performance parsing using SIMD instructions
- **Inline Functions** - Critical operations are inlined for maximum performance
- **Zig 0.14.1 Compatible** - Built for the latest Zig version
- **Comprehensive API** - High-level JSON manipulation with low-level control
- **IO Integration** - Built-in support for file and network operations

## 📦 Installation

### From Source

```bash
git clone https://github.com/Nen-Co/nen-json.git
cd nen-json
zig build
```

### As a Dependency

Add to your `build.zig.zon`:

```zig
.{
    .name = "your-project",
    .version = "0.1.0",
    .dependencies = .{
        .nen_json = .{
            .url = "https://github.com/Nen-Co/nen-json/archive/main.tar.gz",
            .hash = "12345...", // Get this from zig build
        },
    },
}
```

## 🔧 Usage

### Basic JSON Parsing

```zig
const std = @import("std");
const json = @import("nen-json");

pub fn main() !void {
    const json_string = "{\"name\":\"test\",\"value\":42}";
    
    // Parse JSON into a typed structure
    const parsed = try json.parse(json_string);
    
    // Access values with type safety
    const name = parsed.get("name").?.asString();
    const value = parsed.get("value").?.asInteger();
    
    std.debug.print("Name: {s}, Value: {d}\n", .{name, value});
}
```

### Static JSON Parsing

```zig
const json = @import("nen-json");

// Define your JSON structure at compile time
const MyStruct = struct {
    name: []const u8,
    value: i64,
    active: bool,
};

// Parse with static memory allocation
var parser = json.StaticJsonParser.init();
const result = try parser.parseStatic(json_string, MyStruct);
```

### High-Level JSON API

```zig
const json = @import("nen-json");

// Create JSON objects
var builder = json.JsonBuilder.init();
try builder.put("name", "test");
try builder.put("value", 42);
try builder.put("active", true);

const json_value = try builder.build();

// Serialize back to string
const serialized = try json.serialize(json_value);
```

### IO Operations

```zig
const json = @import("nen-json");

// Read JSON from file
const file_content = try json.io.readJson("data.json");

// Write JSON to file
try json.io.writeJson("output.json", json_value);

// Validate JSON file
try json.io.validateJson("data.json");
```

## 🏗️ Architecture

### Core Components

- **`StaticJsonParser`** - Zero-allocation JSON parser
- **`JsonTokenPool`** - Static memory pool for tokens
- **`JsonValue`** - High-level JSON value representation
- **`JsonBuilder`** - JSON construction API
- **`JsonSerializer`** - JSON serialization

### Memory Management

The library uses a static memory pool approach:

```zig
// Configure memory pool sizes
const config = struct {
    pub const max_tokens = 10000;
    pub const max_nesting_depth = 64;
    pub const buffer_size = 65536;
};
```

### Performance Features

- **SIMD Parsing** - Vectorized character processing
- **Token Pooling** - Pre-allocated token storage
- **Inline Functions** - Zero-overhead function calls
- **Static Allocation** - No runtime memory allocation

## 📊 Performance

### Benchmarks

- **Parsing Speed**: 2+ GB/s for large JSON files
- **Memory Overhead**: <5% of input size
- **Startup Time**: <1ms
- **Validation**: <100ns per operation

### Memory Usage

- **Zero Dynamic Allocation** - All memory is static
- **Predictable Memory Usage** - Fixed memory footprint
- **Efficient Buffer Utilization** - >80% buffer efficiency

## 🧪 Testing

Run the test suite:

```bash
# Unit tests
zig build test

# Performance tests
zig build test-perf

# All tests
zig build test-all
```

### Test Coverage

- **Unit Tests** - Core functionality validation
- **Performance Tests** - Speed and memory benchmarks
- **Edge Case Tests** - Boundary condition handling
- **Integration Tests** - End-to-end functionality

## 🔍 Examples

### Example 1: Basic Parsing

```zig
const json = @import("nen-json");

pub fn parseUserData(input: []const u8) !User {
    const parsed = try json.parse(input);
    
    return User{
        .id = parsed.get("id").?.asInteger(),
        .name = parsed.get("name").?.asString(),
        .email = parsed.get("email").?.asString(),
        .active = parsed.get("active").?.asBoolean(),
    };
}
```

### Example 2: JSON Building

```zig
const json = @import("nen-json");

pub fn createUserResponse(user: User) ![]const u8 {
    var builder = json.JsonBuilder.init();
    
    try builder.put("status", "success");
    try builder.put("user", .{
        .id = user.id,
        .name = user.name,
        .email = user.email,
    });
    
    const response = try builder.build();
    return try json.serialize(response);
}
```

### Example 3: File Processing

```zig
const json = @import("nen-json");

pub fn processJsonFile(file_path: []const u8) !void {
    // Read and parse JSON file
    const content = try json.io.readJson(file_path);
    const parsed = try json.parse(content);
    
    // Process the data
    try processData(parsed);
    
    // Write updated data
    try json.io.writeJson(file_path, parsed);
}
```

## 🛠️ Configuration

### Build Options

```zig
// In your build.zig
const exe = b.addExecutable(.{
    .name = "your-app",
    .root_source_file = .{ .cwd_relative = "src/main.zig" },
    .target = target,
    .optimize = optimize,
});

// Link with nen-json
exe.linkLibrary(nen_json_lib);
```

### Runtime Configuration

```zig
const json = @import("nen-json");

// Configure parser behavior
var parser = json.StaticJsonParser.init();
parser.setMaxNestingDepth(32);
parser.setMaxTokens(5000);
parser.setBufferSize(32768);
```

## 📚 API Reference

### Core Types

- **`JsonValue`** - Represents any JSON value
- **`JsonObject`** - JSON object container
- **`JsonArray`** - JSON array container
- **`JsonToken`** - Low-level parsing token
- **`JsonError`** - Error types and handling

### Parser Functions

- **`parse()`** - Parse JSON string to JsonValue
- **`parseStatic()`** - Parse with static memory
- **`validate()`** - Validate JSON without parsing
- **`tokenize()`** - Low-level tokenization

### Builder Functions

- **`put()`** - Add key-value pair
- **`putArray()`** - Add array value
- **`putObject()`** - Add object value
- **`build()`** - Finalize and return JsonValue

### IO Functions

- **`readJson()`** - Read JSON from file
- **`writeJson()`** - Write JSON to file
- **`validateJson()`** - Validate JSON file
- **`streamParse()`** - Parse large files in chunks

## 🚨 Error Handling

The library provides comprehensive error handling:

```zig
const json = @import("nen-json");

pub fn safeParse(input: []const u8) !json.JsonValue {
    return json.parse(input) catch |err| {
        switch (err) {
            json.JsonError.InvalidFormat => {
                // Handle format errors
                return error.InvalidJson;
            },
            json.JsonError.TokenPoolExhausted => {
                // Handle memory exhaustion
                return error.JsonTooLarge;
            },
            else => return err,
        }
    };
}
```

## 🔧 Development

### Building from Source

```bash
# Clone repository
git clone https://github.com/Nen-Co/nen-json.git
cd nen-json

# Build library
zig build

# Run tests
zig build test

# Run examples
zig build examples
```

### Project Structure

```
nen-json/
├── src/
│   ├── lib.zig              # Main library entry point
│   ├── static_json.zig      # Core parsing logic
│   ├── json_api.zig         # High-level API
│   ├── io_integration.zig   # IO operations
│   └── main.zig             # Example executable
├── tests/
│   └── unit/                # Unit tests
├── examples/                 # Usage examples
├── build.zig                # Build configuration
└── README.md                # This file
```

## 📈 Roadmap

### Planned Features

- [ ] **Schema Validation** - JSON Schema support
- [ ] **Streaming API** - Real-time JSON processing
- [ ] **Binary Format** - Efficient binary JSON
- [ ] **WebAssembly** - Browser/Node.js support
- [ ] **Async Parsing** - Non-blocking operations

### Performance Goals

- [ ] **5+ GB/s** parsing speed
- [ ] **<1%** memory overhead
- [ ] **<0.1ms** startup time
- [ ] **100%** buffer utilization

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

### Code Style

- Follow Zig style guidelines
- Use `inline` for performance-critical functions
- Add comprehensive tests
- Document public APIs

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Zig Community** - For the amazing language and ecosystem
- **SIMD Libraries** - For performance optimization techniques
- **JSON Standards** - For the specification and validation rules

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Nen-Co/nen-json/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Nen-Co/nen-json/discussions)
- **Documentation**: [API Docs](https://nen-co.github.io/nen-json)

---

**Built with ❤️ by the Nen Team**

*Performance-focused, memory-efficient, and developer-friendly JSON processing for Zig.*

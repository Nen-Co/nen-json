const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Main library module
    const lib = b.addModule("nen-json", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Version info removed for Zig 0.14.1 compatibility

    // Install library
    // b.installArtifact(lib); // Not needed for modules

    // Main executable for testing/demo
    const exe = b.addExecutable(.{
        .name = "nen-json",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.addImport("nen-json", lib);

    b.installArtifact(exe);

    // Unit tests
    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/unit/json_tests.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    unit_tests.root_module.addImport("nen-json", lib);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test-unit", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    // Performance tests
    const perf_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/performance/perf_tests.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    perf_tests.root_module.addImport("nen-json", lib);

    const run_perf_tests = b.addRunArtifact(perf_tests);
    const perf_step = b.step("test-performance", "Run performance tests");
    perf_step.dependOn(&run_perf_tests.step);

    // Benchmark tests
    const bench_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/benchmarks/bench_tests.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    bench_tests.root_module.addImport("nen-json", lib);

    const run_bench_tests = b.addRunArtifact(bench_tests);
    const bench_step = b.step("bench", "Run benchmark tests");
    bench_step.dependOn(&run_bench_tests.step);

    // All tests
    const all_tests_step = b.step("test-all", "Run all tests");
    all_tests_step.dependOn(&run_unit_tests.step);
    all_tests_step.dependOn(&run_perf_tests.step);
    all_tests_step.dependOn(&run_bench_tests.step);

    // Examples
    const examples = b.addExecutable(.{
        .name = "examples",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/basic_usage.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    examples.root_module.addImport("nen-json", lib);

    const run_examples = b.addRunArtifact(examples);
    const examples_step = b.step("examples", "Run examples");
    examples_step.dependOn(&run_examples.step);

    // Documentation
    // const docs_step = b.step("docs", "Generate documentation");
    // docs_step.dependOn(&docs.step); // Disabled for now

    // Package info
    // b.installArtifact(lib); // Not needed for modules
    b.installArtifact(exe);
}

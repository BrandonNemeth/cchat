const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create a shared module for common code (net.zig, protocol.zig)
    const zchat_mod = b.addModule("zchat", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    // Build the server executable
    const server_exe = b.addExecutable(.{
        .name = "zchat-server",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/server.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zchat", .module = zchat_mod },
            },
        }),
    });
    b.installArtifact(server_exe);

    // Build the client executable
    const client_exe = b.addExecutable(.{
        .name = "zchat-client",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/client.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zchat", .module = zchat_mod },
            },
        }),
    });
    b.installArtifact(client_exe);

    // Build the legacy main executable (for backwards compatibility)
    const main_exe = b.addExecutable(.{
        .name = "zchat",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zchat", .module = zchat_mod },
            },
        }),
    });
    b.installArtifact(main_exe);

    // Run step for server
    const server_step = b.step("server", "Run the chat server");
    const run_server = b.addRunArtifact(server_exe);
    run_server.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_server.addArgs(args);
    }
    server_step.dependOn(&run_server.step);

    // Run step for client
    const client_step = b.step("client", "Run the chat client");
    const run_client = b.addRunArtifact(client_exe);
    run_client.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_client.addArgs(args);
    }
    client_step.dependOn(&run_client.step);

    // Default run step (legacy main)
    const run_step = b.step("run", "Run the app (legacy main)");
    const run_main = b.addRunArtifact(main_exe);
    run_main.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_main.addArgs(args);
    }
    run_step.dependOn(&run_main.step);

    // Unit tests for the shared module
    const mod_tests = b.addTest(.{
        .root_module = zchat_mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    // Unit tests for server
    const server_tests = b.addTest(.{
        .root_module = server_exe.root_module,
    });
    const run_server_tests = b.addRunArtifact(server_tests);

    // Unit tests for client
    const client_tests = b.addTest(.{
        .root_module = client_exe.root_module,
    });
    const run_client_tests = b.addRunArtifact(client_tests);

    // Test step
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_server_tests.step);
    test_step.dependOn(&run_client_tests.step);
}

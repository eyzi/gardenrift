const builtin = @import("builtin");
const std = @import("std");

pub fn build(b: *std.Build) !void {
    const exe = try create_executable(b);
    try compile_shader(b, exe, "main.vert", "main.vert.spv");
    try compile_shader(b, exe, "main.frag", "main.frag.spv");
    try create_run_command(b, exe);
}

fn create_executable(b: *std.Build) !*std.Build.Step.Compile {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "gardenrift",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    try add_glfw(b, exe);
    try add_vulkan(b, exe);
    exe.linkLibC();

    b.installArtifact(exe);
    return exe;
}

fn add_glfw(b: *std.Build, exe: *std.Build.Step.Compile) !void {
    _ = b;
    // const glfw_dep = b.dependency("mach_glfw", .{});
    // exe.addModule("glfw", glfw_dep.module("mach-glfw"));
    exe.addIncludePath(.{ .path = "C:\\glfw-3.4.bin.WIN64\\include" });
    exe.addObjectFile(.{ .path = "C:\\glfw-3.4.bin.WIN64\\lib-mingw-w64\\glfw3.dll" });
    exe.addObjectFile(.{ .path = "C:\\glfw-3.4.bin.WIN64\\lib-mingw-w64\\libglfw3.a" });
    exe.addObjectFile(.{ .path = "C:\\glfw-3.4.bin.WIN64\\lib-mingw-w64\\libglfw3dll.a" });
}

fn add_vulkan(b: *std.Build, exe: *std.Build.Step.Compile) !void {
    _ = b;
    // const vulkan_dep = b.dependency("vulkan", .{});
    // exe.addModule("vulkan", vulkan_dep.module("vulkan-zig-generated"));
    exe.addIncludePath(.{ .path = "C:\\VulkanSDK\\1.3.275.0\\Include" });
    exe.addObjectFile(.{ .path = "C:\\VulkanSDK\\1.3.275.0\\Lib\\vulkan-1.lib" });
}

fn create_run_command(b: *std.Build, exe: *std.Build.Step.Compile) !void {
    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    run_cmd.addPathDir("C:\\glfw-3.4.bin.WIN64\\lib-mingw-w64\\");
    run_cmd.addPathDir("C:\\VulkanSDK\\1.3.275.0\\Lib\\");
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn compile_shader(b: *std.Build, exe: *std.Build.Step.Compile, input_file: []const u8, output_file: []const u8) !void {
    const dirname = "shaders";
    const full_in = try std.fs.path.join(b.allocator, &[_][]const u8{ dirname, input_file });
    const full_out = try std.fs.path.join(b.allocator, &[_][]const u8{ dirname, output_file });
    const run_cmd = b.addSystemCommand(&[_][]const u8{
        "glslc",
        "--target-env=vulkan1.1",
        "-o",
        full_out,
        full_in,
    });
    exe.step.dependOn(&run_cmd.step);
}

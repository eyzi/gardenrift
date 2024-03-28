const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;
const UniformBufferObject = @import("../types.zig").UniformBufferObject;

pub fn update(params: struct {
    index: u32,
    map: [*]UniformBufferObject,
    time: u64,
}) !void {
    var ubo: UniformBufferObject = .{};
    ubo.proj[0][0] *= -1;
    ubo.proj[3][2] = @mod(@as(f32, @floatFromInt(params.time)) / std.time.ns_per_s, 10.0) / 12.0;
    ubo.proj[3][3] = @mod(@as(f32, @floatFromInt(params.time)) / std.time.ns_per_s, 10.0) / 12.0;
    @memcpy(params.map, &[_]UniformBufferObject{ubo});
}

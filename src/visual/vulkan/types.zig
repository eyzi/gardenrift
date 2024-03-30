const glfwc = @import("./glfw-c.zig").c;

pub const QueueFamilyIndices = struct {
    graphics_family: ?u32 = null,
    present_family: ?u32 = null,
    transfer_family: ?u32 = null,
    compute_family: ?u32 = null,
};

pub const Vertex = struct {
    position: @Vector(3, f32),
    color: @Vector(3, f32),
    texCoord: @Vector(2, f32),
};

pub const UniformBufferObject = struct {
    model: [4]@Vector(4, f32) align(16) = .{
        .{ 1.0, 0.0, 0.0, 0.0 },
        .{ 0.0, 1.0, 0.0, 0.0 },
        .{ 0.0, 0.0, 1.0, 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    },
    view: [4]@Vector(4, f32) align(16) = .{
        .{ 1.0, 0.0, 0.0, 0.0 },
        .{ 0.0, 1.0, 0.0, 0.0 },
        .{ 0.0, 0.0, 1.0, 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    },
    proj: [4]@Vector(4, f32) align(16) = .{
        .{ 1.0, 0.0, 0.0, 0.0 },
        .{ 0.0, 1.0, 0.0, 0.0 },
        .{ 0.0, 0.0, 1.0, 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    },
};

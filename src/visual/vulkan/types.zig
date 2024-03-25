const glfwc = @import("./glfw-c.zig").c;

pub const QueueFamilyIndices = struct {
    graphicsFamily: ?u32 = null,
    presentFamily: ?u32 = null,
    transferFamily: ?u32 = null,
};

pub const Vertex = struct {
    position: [2]f32,
    color: [3]f32,
};

pub const BufferTuple = .{
    glfwc.VkBufferCreateInfo,
    glfwc.VkBuffer,
    glfwc.VkDeviceMemory,
};

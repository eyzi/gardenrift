const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;
const Vertex = @import("../types.zig").Vertex;

pub fn map_memory(comptime T: type, params: struct {
    device: glfwc.VkDevice,
    data: ?[]const T = null,
    buffer_create_info: glfwc.VkBufferCreateInfo,
    buffer_memory: glfwc.VkDeviceMemory,
    memcpy: bool = true,
}) ![*]T {
    var data: [*]T = undefined;
    if (glfwc.vkMapMemory(params.device, params.buffer_memory, 0, params.buffer_create_info.size, 0, @ptrCast(&data)) != glfwc.VK_SUCCESS) {
        return error.VulkanMemoryMapError;
    }

    if (params.memcpy) {
        if (params.data) |data_to_copy| {
            @memcpy(data, data_to_copy);
        } else {
            return error.VulkanMemcpyNoData;
        }
    }

    return data;
}

pub fn unmap_memory(params: struct {
    device: glfwc.VkDevice,
    buffer_memory: glfwc.VkDeviceMemory,
}) void {
    glfwc.vkUnmapMemory(params.device, params.buffer_memory);
}

const std = @import("std");
const vkc = @import("../vk-c.zig").c;
const Vertex = @import("../types.zig").Vertex;

pub fn map_memory(comptime T: type, params: struct {
    device: vkc.VkDevice,
    data: ?[]const T = null,
    buffer_create_info: vkc.VkBufferCreateInfo,
    buffer_memory: vkc.VkDeviceMemory,
    memcpy: bool = true,
}) ![*]T {
    var data: [*]T = undefined;
    if (vkc.vkMapMemory(params.device, params.buffer_memory, 0, params.buffer_create_info.size, 0, @ptrCast(&data)) != vkc.VK_SUCCESS) {
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
    device: vkc.VkDevice,
    buffer_memory: vkc.VkDeviceMemory,
}) void {
    vkc.vkUnmapMemory(params.device, params.buffer_memory);
}

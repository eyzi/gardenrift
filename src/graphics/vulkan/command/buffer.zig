const std = @import("std");
const vkc = @import("../vk-c.zig").c;

/// returns command buffer. needs to be destroyed.
pub fn create(params: struct {
    device: vkc.VkDevice,
    command_pool: vkc.VkCommandPool,
    n_buffers: usize,
    allocator: std.mem.Allocator,
}) ![]vkc.VkCommandBuffer {
    var buffers = try params.allocator.alloc(vkc.VkCommandBuffer, params.n_buffers);

    const allocation_info = vkc.VkCommandBufferAllocateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .commandPool = params.command_pool,
        .level = vkc.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = @as(u32, @intCast(buffers.len)),
        .pNext = null,
    };

    if (vkc.vkAllocateCommandBuffers(params.device, &allocation_info, buffers.ptr) != vkc.VK_SUCCESS) {
        return error.VulkanCommandBufferAllocateError;
    }

    return buffers;
}

pub fn destroy(params: struct {
    command_buffers: []vkc.VkCommandBuffer,
    allocator: std.mem.Allocator,
}) void {
    params.allocator.free(params.command_buffers);
}

pub fn free(params: struct {
    device: vkc.VkDevice,
    command_pool: vkc.VkCommandPool,
    command_buffers: []vkc.VkCommandBuffer,
}) void {
    vkc.vkFreeCommandBuffers(params.device, params.command_pool, @as(u32, @intCast(params.command_buffers.len)), params.command_buffers.ptr);
}

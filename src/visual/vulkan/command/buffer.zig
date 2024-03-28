const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;

/// returns command buffer. needs to be destroyed.
pub fn create(params: struct {
    device: glfwc.VkDevice,
    command_pool: glfwc.VkCommandPool,
    n_buffers: usize,
    allocator: std.mem.Allocator,
}) ![]glfwc.VkCommandBuffer {
    var buffers = try params.allocator.alloc(glfwc.VkCommandBuffer, params.n_buffers);

    const allocation_info = glfwc.VkCommandBufferAllocateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .commandPool = params.command_pool,
        .level = glfwc.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = @as(u32, @intCast(buffers.len)),
        .pNext = null,
    };

    if (glfwc.vkAllocateCommandBuffers(params.device, &allocation_info, buffers.ptr) != glfwc.VK_SUCCESS) {
        return error.VulkanCommandBufferAllocateError;
    }

    return buffers;
}

pub fn destroy(params: struct {
    command_buffers: []glfwc.VkCommandBuffer,
    allocator: std.mem.Allocator,
}) void {
    params.allocator.free(params.command_buffers);
}

pub fn free(params: struct {
    device: glfwc.VkDevice,
    command_pool: glfwc.VkCommandPool,
    command_buffers: []glfwc.VkCommandBuffer,
}) void {
    glfwc.vkFreeCommandBuffers(params.device, params.command_pool, @as(u32, @intCast(params.command_buffers.len)), params.command_buffers.ptr);
}

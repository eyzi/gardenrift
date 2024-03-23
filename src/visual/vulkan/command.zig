const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;
const queue = @import("./queue.zig");
const render = @import("./render.zig");
const swapchain = @import("./swapchain.zig");

/// returns command pool. needs to be destroyed.
pub fn create_pool(device: glfwc.VkDevice, queue_family_indices: queue.QueueFamilyIndices) !glfwc.VkCommandPool {
    const create_info = glfwc.VkCommandPoolCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .flags = glfwc.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        .queueFamilyIndex = queue_family_indices.graphicsFamily.?,
        .pNext = null,
    };

    var pool: glfwc.VkCommandPool = undefined;
    if (glfwc.vkCreateCommandPool(device, &create_info, null, &pool) != glfwc.VK_SUCCESS) {
        return error.VulkanCommandPoolCreateError;
    }

    return pool;
}

pub fn destroy_pool(device: glfwc.VkDevice, pool: glfwc.VkCommandPool) void {
    glfwc.vkDestroyCommandPool(device, pool, null);
}

/// returns command buffer. needs to be destroyed.
pub fn create_buffers(device: glfwc.VkDevice, pool: glfwc.VkCommandPool, n_buffers: usize, allocator: std.mem.Allocator) ![]glfwc.VkCommandBuffer {
    var buffers = try allocator.alloc(glfwc.VkCommandBuffer, n_buffers);

    const allocation_info = glfwc.VkCommandBufferAllocateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .commandPool = pool,
        .level = glfwc.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = @as(u32, @intCast(buffers.len)),
        .pNext = null,
    };

    if (glfwc.vkAllocateCommandBuffers(device, &allocation_info, buffers.ptr) != glfwc.VK_SUCCESS) {
        return error.VulkanCommandBufferAllocateError;
    }

    return buffers;
}

pub fn destroy_buffers(buffer: []glfwc.VkCommandBuffer, allocator: std.mem.Allocator) void {
    allocator.free(buffer);
}

pub fn reset(command_buffer: glfwc.VkCommandBuffer) !void {
    if (glfwc.vkResetCommandBuffer(command_buffer, 0) != glfwc.VK_SUCCESS) {
        return error.VulkanCommandBufferResetError;
    }
}

pub fn begin(command_buffer: glfwc.VkCommandBuffer) !void {
    const begin_info = glfwc.VkCommandBufferBeginInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = 0,
        .pInheritanceInfo = null,
        .pNext = null,
    };

    if (glfwc.vkBeginCommandBuffer(command_buffer, &begin_info) != glfwc.VK_SUCCESS) {
        return error.VulkanCommandBufferRecordError;
    }
}

pub fn end(command_buffer: glfwc.VkCommandBuffer) !void {
    if (glfwc.vkEndCommandBuffer(command_buffer) != glfwc.VK_SUCCESS) {
        return error.VulkanCommandBufferEndError;
    }
}

pub fn record_buffer(command_buffer: glfwc.VkCommandBuffer, graphics_pipeline: glfwc.VkPipeline, render_pass: glfwc.VkRenderPass, frame_buffer: glfwc.VkFramebuffer, extent: glfwc.VkExtent2D) !void {
    try begin(command_buffer);
    render.begin(render_pass, command_buffer, frame_buffer, extent);
    glfwc.vkCmdBindPipeline(command_buffer, glfwc.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipeline);
    glfwc.vkCmdSetViewport(command_buffer, 0, 1, &swapchain.create_viewport(extent));
    glfwc.vkCmdSetScissor(command_buffer, 0, 1, &swapchain.create_scissor(extent));
    glfwc.vkCmdDraw(command_buffer, 3, 1, 0, 0);
    render.end(command_buffer);
    try end(command_buffer);
}

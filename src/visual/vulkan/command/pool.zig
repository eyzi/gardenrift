const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;
const QueueFamilyIndices = @import("../types.zig").QueueFamilyIndices;

/// returns command pool. needs to be destroyed.
pub fn create(params: struct {
    device: glfwc.VkDevice,
    queue_family_indices: QueueFamilyIndices,
    flags: glfwc.VkCommandPoolCreateFlags = glfwc.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
}) !glfwc.VkCommandPool {
    const create_info = glfwc.VkCommandPoolCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .flags = params.flags,
        .queueFamilyIndex = params.queue_family_indices.graphicsFamily.?,
        .pNext = null,
    };

    var command_pool: glfwc.VkCommandPool = undefined;
    if (glfwc.vkCreateCommandPool(params.device, &create_info, null, &command_pool) != glfwc.VK_SUCCESS) {
        return error.VulkanCommandPoolCreateError;
    }

    return command_pool;
}

pub fn destroy(params: struct {
    device: glfwc.VkDevice,
    command_pool: glfwc.VkCommandPool,
}) void {
    glfwc.vkDestroyCommandPool(params.device, params.command_pool, null);
}

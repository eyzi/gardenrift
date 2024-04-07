const std = @import("std");
const vkc = @import("../vk-c.zig").c;
const QueueFamilyIndices = @import("../types.zig").QueueFamilyIndices;

/// returns command pool. needs to be destroyed.
pub fn create(params: struct {
    device: vkc.VkDevice,
    queue_family_indices: QueueFamilyIndices,
    flags: vkc.VkCommandPoolCreateFlags = vkc.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
}) !vkc.VkCommandPool {
    const create_info = vkc.VkCommandPoolCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .flags = params.flags,
        .queueFamilyIndex = params.queue_family_indices.graphics_family.?,
        .pNext = null,
    };

    var command_pool: vkc.VkCommandPool = undefined;
    if (vkc.vkCreateCommandPool(params.device, &create_info, null, &command_pool) != vkc.VK_SUCCESS) {
        return error.VulkanCommandPoolCreateError;
    }

    return command_pool;
}

pub fn destroy(params: struct {
    device: vkc.VkDevice,
    command_pool: vkc.VkCommandPool,
}) void {
    vkc.vkDestroyCommandPool(params.device, params.command_pool, null);
}

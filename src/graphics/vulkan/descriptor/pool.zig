const std = @import("std");
const vkc = @import("../vk-c.zig").c;

pub fn create(params: struct {
    device: vkc.VkDevice,
    max_frames: u32,
}) !vkc.VkDescriptorPool {
    const pool_sizes = [_]vkc.VkDescriptorPoolSize{
        .{
            .type = vkc.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
            .descriptorCount = params.max_frames,
        },
        .{
            .type = vkc.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
            .descriptorCount = params.max_frames,
        },
    };

    const create_info = vkc.VkDescriptorPoolCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .poolSizeCount = pool_sizes.len,
        .pPoolSizes = &pool_sizes,
        .maxSets = params.max_frames,
        .pNext = null,
        .flags = 0,
    };

    var pool: vkc.VkDescriptorPool = undefined;
    if (vkc.vkCreateDescriptorPool(params.device, &create_info, null, &pool) != vkc.VK_SUCCESS) {
        return error.VulkanDescriptorPoolCreateError;
    }

    return pool;
}

pub fn destroy(params: struct {
    device: vkc.VkDevice,
    descriptor_pool: vkc.VkDescriptorPool,
}) void {
    vkc.vkDestroyDescriptorPool(params.device, params.descriptor_pool, null);
}

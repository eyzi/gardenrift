const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;

pub fn create(params: struct {
    device: glfwc.VkDevice,
    max_frames: u32,
}) !glfwc.VkDescriptorPool {
    const pool_size = glfwc.VkDescriptorPoolSize{
        .type = glfwc.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = params.max_frames,
    };

    const create_info = glfwc.VkDescriptorPoolCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .poolSizeCount = 1,
        .pPoolSizes = &pool_size,
        .maxSets = params.max_frames,
        .pNext = null,
        .flags = 0,
    };

    var pool: glfwc.VkDescriptorPool = undefined;
    if (glfwc.vkCreateDescriptorPool(params.device, &create_info, null, &pool) != glfwc.VK_SUCCESS) {
        return error.VulkanDescriptorPoolCreateError;
    }

    return pool;
}

pub fn destroy(params: struct {
    device: glfwc.VkDevice,
    descriptor_pool: glfwc.VkDescriptorPool,
}) void {
    glfwc.vkDestroyDescriptorPool(params.device, params.descriptor_pool, null);
}

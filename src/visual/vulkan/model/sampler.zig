const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;
const physical_device = @import("../instance/physical-device.zig");

/// returns a sampler. needs to be destroyed.
pub fn create(params: struct {
    device: glfwc.VkDevice,
    physical_device: glfwc.VkPhysicalDevice,
}) !glfwc.VkSampler {
    const properties = try physical_device.get_properties(.{ .physical_device = params.physical_device });

    const create_info = glfwc.VkSamplerCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
        .magFilter = glfwc.VK_FILTER_LINEAR,
        .minFilter = glfwc.VK_FILTER_LINEAR,
        .addressModeU = glfwc.VK_SAMPLER_ADDRESS_MODE_REPEAT,
        .addressModeV = glfwc.VK_SAMPLER_ADDRESS_MODE_REPEAT,
        .addressModeW = glfwc.VK_SAMPLER_ADDRESS_MODE_REPEAT,
        .anisotropyEnable = glfwc.VK_TRUE,
        .maxAnisotropy = properties.limits.maxSamplerAnisotropy,
        .borderColor = glfwc.VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK,
        .unnormalizedCoordinates = glfwc.VK_FALSE,
        .compareEnable = glfwc.VK_FALSE,
        .compareOp = glfwc.VK_COMPARE_OP_ALWAYS,
        .mipmapMode = glfwc.VK_SAMPLER_MIPMAP_MODE_LINEAR,
        .mipLodBias = 0.0,
        .minLod = 0.0,
        .maxLod = 0.0,
        .flags = 0,
        .pNext = null,
    };

    var sampler: glfwc.VkSampler = undefined;
    if (glfwc.vkCreateSampler(params.device, &create_info, null, &sampler) != glfwc.VK_SUCCESS) {
        return error.VulkanSamplerCreateError;
    }
    return sampler;
}

pub fn destroy(params: struct {
    device: glfwc.VkDevice,
    sampler: glfwc.VkSampler,
}) void {
    glfwc.vkDestroySampler(params.device, params.sampler, null);
}

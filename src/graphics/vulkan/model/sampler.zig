const std = @import("std");
const vkc = @import("../vk-c.zig").c;
const physical_device = @import("../instance/physical-device.zig");

/// returns a sampler. needs to be destroyed.
pub fn create(params: struct {
    device: vkc.VkDevice,
    physical_device: vkc.VkPhysicalDevice,
    mip_levels: u32 = 1,
}) !vkc.VkSampler {
    const properties = try physical_device.get_properties(.{ .physical_device = params.physical_device });

    const create_info = vkc.VkSamplerCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
        .magFilter = vkc.VK_FILTER_LINEAR,
        .minFilter = vkc.VK_FILTER_LINEAR,
        .addressModeU = vkc.VK_SAMPLER_ADDRESS_MODE_REPEAT,
        .addressModeV = vkc.VK_SAMPLER_ADDRESS_MODE_REPEAT,
        .addressModeW = vkc.VK_SAMPLER_ADDRESS_MODE_REPEAT,
        .anisotropyEnable = vkc.VK_TRUE,
        .maxAnisotropy = properties.limits.maxSamplerAnisotropy,
        .borderColor = vkc.VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK,
        .unnormalizedCoordinates = vkc.VK_FALSE,
        .compareEnable = vkc.VK_FALSE,
        .compareOp = vkc.VK_COMPARE_OP_ALWAYS,
        .mipmapMode = vkc.VK_SAMPLER_MIPMAP_MODE_LINEAR,
        .mipLodBias = 0.0,
        .minLod = 0.0,
        .maxLod = @floatFromInt(params.mip_levels),
        .flags = 0,
        .pNext = null,
    };

    var sampler: vkc.VkSampler = undefined;
    if (vkc.vkCreateSampler(params.device, &create_info, null, &sampler) != vkc.VK_SUCCESS) {
        return error.VulkanSamplerCreateError;
    }
    return sampler;
}

pub fn destroy(params: struct {
    device: vkc.VkDevice,
    sampler: vkc.VkSampler,
}) void {
    vkc.vkDestroySampler(params.device, params.sampler, null);
}

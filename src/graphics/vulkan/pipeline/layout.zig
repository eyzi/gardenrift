const std = @import("std");
const vkc = @import("../vk-c.zig").c;

/// returns a pipeline layout. needs to be destroyed.
pub fn create(params: struct {
    device: vkc.VkDevice,
    descriptor_set_layout: vkc.VkDescriptorSetLayout,
}) !vkc.VkPipelineLayout {
    const create_info = vkc.VkPipelineLayoutCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
        .setLayoutCount = 1,
        .pSetLayouts = &[_]vkc.VkDescriptorSetLayout{params.descriptor_set_layout},
        .pushConstantRangeCount = 0,
        .pPushConstantRanges = null,
        .pNext = null,
        .flags = 0,
    };

    var layout: vkc.VkPipelineLayout = undefined;
    if (vkc.vkCreatePipelineLayout(params.device, &create_info, null, &layout) != vkc.VK_SUCCESS) {
        return error.VulkanPipelineLayoutCreateError;
    }

    return layout;
}

pub fn destroy(params: struct {
    device: vkc.VkDevice,
    layout: vkc.VkPipelineLayout,
}) void {
    vkc.vkDestroyPipelineLayout(params.device, params.layout, null);
}

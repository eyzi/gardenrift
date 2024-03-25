const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;

/// returns a pipeline layout. needs to be destroyed.
pub fn create(params: struct {
    device: glfwc.VkDevice,
}) !glfwc.VkPipelineLayout {
    const create_info = glfwc.VkPipelineLayoutCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
        .setLayoutCount = 0,
        .pSetLayouts = null,
        .pushConstantRangeCount = 0,
        .pPushConstantRanges = null,
        .pNext = null,
        .flags = 0,
    };

    var layout: glfwc.VkPipelineLayout = undefined;
    if (glfwc.vkCreatePipelineLayout(params.device, &create_info, null, &layout) != glfwc.VK_SUCCESS) {
        return error.VulkanPipelineLayoutCreateError;
    }

    return layout;
}

pub fn destroy(params: struct {
    device: glfwc.VkDevice,
    layout: glfwc.VkPipelineLayout,
}) void {
    glfwc.vkDestroyPipelineLayout(params.device, params.layout, null);
}

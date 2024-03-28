const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;
const vertex = @import("../model/vertex.zig");
const swapchain = @import("../swapchain/swapchain.zig");

/// returns a pipeline. needs to be destroyed.
pub fn create(params: struct {
    device: glfwc.VkDevice,
    shader_stages: [2]glfwc.VkPipelineShaderStageCreateInfo,
    layout: glfwc.VkPipelineLayout,
    renderpass: glfwc.VkRenderPass,
    extent: ?glfwc.VkExtent2D = null,
}) !glfwc.VkPipeline {
    const create_info = glfwc.VkGraphicsPipelineCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
        .stageCount = params.shader_stages.len,
        .pStages = &params.shader_stages,
        .layout = params.layout,
        .renderPass = params.renderpass,
        .subpass = 0,
        .pVertexInputState = &create_vertex_input_info(),
        .pInputAssemblyState = &create_input_assembly_info(),
        .pViewportState = &create_viewport_state_info(.{ .extent = params.extent }),
        .pRasterizationState = &create_rasterizer_info(),
        .pMultisampleState = &create_multisampling_info(),
        .pDepthStencilState = null,
        .pColorBlendState = &create_color_blending_info(),
        .pDynamicState = &create_dynamic_state_info(),
        .pTessellationState = null,
        .basePipelineHandle = null,
        .basePipelineIndex = 0,
        .pNext = null,
        .flags = 0,
    };

    var pipeline: glfwc.VkPipeline = undefined;
    if (glfwc.vkCreateGraphicsPipelines(params.device, @ptrCast(glfwc.VK_NULL_HANDLE), 1, &create_info, null, &pipeline) != glfwc.VK_SUCCESS) {
        return error.VulkanGraphicsPipelineCreateError;
    }

    return pipeline;
}

pub fn destroy(params: struct {
    device: glfwc.VkDevice,
    pipeline: glfwc.VkPipeline,
}) void {
    glfwc.vkDestroyPipeline(params.device, params.pipeline, null);
}

pub fn create_dynamic_state_info() glfwc.VkPipelineDynamicStateCreateInfo {
    const dynamic_states = [_]glfwc.VkDynamicState{
        glfwc.VK_DYNAMIC_STATE_VIEWPORT,
        glfwc.VK_DYNAMIC_STATE_SCISSOR,
    };
    return glfwc.VkPipelineDynamicStateCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
        .dynamicStateCount = dynamic_states.len,
        .pDynamicStates = &dynamic_states,
        .pNext = null,
        .flags = 0,
    };
}

pub fn create_vertex_input_info() glfwc.VkPipelineVertexInputStateCreateInfo {
    const binding_description = vertex.get_binding_description();
    const attribute_description = vertex.get_attribute_descriptions();
    return glfwc.VkPipelineVertexInputStateCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        .vertexBindingDescriptionCount = @as(u32, @intCast(binding_description.len)),
        .pVertexBindingDescriptions = binding_description.ptr,
        .vertexAttributeDescriptionCount = @as(u32, @intCast(attribute_description.len)),
        .pVertexAttributeDescriptions = attribute_description.ptr,
        .pNext = null,
        .flags = 0,
    };
}

pub fn create_input_assembly_info() glfwc.VkPipelineInputAssemblyStateCreateInfo {
    return glfwc.VkPipelineInputAssemblyStateCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
        .topology = glfwc.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
        .primitiveRestartEnable = glfwc.VK_FALSE,
        .pNext = null,
        .flags = 0,
    };
}

pub fn create_viewport_state_info(params: struct {
    extent: ?glfwc.VkExtent2D = null,
}) glfwc.VkPipelineViewportStateCreateInfo {
    return glfwc.VkPipelineViewportStateCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        .viewportCount = 1,
        .scissorCount = 1,
        .pViewports = if (params.extent != null) &swapchain.create_viewport(.{ .extent = params.extent.? }) else null,
        .pScissors = if (params.extent != null) &swapchain.create_scissor(.{ .extent = params.extent.? }) else null,
        .pNext = null,
        .flags = 0,
    };
}

pub fn create_rasterizer_info() glfwc.VkPipelineRasterizationStateCreateInfo {
    return glfwc.VkPipelineRasterizationStateCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
        .depthClampEnable = glfwc.VK_FALSE,
        .rasterizerDiscardEnable = glfwc.VK_FALSE,
        .polygonMode = glfwc.VK_POLYGON_MODE_FILL,
        .lineWidth = 1.0,
        .cullMode = glfwc.VK_CULL_MODE_BACK_BIT,
        .frontFace = glfwc.VK_FRONT_FACE_COUNTER_CLOCKWISE,
        .depthBiasEnable = glfwc.VK_FALSE,
        .depthBiasConstantFactor = 0.0,
        .depthBiasClamp = 0.0,
        .depthBiasSlopeFactor = 0.0,
        .pNext = null,
        .flags = 0,
    };
}

pub fn create_multisampling_info() glfwc.VkPipelineMultisampleStateCreateInfo {
    return glfwc.VkPipelineMultisampleStateCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
        .sampleShadingEnable = glfwc.VK_FALSE,
        .rasterizationSamples = glfwc.VK_SAMPLE_COUNT_1_BIT,
        .minSampleShading = 1.0,
        .pSampleMask = null,
        .alphaToCoverageEnable = glfwc.VK_FALSE,
        .alphaToOneEnable = glfwc.VK_FALSE,
        .pNext = null,
        .flags = 0,
    };
}

pub fn create_color_blending_info() glfwc.VkPipelineColorBlendStateCreateInfo {
    return glfwc.VkPipelineColorBlendStateCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
        .logicOpEnable = glfwc.VK_FALSE,
        .logicOp = glfwc.VK_LOGIC_OP_COPY,
        .attachmentCount = 1,
        .pAttachments = &glfwc.VkPipelineColorBlendAttachmentState{
            .colorWriteMask = glfwc.VK_COLOR_COMPONENT_R_BIT | glfwc.VK_COLOR_COMPONENT_G_BIT | glfwc.VK_COLOR_COMPONENT_B_BIT | glfwc.VK_COLOR_COMPONENT_A_BIT,
            .blendEnable = glfwc.VK_FALSE,
            .srcColorBlendFactor = glfwc.VK_BLEND_FACTOR_SRC_ALPHA,
            .dstColorBlendFactor = glfwc.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
            .colorBlendOp = glfwc.VK_BLEND_OP_ADD,
            .srcAlphaBlendFactor = glfwc.VK_BLEND_FACTOR_ONE,
            .dstAlphaBlendFactor = glfwc.VK_BLEND_FACTOR_ONE,
            .alphaBlendOp = glfwc.VK_BLEND_OP_ADD,
        },
        .blendConstants = [_]f32{ 0.0, 0.0, 0.0, 0.0 },
        .pNext = null,
        .flags = 0,
    };
}

const std = @import("std");
const vkc = @import("../vk-c.zig").c;
const vertex = @import("../model/vertex.zig");
const swapchain = @import("../swapchain/swapchain.zig");

/// returns a pipeline. needs to be destroyed.
pub fn create(params: struct {
    device: vkc.VkDevice,
    shader_stages: [2]vkc.VkPipelineShaderStageCreateInfo,
    layout: vkc.VkPipelineLayout,
    renderpass: vkc.VkRenderPass,
    extent: ?vkc.VkExtent2D = null,
    samples: u32 = vkc.VK_SAMPLE_COUNT_1_BIT,
}) !vkc.VkPipeline {
    const create_info = vkc.VkGraphicsPipelineCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
        .stageCount = params.shader_stages.len,
        .pStages = &params.shader_stages,
        .layout = params.layout,
        .renderPass = params.renderpass,
        .subpass = 0,
        .pVertexInputState = &create_vertex_input_info(),
        .pInputAssemblyState = &create_input_assembly_info(),
        .pViewportState = &create_viewport_state_info(.{ .extent = params.extent }),
        .pRasterizationState = &create_rasterizer_info(),
        .pMultisampleState = &create_multisampling_info(.{ .samples = params.samples }),
        .pDepthStencilState = &create_depth_stencil_info(),
        .pColorBlendState = &create_color_blending_info(),
        .pDynamicState = &create_dynamic_state_info(),
        .pTessellationState = null,
        .basePipelineHandle = null,
        .basePipelineIndex = 0,
        .pNext = null,
        .flags = 0,
    };

    var pipeline: vkc.VkPipeline = undefined;
    if (vkc.vkCreateGraphicsPipelines(params.device, @ptrCast(vkc.VK_NULL_HANDLE), 1, &create_info, null, &pipeline) != vkc.VK_SUCCESS) {
        return error.VulkanGraphicsPipelineCreateError;
    }

    return pipeline;
}

pub fn destroy(params: struct {
    device: vkc.VkDevice,
    pipeline: vkc.VkPipeline,
}) void {
    vkc.vkDestroyPipeline(params.device, params.pipeline, null);
}

pub fn create_dynamic_state_info() vkc.VkPipelineDynamicStateCreateInfo {
    const dynamic_states = [_]vkc.VkDynamicState{
        vkc.VK_DYNAMIC_STATE_VIEWPORT,
        vkc.VK_DYNAMIC_STATE_SCISSOR,
    };
    return vkc.VkPipelineDynamicStateCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
        .dynamicStateCount = dynamic_states.len,
        .pDynamicStates = &dynamic_states,
        .pNext = null,
        .flags = 0,
    };
}

pub fn create_vertex_input_info() vkc.VkPipelineVertexInputStateCreateInfo {
    const binding_description = vertex.get_binding_description();
    const attribute_description = vertex.get_attribute_descriptions();
    return vkc.VkPipelineVertexInputStateCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        .vertexBindingDescriptionCount = @as(u32, @intCast(binding_description.len)),
        .pVertexBindingDescriptions = binding_description.ptr,
        .vertexAttributeDescriptionCount = @as(u32, @intCast(attribute_description.len)),
        .pVertexAttributeDescriptions = attribute_description.ptr,
        .pNext = null,
        .flags = 0,
    };
}

pub fn create_input_assembly_info() vkc.VkPipelineInputAssemblyStateCreateInfo {
    return vkc.VkPipelineInputAssemblyStateCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
        .topology = vkc.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
        .primitiveRestartEnable = vkc.VK_FALSE,
        .pNext = null,
        .flags = 0,
    };
}

pub fn create_viewport_state_info(params: struct {
    extent: ?vkc.VkExtent2D = null,
}) vkc.VkPipelineViewportStateCreateInfo {
    return vkc.VkPipelineViewportStateCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        .viewportCount = 1,
        .scissorCount = 1,
        .pViewports = if (params.extent != null) &swapchain.create_viewport(.{ .extent = params.extent.? }) else null,
        .pScissors = if (params.extent != null) &swapchain.create_scissor(.{ .extent = params.extent.? }) else null,
        .pNext = null,
        .flags = 0,
    };
}

pub fn create_rasterizer_info() vkc.VkPipelineRasterizationStateCreateInfo {
    return vkc.VkPipelineRasterizationStateCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
        .depthClampEnable = vkc.VK_FALSE,
        .rasterizerDiscardEnable = vkc.VK_FALSE,
        .polygonMode = vkc.VK_POLYGON_MODE_FILL,
        .lineWidth = 1.0,
        .cullMode = vkc.VK_CULL_MODE_BACK_BIT,
        .frontFace = vkc.VK_FRONT_FACE_CLOCKWISE,
        .depthBiasEnable = vkc.VK_FALSE,
        .depthBiasConstantFactor = 0.0,
        .depthBiasClamp = 0.0,
        .depthBiasSlopeFactor = 0.0,
        .pNext = null,
        .flags = 0,
    };
}

pub fn create_multisampling_info(params: struct {
    samples: u32 = vkc.VK_SAMPLE_COUNT_1_BIT,
}) vkc.VkPipelineMultisampleStateCreateInfo {
    return vkc.VkPipelineMultisampleStateCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
        .sampleShadingEnable = vkc.VK_TRUE,
        .rasterizationSamples = params.samples,
        .minSampleShading = 0.2,
        .pSampleMask = null,
        .alphaToCoverageEnable = vkc.VK_FALSE,
        .alphaToOneEnable = vkc.VK_FALSE,
        .pNext = null,
        .flags = 0,
    };
}

pub fn create_depth_stencil_info() vkc.VkPipelineDepthStencilStateCreateInfo {
    return std.mem.zeroInit(vkc.VkPipelineDepthStencilStateCreateInfo, .{
        .sType = vkc.VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
        .depthTestEnable = vkc.VK_TRUE,
        .depthWriteEnable = vkc.VK_TRUE,
        .depthCompareOp = vkc.VK_COMPARE_OP_LESS,
        .depthBoundsTestEnable = vkc.VK_FALSE,
        .stencilTestEnable = vkc.VK_FALSE,
        .minDepthBounds = 0.0,
        .maxDepthBounds = 1.0,
    });
}

pub fn create_color_blending_info() vkc.VkPipelineColorBlendStateCreateInfo {
    return vkc.VkPipelineColorBlendStateCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
        .logicOpEnable = vkc.VK_FALSE,
        .logicOp = vkc.VK_LOGIC_OP_COPY,
        .attachmentCount = 1,
        .pAttachments = &vkc.VkPipelineColorBlendAttachmentState{
            .colorWriteMask = vkc.VK_COLOR_COMPONENT_R_BIT | vkc.VK_COLOR_COMPONENT_G_BIT | vkc.VK_COLOR_COMPONENT_B_BIT | vkc.VK_COLOR_COMPONENT_A_BIT,
            .blendEnable = vkc.VK_FALSE,
            .srcColorBlendFactor = vkc.VK_BLEND_FACTOR_SRC_ALPHA,
            .dstColorBlendFactor = vkc.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
            .colorBlendOp = vkc.VK_BLEND_OP_ADD,
            .srcAlphaBlendFactor = vkc.VK_BLEND_FACTOR_ONE,
            .dstAlphaBlendFactor = vkc.VK_BLEND_FACTOR_ONE,
            .alphaBlendOp = vkc.VK_BLEND_OP_ADD,
        },
        .blendConstants = [_]f32{ 0.0, 0.0, 0.0, 0.0 },
        .pNext = null,
        .flags = 0,
    };
}

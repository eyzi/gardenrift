const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;
const swapchain = @import("./swapchain.zig");

/// returns a pipeline. needs to be destroyed.
pub fn create(device: glfwc.VkDevice, shader_stages: [2]glfwc.VkPipelineShaderStageCreateInfo, layout: glfwc.VkPipelineLayout, render_pass: glfwc.VkRenderPass, extent: glfwc.VkExtent2D) !glfwc.VkPipeline {
    const create_info = glfwc.VkGraphicsPipelineCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
        .stageCount = shader_stages.len,
        .pStages = &shader_stages,
        .layout = layout,
        .renderPass = render_pass,
        .subpass = 0,
        .pVertexInputState = &create_vertex_input_info(),
        .pInputAssemblyState = &create_input_assembly_info(),
        .pViewportState = &create_viewport_state_info(extent),
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
    if (glfwc.vkCreateGraphicsPipelines(device, @ptrCast(glfwc.VK_NULL_HANDLE), 1, &create_info, null, &pipeline) != glfwc.VK_SUCCESS) {
        return error.VulkanGraphicsPipelineCreateError;
    }

    return pipeline;
}

pub fn destroy(device: glfwc.VkDevice, pipeline: glfwc.VkPipeline) void {
    glfwc.vkDestroyPipeline(device, pipeline, null);
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
    return glfwc.VkPipelineVertexInputStateCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        .vertexBindingDescriptionCount = 0,
        .pVertexBindingDescriptions = null,
        .vertexAttributeDescriptionCount = 0,
        .pVertexAttributeDescriptions = null,
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

pub fn create_viewport_state_info(extent: glfwc.VkExtent2D) glfwc.VkPipelineViewportStateCreateInfo {
    return glfwc.VkPipelineViewportStateCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        .viewportCount = 1,
        .scissorCount = 1,
        .pViewports = &swapchain.create_viewport(extent),
        .pScissors = &swapchain.create_scissor(extent),
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
        .frontFace = glfwc.VK_FRONT_FACE_CLOCKWISE,
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

/// returns pipeline layout. needs to be destroyed.
pub fn create_layout(device: glfwc.VkDevice) !glfwc.VkPipelineLayout {
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
    if (glfwc.vkCreatePipelineLayout(device, &create_info, null, &layout) != glfwc.VK_SUCCESS) {
        return error.VulkanPipelineLayoutCreateError;
    }

    return layout;
}

pub fn destroy_layout(device: glfwc.VkDevice, layout: glfwc.VkPipelineLayout) void {
    glfwc.vkDestroyPipelineLayout(device, layout, null);
}

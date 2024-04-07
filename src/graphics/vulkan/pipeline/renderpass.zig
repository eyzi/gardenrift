const std = @import("std");
const vkc = @import("../vk-c.zig").c;

/// returns a render pass. needs to be destroyed.
pub fn create(params: struct {
    device: vkc.VkDevice,
    surface_format: vkc.VkSurfaceFormatKHR,
    depth_format: vkc.VkFormat,
    samples: u32 = vkc.VK_SAMPLE_COUNT_1_BIT,
}) !vkc.VkRenderPass {
    const color_attachment = vkc.VkAttachmentDescription{
        .format = params.surface_format.format,
        .samples = params.samples,
        .loadOp = vkc.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = vkc.VK_ATTACHMENT_STORE_OP_STORE,
        .stencilLoadOp = vkc.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        .stencilStoreOp = vkc.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .initialLayout = vkc.VK_IMAGE_LAYOUT_UNDEFINED,
        .finalLayout = vkc.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        .flags = 0,
    };

    const color_attachment_ref = vkc.VkAttachmentReference{
        .attachment = 0,
        .layout = vkc.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
    };

    const depth_attachment = vkc.VkAttachmentDescription{
        .format = params.depth_format,
        .samples = params.samples,
        .loadOp = vkc.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = vkc.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .stencilLoadOp = vkc.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        .stencilStoreOp = vkc.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .initialLayout = vkc.VK_IMAGE_LAYOUT_UNDEFINED,
        .finalLayout = vkc.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        .flags = 0,
    };

    const depth_attachment_ref = vkc.VkAttachmentReference{
        .attachment = 1,
        .layout = vkc.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
    };

    const color_resolve_attachment = vkc.VkAttachmentDescription{
        .format = params.surface_format.format,
        .samples = vkc.VK_SAMPLE_COUNT_1_BIT,
        .loadOp = vkc.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        .storeOp = vkc.VK_ATTACHMENT_STORE_OP_STORE,
        .stencilLoadOp = vkc.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        .stencilStoreOp = vkc.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .initialLayout = vkc.VK_IMAGE_LAYOUT_UNDEFINED,
        .finalLayout = vkc.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
        .flags = 0,
    };

    const color_attachment_resolve_ref = vkc.VkAttachmentReference{
        .attachment = 2,
        .layout = vkc.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
    };

    const subpass = vkc.VkSubpassDescription{
        .pipelineBindPoint = vkc.VK_PIPELINE_BIND_POINT_GRAPHICS,
        .colorAttachmentCount = 1,
        .pColorAttachments = &color_attachment_ref,
        .inputAttachmentCount = 0,
        .pInputAttachments = null,
        .pResolveAttachments = &color_attachment_resolve_ref,
        .pDepthStencilAttachment = &depth_attachment_ref,
        .preserveAttachmentCount = 0,
        .pPreserveAttachments = null,
        .flags = 0,
    };

    const dependency = vkc.VkSubpassDependency{
        .srcSubpass = vkc.VK_SUBPASS_EXTERNAL,
        .dstSubpass = 0,
        .srcStageMask = vkc.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | vkc.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
        .srcAccessMask = 0,
        .dstStageMask = vkc.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | vkc.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
        .dstAccessMask = vkc.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT | vkc.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
        .dependencyFlags = 0,
    };

    const attachments = [_]vkc.VkAttachmentDescription{
        color_attachment,
        depth_attachment,
        color_resolve_attachment,
    };

    const create_info = vkc.VkRenderPassCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .attachmentCount = attachments.len,
        .pAttachments = &attachments,
        .subpassCount = 1,
        .pSubpasses = &subpass,
        .dependencyCount = 1,
        .pDependencies = &dependency,
        .pNext = null,
        .flags = 0,
    };

    var renderpass: vkc.VkRenderPass = undefined;
    if (vkc.vkCreateRenderPass(params.device, &create_info, null, &renderpass) != vkc.VK_SUCCESS) {
        return error.VulkanRenderPassCreateError;
    }

    return renderpass;
}

pub fn destroy(params: struct {
    device: vkc.VkDevice,
    renderpass: vkc.VkRenderPass,
}) void {
    vkc.vkDestroyRenderPass(params.device, params.renderpass, null);
}

pub fn begin(params: struct {
    renderpass: vkc.VkRenderPass,
    command_buffer: vkc.VkCommandBuffer,
    frame_buffer: vkc.VkFramebuffer,
    extent: vkc.VkExtent2D,
    clear_values: []const vkc.VkClearValue,
}) void {
    const pass_info = vkc.VkRenderPassBeginInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
        .renderPass = params.renderpass,
        .framebuffer = params.frame_buffer,
        .renderArea = .{
            .offset = vkc.VkOffset2D{
                .x = 0,
                .y = 0,
            },
            .extent = params.extent,
        },
        .clearValueCount = @as(u32, @intCast(params.clear_values.len)),
        .pClearValues = params.clear_values.ptr,
        .pNext = null,
    };

    vkc.vkCmdBeginRenderPass(params.command_buffer, &pass_info, vkc.VK_SUBPASS_CONTENTS_INLINE);
}

pub fn end(params: struct {
    command_buffer: vkc.VkCommandBuffer,
}) void {
    vkc.vkCmdEndRenderPass(params.command_buffer);
}

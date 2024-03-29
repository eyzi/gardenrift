const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;

/// returns a render pass. needs to be destroyed.
pub fn create(params: struct {
    device: glfwc.VkDevice,
    surface_format: glfwc.VkSurfaceFormatKHR,
    depth_format: glfwc.VkFormat,
}) !glfwc.VkRenderPass {
    const color_attachment = glfwc.VkAttachmentDescription{
        .format = params.surface_format.format,
        .samples = glfwc.VK_SAMPLE_COUNT_1_BIT,
        .loadOp = glfwc.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = glfwc.VK_ATTACHMENT_STORE_OP_STORE,
        .stencilLoadOp = glfwc.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        .stencilStoreOp = glfwc.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .initialLayout = glfwc.VK_IMAGE_LAYOUT_UNDEFINED,
        .finalLayout = glfwc.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
        .flags = 0,
    };

    const color_attachment_ref = glfwc.VkAttachmentReference{
        .attachment = 0,
        .layout = glfwc.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
    };

    const depth_attachment = glfwc.VkAttachmentDescription{
        .format = params.depth_format,
        .samples = glfwc.VK_SAMPLE_COUNT_1_BIT,
        .loadOp = glfwc.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = glfwc.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .stencilLoadOp = glfwc.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        .stencilStoreOp = glfwc.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .initialLayout = glfwc.VK_IMAGE_LAYOUT_UNDEFINED,
        .finalLayout = glfwc.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        .flags = 0,
    };

    const depth_attachment_ref = glfwc.VkAttachmentReference{
        .attachment = 1,
        .layout = glfwc.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
    };

    const subpass = glfwc.VkSubpassDescription{
        .pipelineBindPoint = glfwc.VK_PIPELINE_BIND_POINT_GRAPHICS,
        .colorAttachmentCount = 1,
        .pColorAttachments = &color_attachment_ref,
        .inputAttachmentCount = 0,
        .pInputAttachments = null,
        .pResolveAttachments = null,
        .pDepthStencilAttachment = &depth_attachment_ref,
        .preserveAttachmentCount = 0,
        .pPreserveAttachments = null,
        .flags = 0,
    };

    const dependency = glfwc.VkSubpassDependency{
        .srcSubpass = glfwc.VK_SUBPASS_EXTERNAL,
        .dstSubpass = 0,
        .srcStageMask = glfwc.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | glfwc.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
        .srcAccessMask = 0,
        .dstStageMask = glfwc.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | glfwc.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
        .dstAccessMask = glfwc.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT | glfwc.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
        .dependencyFlags = 0,
    };

    const attachments = [_]glfwc.VkAttachmentDescription{
        color_attachment,
        depth_attachment,
    };

    const create_info = glfwc.VkRenderPassCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .attachmentCount = attachments.len,
        .pAttachments = &attachments,
        .subpassCount = 1,
        .pSubpasses = &subpass,
        .dependencyCount = 1,
        .pDependencies = &dependency,
        .pNext = null,
        .flags = 0,
    };

    var renderpass: glfwc.VkRenderPass = undefined;
    if (glfwc.vkCreateRenderPass(params.device, &create_info, null, &renderpass) != glfwc.VK_SUCCESS) {
        return error.VulkanRenderPassCreateError;
    }

    return renderpass;
}

pub fn destroy(params: struct {
    device: glfwc.VkDevice,
    renderpass: glfwc.VkRenderPass,
}) void {
    glfwc.vkDestroyRenderPass(params.device, params.renderpass, null);
}

pub fn begin(params: struct {
    renderpass: glfwc.VkRenderPass,
    command_buffer: glfwc.VkCommandBuffer,
    frame_buffer: glfwc.VkFramebuffer,
    extent: glfwc.VkExtent2D,
    clear_values: []const glfwc.VkClearValue,
}) void {
    const pass_info = glfwc.VkRenderPassBeginInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
        .renderPass = params.renderpass,
        .framebuffer = params.frame_buffer,
        .renderArea = .{
            .offset = glfwc.VkOffset2D{
                .x = 0,
                .y = 0,
            },
            .extent = params.extent,
        },
        .clearValueCount = @as(u32, @intCast(params.clear_values.len)),
        .pClearValues = params.clear_values.ptr,
        .pNext = null,
    };

    glfwc.vkCmdBeginRenderPass(params.command_buffer, &pass_info, glfwc.VK_SUBPASS_CONTENTS_INLINE);
}

pub fn end(params: struct {
    command_buffer: glfwc.VkCommandBuffer,
}) void {
    glfwc.vkCmdEndRenderPass(params.command_buffer);
}

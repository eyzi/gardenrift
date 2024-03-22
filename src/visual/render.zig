const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;
const command = @import("./command.zig");
const swapchain = @import("./swapchain.zig");

/// returns a render pass. needs to be destroyed.
pub fn create_render_pass(device: glfwc.VkDevice, surface_format: glfwc.VkSurfaceFormatKHR) !glfwc.VkRenderPass {
    const color_attachment = glfwc.VkAttachmentDescription{
        .format = surface_format.format,
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

    const subpass = glfwc.VkSubpassDescription{
        .pipelineBindPoint = glfwc.VK_PIPELINE_BIND_POINT_GRAPHICS,
        .colorAttachmentCount = 1,
        .pColorAttachments = &color_attachment_ref,
        .inputAttachmentCount = 0,
        .pInputAttachments = null,
        .pResolveAttachments = null,
        .pDepthStencilAttachment = null,
        .preserveAttachmentCount = 0,
        .pPreserveAttachments = null,
        .flags = 0,
    };

    const dependency = glfwc.VkSubpassDependency{
        .srcSubpass = glfwc.VK_SUBPASS_EXTERNAL,
        .dstSubpass = 0,
        .srcStageMask = glfwc.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
        .srcAccessMask = 0,
        .dstStageMask = glfwc.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
        .dstAccessMask = glfwc.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
        .dependencyFlags = 0,
    };

    const create_info = glfwc.VkRenderPassCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .attachmentCount = 1,
        .pAttachments = &color_attachment,
        .subpassCount = 1,
        .pSubpasses = &subpass,
        .dependencyCount = 1,
        .pDependencies = &dependency,
        .pNext = null,
        .flags = 0,
    };

    var render_pass: glfwc.VkRenderPass = undefined;
    if (glfwc.vkCreateRenderPass(device, &create_info, null, &render_pass) != glfwc.VK_SUCCESS) {
        return error.VulkanRenderPassCreateError;
    }

    return render_pass;
}

pub fn destroy_render_pass(device: glfwc.VkDevice, render_pass: glfwc.VkRenderPass) void {
    glfwc.vkDestroyRenderPass(device, render_pass, null);
}

pub fn begin(render_pass: glfwc.VkRenderPass, command_buffer: glfwc.VkCommandBuffer, frame_buffer: glfwc.VkFramebuffer, extent: glfwc.VkExtent2D) void {
    const pass_info = glfwc.VkRenderPassBeginInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
        .renderPass = render_pass,
        .framebuffer = frame_buffer,
        .renderArea = .{
            .offset = glfwc.VkOffset2D{
                .x = 0,
                .y = 0,
            },
            .extent = extent,
        },
        .clearValueCount = 1,
        .pClearValues = &glfwc.VkClearValue{
            .color = glfwc.VkClearColorValue{
                .float32 = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            },
        },
        .pNext = null,
    };

    glfwc.vkCmdBeginRenderPass(command_buffer, &pass_info, glfwc.VK_SUBPASS_CONTENTS_INLINE);
}

pub fn end(command_buffer: glfwc.VkCommandBuffer) void {
    glfwc.vkCmdEndRenderPass(command_buffer);
}

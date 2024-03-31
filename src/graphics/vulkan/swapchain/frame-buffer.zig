pub const std = @import("std");
pub const glfwc = @import("../glfw-c.zig").c;

/// returns frame buffers. needs to be deallocated and destroyed
pub fn create(params: struct {
    device: glfwc.VkDevice,
    image_views: []glfwc.VkImageView,
    color_image_view: glfwc.VkImageView,
    depth_image_view: glfwc.VkImageView,
    renderpass: glfwc.VkRenderPass,
    extent: glfwc.VkExtent2D,
    allocator: std.mem.Allocator,
}) ![]glfwc.VkFramebuffer {
    var frame_buffers = try params.allocator.alloc(glfwc.VkFramebuffer, params.image_views.len);

    for (params.image_views, 0..) |image_view, i| {
        // order is important here, apparently. should be reverse order of renderpass array
        const attachments = [_]glfwc.VkImageView{
            params.color_image_view,
            params.depth_image_view,
            image_view,
        };
        const create_info = glfwc.VkFramebufferCreateInfo{
            .sType = glfwc.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .renderPass = params.renderpass,
            .attachmentCount = attachments.len,
            .pAttachments = &attachments,
            .width = params.extent.width,
            .height = params.extent.height,
            .layers = 1,
            .pNext = null,
            .flags = 0,
        };

        if (glfwc.vkCreateFramebuffer(params.device, &create_info, null, &frame_buffers[i]) != glfwc.VK_SUCCESS) {
            return error.VulkanFrameBuffersCreateError;
        }
    }

    return frame_buffers;
}

pub fn destroy(params: struct {
    device: glfwc.VkDevice,
    frame_buffers: []glfwc.VkFramebuffer,
    allocator: std.mem.Allocator,
}) void {
    for (params.frame_buffers) |frame_buffer| {
        glfwc.vkDestroyFramebuffer(params.device, frame_buffer, null);
    }
    params.allocator.free(params.frame_buffers);
}

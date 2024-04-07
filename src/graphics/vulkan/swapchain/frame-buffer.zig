pub const std = @import("std");
const vkc = @import("../vk-c.zig").c;

/// returns frame buffers. needs to be deallocated and destroyed
pub fn create(params: struct {
    device: vkc.VkDevice,
    image_views: []vkc.VkImageView,
    color_image_view: vkc.VkImageView,
    depth_image_view: vkc.VkImageView,
    renderpass: vkc.VkRenderPass,
    extent: vkc.VkExtent2D,
    allocator: std.mem.Allocator,
}) ![]vkc.VkFramebuffer {
    var frame_buffers = try params.allocator.alloc(vkc.VkFramebuffer, params.image_views.len);

    for (params.image_views, 0..) |image_view, i| {
        // order is important here, apparently. should be reverse order of renderpass array
        const attachments = [_]vkc.VkImageView{
            params.color_image_view,
            params.depth_image_view,
            image_view,
        };
        const create_info = vkc.VkFramebufferCreateInfo{
            .sType = vkc.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .renderPass = params.renderpass,
            .attachmentCount = attachments.len,
            .pAttachments = &attachments,
            .width = params.extent.width,
            .height = params.extent.height,
            .layers = 1,
            .pNext = null,
            .flags = 0,
        };

        if (vkc.vkCreateFramebuffer(params.device, &create_info, null, &frame_buffers[i]) != vkc.VK_SUCCESS) {
            return error.VulkanFrameBuffersCreateError;
        }
    }

    return frame_buffers;
}

pub fn destroy(params: struct {
    device: vkc.VkDevice,
    frame_buffers: []vkc.VkFramebuffer,
    allocator: std.mem.Allocator,
}) void {
    for (params.frame_buffers) |frame_buffer| {
        vkc.vkDestroyFramebuffer(params.device, frame_buffer, null);
    }
    params.allocator.free(params.frame_buffers);
}

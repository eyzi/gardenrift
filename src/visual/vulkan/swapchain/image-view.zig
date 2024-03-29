const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;

/// returns image view. needs to be destroyed.
pub fn create(params: struct {
    device: glfwc.VkDevice,
    image: glfwc.VkImage,
    format: glfwc.VkFormat,
    aspect_mask: glfwc.VkImageAspectFlags = glfwc.VK_IMAGE_ASPECT_COLOR_BIT,
}) !glfwc.VkImageView {
    const create_info = glfwc.VkImageViewCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
        .image = params.image,
        .viewType = glfwc.VK_IMAGE_VIEW_TYPE_2D,
        .format = params.format,
        .components = .{
            .r = glfwc.VK_COMPONENT_SWIZZLE_IDENTITY,
            .g = glfwc.VK_COMPONENT_SWIZZLE_IDENTITY,
            .b = glfwc.VK_COMPONENT_SWIZZLE_IDENTITY,
            .a = glfwc.VK_COMPONENT_SWIZZLE_IDENTITY,
        },
        .subresourceRange = .{
            .aspectMask = params.aspect_mask,
            .baseMipLevel = 0,
            .levelCount = 1,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
        .pNext = null,
        .flags = 0,
    };

    var image_view: glfwc.VkImageView = undefined;
    if (glfwc.vkCreateImageView(params.device, &create_info, null, &image_view) != glfwc.VK_SUCCESS) {
        return error.VulkanImageViewCreateError;
    }
    return image_view;
}

pub fn destroy(params: struct {
    device: glfwc.VkDevice,
    image_view: glfwc.VkImageView,
}) void {
    glfwc.vkDestroyImageView(params.device, params.image_view, null);
}

/// returns image views using allocator. needs to be destroyed.
pub fn create_many(params: struct {
    device: glfwc.VkDevice,
    images: []glfwc.VkImage,
    format: glfwc.VkFormat,
    allocator: std.mem.Allocator,
}) ![]glfwc.VkImageView {
    var image_views = try params.allocator.alloc(glfwc.VkImageView, params.images.len);
    for (params.images, 0..) |image, i| {
        image_views[i] = try create(.{
            .device = params.device,
            .image = image,
            .format = params.format,
        });
    }

    return image_views;
}

pub fn destroy_many(params: struct {
    device: glfwc.VkDevice,
    image_views: []glfwc.VkImageView,
    allocator: std.mem.Allocator,
}) void {
    for (params.image_views) |image_view| {
        destroy(.{ .device = params.device, .image_view = image_view });
    }
    params.allocator.free(params.image_views);
}

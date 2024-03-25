const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;

/// returns image views using allocator. needs to be destroyed.
pub fn create(params: struct {
    device: glfwc.VkDevice,
    images: []glfwc.VkImage,
    surface_format: glfwc.VkSurfaceFormatKHR,
    allocator: std.mem.Allocator,
}) ![]glfwc.VkImageView {
    var image_views = try params.allocator.alloc(glfwc.VkImageView, params.images.len);
    for (params.images, 0..) |image, i| {
        const create_info = glfwc.VkImageViewCreateInfo{
            .sType = glfwc.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
            .image = image,
            .viewType = glfwc.VK_IMAGE_VIEW_TYPE_2D,
            .format = params.surface_format.format,
            .components = .{
                .r = glfwc.VK_COMPONENT_SWIZZLE_IDENTITY,
                .g = glfwc.VK_COMPONENT_SWIZZLE_IDENTITY,
                .b = glfwc.VK_COMPONENT_SWIZZLE_IDENTITY,
                .a = glfwc.VK_COMPONENT_SWIZZLE_IDENTITY,
            },
            .subresourceRange = .{
                .aspectMask = glfwc.VK_IMAGE_ASPECT_COLOR_BIT,
                .baseMipLevel = 0,
                .levelCount = 1,
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
            .pNext = null,
            .flags = 0,
        };
        if (glfwc.vkCreateImageView(params.device, &create_info, null, &image_views[i]) != glfwc.VK_SUCCESS) {
            return error.VulkanImageViewCreateError;
        }
    }

    return image_views;
}

pub fn destroy(params: struct {
    device: glfwc.VkDevice,
    image_views: []glfwc.VkImageView,
    allocator: std.mem.Allocator,
}) void {
    for (params.image_views) |image_view| {
        glfwc.vkDestroyImageView(params.device, image_view, null);
    }
    params.allocator.free(params.image_views);
}

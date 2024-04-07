const std = @import("std");
const vkc = @import("../vk-c.zig").c;

/// returns image view. needs to be destroyed.
pub fn create(params: struct {
    device: vkc.VkDevice,
    image: vkc.VkImage,
    format: vkc.VkFormat,
    aspect_mask: vkc.VkImageAspectFlags = vkc.VK_IMAGE_ASPECT_COLOR_BIT,
    mip_levels: u32 = 1,
}) !vkc.VkImageView {
    const create_info = vkc.VkImageViewCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
        .image = params.image,
        .viewType = vkc.VK_IMAGE_VIEW_TYPE_2D,
        .format = params.format,
        .components = .{
            .r = vkc.VK_COMPONENT_SWIZZLE_IDENTITY,
            .g = vkc.VK_COMPONENT_SWIZZLE_IDENTITY,
            .b = vkc.VK_COMPONENT_SWIZZLE_IDENTITY,
            .a = vkc.VK_COMPONENT_SWIZZLE_IDENTITY,
        },
        .subresourceRange = .{
            .aspectMask = params.aspect_mask,
            .baseMipLevel = 0,
            .levelCount = params.mip_levels,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
        .pNext = null,
        .flags = 0,
    };

    var image_view: vkc.VkImageView = undefined;
    if (vkc.vkCreateImageView(params.device, &create_info, null, &image_view) != vkc.VK_SUCCESS) {
        return error.VulkanImageViewCreateError;
    }
    return image_view;
}

pub fn destroy(params: struct {
    device: vkc.VkDevice,
    image_view: vkc.VkImageView,
}) void {
    vkc.vkDestroyImageView(params.device, params.image_view, null);
}

/// returns image views using allocator. needs to be destroyed.
pub fn create_many(params: struct {
    device: vkc.VkDevice,
    images: []vkc.VkImage,
    format: vkc.VkFormat,
    allocator: std.mem.Allocator,
}) ![]vkc.VkImageView {
    var image_views = try params.allocator.alloc(vkc.VkImageView, params.images.len);
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
    device: vkc.VkDevice,
    image_views: []vkc.VkImageView,
    allocator: std.mem.Allocator,
}) void {
    for (params.image_views) |image_view| {
        destroy(.{ .device = params.device, .image_view = image_view });
    }
    params.allocator.free(params.image_views);
}

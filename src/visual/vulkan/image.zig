const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;

/// returns images using allocator. needs to be deallocated.
///
/// NOTE:   The images were created by the implementation for the swap chain and they will be automatically
///         cleaned up once the swap chain has been destroyed, therefore we don't need to add any cleanup code.
pub fn create(device: glfwc.VkDevice, swapchain: glfwc.VkSwapchainKHR, allocator: std.mem.Allocator) ![]glfwc.VkImage {
    var n_images: u32 = undefined;
    if (glfwc.vkGetSwapchainImagesKHR(device, swapchain, &n_images, null) != glfwc.VK_SUCCESS) {
        return error.VulkanSwapchainImageError;
    }

    var images = try allocator.alloc(glfwc.VkImage, n_images);

    if (glfwc.vkGetSwapchainImagesKHR(device, swapchain, &n_images, images.ptr) != glfwc.VK_SUCCESS) {
        return error.VulkanSwapchainImageError;
    }

    return images;
}

/// possibly not needed to be called
pub fn destroy(device: glfwc.VkDevice, images: []glfwc.VkImage, allocator: std.mem.Allocator) void {
    for (images) |image| {
        glfwc.vkDestroyImage(device, image, null);
    }
    allocator.free(images);
}

/// returns image views using allocator. needs to be destroyed.
pub fn create_views(device: glfwc.VkDevice, images: []glfwc.VkImage, surface_format: glfwc.VkSurfaceFormatKHR, allocator: std.mem.Allocator) ![]glfwc.VkImageView {
    var image_views = try allocator.alloc(glfwc.VkImageView, images.len);
    for (images, 0..) |image, i| {
        const create_info = glfwc.VkImageViewCreateInfo{
            .sType = glfwc.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
            .image = image,
            .viewType = glfwc.VK_IMAGE_VIEW_TYPE_2D,
            .format = surface_format.format,
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
        if (glfwc.vkCreateImageView(device, &create_info, null, &image_views[i]) != glfwc.VK_SUCCESS) {
            return error.VulkanImageViewCreateError;
        }
    }

    return image_views;
}

pub fn destroy_views(device: glfwc.VkDevice, image_views: []glfwc.VkImageView, allocator: std.mem.Allocator) void {
    for (image_views) |image_view| {
        glfwc.vkDestroyImageView(device, image_view, null);
    }
    allocator.free(image_views);
}

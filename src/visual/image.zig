const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;

/// returns images. needs to be deallocated.
pub fn create(device: glfwc.VkDevice, swapchain: glfwc.VkSwapchainKHR, allocator: std.mem.Allocator) ![]glfwc.VkImage {
    var image_count: u32 = undefined;
    if (glfwc.vkGetSwapchainImagesKHR(device, swapchain, &image_count, null) != glfwc.VK_SUCCESS) {
        return error.VulkanSwapchainImageError;
    }

    var images = try allocator.alloc(glfwc.VkImage, image_count);
    if (glfwc.vkGetSwapchainImagesKHR(device, swapchain, &image_count, images.ptr) != glfwc.VK_SUCCESS) {
        return error.VulkanSwapchainImageError;
    }

    return images;
}

pub fn create_views() void {}

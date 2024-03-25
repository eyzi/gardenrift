const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;

/// returns images using allocator. needs to be deallocated.
pub fn create(params: struct {
    device: glfwc.VkDevice,
    swapchain: glfwc.VkSwapchainKHR,
    allocator: std.mem.Allocator,
}) ![]glfwc.VkImage {
    var n_images: u32 = undefined;
    if (glfwc.vkGetSwapchainImagesKHR(params.device, params.swapchain, &n_images, null) != glfwc.VK_SUCCESS) {
        return error.VulkanSwapchainImageError;
    }

    var images = try params.allocator.alloc(glfwc.VkImage, n_images);

    if (glfwc.vkGetSwapchainImagesKHR(params.device, params.swapchain, &n_images, images.ptr) != glfwc.VK_SUCCESS) {
        return error.VulkanSwapchainImageError;
    }

    return images;
}

/// NOTE:   The images were created by the implementation for the swap chain and they will be automatically
///         cleaned up once the swap chain has been destroyed, therefore we don't need to destroy explicitly.
pub fn destroy(params: struct {
    device: glfwc.VkDevice,
    images: []glfwc.VkImage,
    allocator: std.mem.Allocator,
    destroy_images: bool = false,
}) void {
    if (params.destroy_images) {
        for (params.images) |image| {
            glfwc.vkDestroyImage(params.device, image, null);
        }
    }
    params.allocator.free(params.images);
}

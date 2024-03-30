const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;

// returns a created image. needs to be destroyed
pub fn create(params: struct {
    device: glfwc.VkDevice,
    create_info: glfwc.VkImageCreateInfo,
}) !glfwc.VkImage {
    var image: glfwc.VkImage = undefined;
    if (glfwc.vkCreateImage(params.device, &params.create_info, null, &image) != glfwc.VK_SUCCESS) {
        return error.VulkanTextureImageCreateError;
    }
    return image;
}

pub fn destroy(params: struct {
    device: glfwc.VkDevice,
    image: glfwc.VkImage,
}) void {
    glfwc.vkDestroyImage(params.device, params.image, null);
}

pub fn info(params: struct {
    width: u32,
    height: u32,
    format: glfwc.VkFormat = glfwc.VK_FORMAT_R8G8B8A8_SRGB,
    tiling: glfwc.VkImageTiling = glfwc.VK_IMAGE_TILING_OPTIMAL,
    usage: glfwc.VkImageUsageFlags = glfwc.VK_IMAGE_USAGE_TRANSFER_DST_BIT | glfwc.VK_IMAGE_USAGE_SAMPLED_BIT,
    sharing_mode: glfwc.VkSharingMode = glfwc.VK_SHARING_MODE_EXCLUSIVE,
    mip_levels: u32 = 1,
}) glfwc.VkImageCreateInfo {
    return glfwc.VkImageCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
        .imageType = glfwc.VK_IMAGE_TYPE_2D,
        .extent = .{
            .width = params.width,
            .height = params.height,
            .depth = 1,
        },
        .mipLevels = params.mip_levels,
        .arrayLayers = 1,
        .format = params.format,
        .tiling = params.tiling,
        .initialLayout = glfwc.VK_IMAGE_LAYOUT_UNDEFINED,
        .usage = params.usage,
        .samples = glfwc.VK_SAMPLE_COUNT_1_BIT,
        .sharingMode = params.sharing_mode,
        .queueFamilyIndexCount = 0,
        .pQueueFamilyIndices = null,
        .flags = 0,
        .pNext = null,
    };
}

/// NOTE:   swapchain images don't need to be destroyed as they will be
///         automatically destroyed when their image views are destroyed.
///         in that case, set destroy_images to false.
pub fn destroy_many(params: struct {
    device: glfwc.VkDevice,
    images: []glfwc.VkImage,
    allocator: std.mem.Allocator,
    destroy_images: bool = true,
}) void {
    if (params.destroy_images) {
        for (params.images) |image| {
            glfwc.vkDestroyImage(params.device, image, null);
        }
    }
    params.allocator.free(params.images);
}

/// returns swapchain images using allocator. needs to be deallocated.
pub fn get_swapchain_images(params: struct {
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

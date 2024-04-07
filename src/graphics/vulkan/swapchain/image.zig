const std = @import("std");
const vkc = @import("../vk-c.zig").c;

// returns a created image. needs to be destroyed
pub fn create(params: struct {
    device: vkc.VkDevice,
    create_info: vkc.VkImageCreateInfo,
}) !vkc.VkImage {
    var image: vkc.VkImage = undefined;
    if (vkc.vkCreateImage(params.device, &params.create_info, null, &image) != vkc.VK_SUCCESS) {
        return error.VulkanTextureImageCreateError;
    }
    return image;
}

pub fn destroy(params: struct {
    device: vkc.VkDevice,
    image: vkc.VkImage,
}) void {
    vkc.vkDestroyImage(params.device, params.image, null);
}

pub fn info(params: struct {
    width: u32,
    height: u32,
    format: vkc.VkFormat = vkc.VK_FORMAT_R8G8B8A8_SRGB,
    tiling: vkc.VkImageTiling = vkc.VK_IMAGE_TILING_OPTIMAL,
    usage: vkc.VkImageUsageFlags = vkc.VK_IMAGE_USAGE_TRANSFER_DST_BIT | vkc.VK_IMAGE_USAGE_SAMPLED_BIT,
    sharing_mode: vkc.VkSharingMode = vkc.VK_SHARING_MODE_EXCLUSIVE,
    mip_levels: u32 = 1,
    samples: u32 = vkc.VK_SAMPLE_COUNT_1_BIT,
}) vkc.VkImageCreateInfo {
    return vkc.VkImageCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
        .imageType = vkc.VK_IMAGE_TYPE_2D,
        .extent = .{
            .width = params.width,
            .height = params.height,
            .depth = 1,
        },
        .mipLevels = params.mip_levels,
        .arrayLayers = 1,
        .format = params.format,
        .tiling = params.tiling,
        .initialLayout = vkc.VK_IMAGE_LAYOUT_UNDEFINED,
        .usage = params.usage,
        .samples = params.samples,
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
    device: vkc.VkDevice,
    images: []vkc.VkImage,
    allocator: std.mem.Allocator,
    destroy_images: bool = true,
}) void {
    if (params.destroy_images) {
        for (params.images) |image| {
            vkc.vkDestroyImage(params.device, image, null);
        }
    }
    params.allocator.free(params.images);
}

/// returns swapchain images using allocator. needs to be deallocated.
pub fn get_swapchain_images(params: struct {
    device: vkc.VkDevice,
    swapchain: vkc.VkSwapchainKHR,
    allocator: std.mem.Allocator,
}) ![]vkc.VkImage {
    var n_images: u32 = undefined;
    if (vkc.vkGetSwapchainImagesKHR(params.device, params.swapchain, &n_images, null) != vkc.VK_SUCCESS) {
        return error.VulkanSwapchainImageError;
    }

    var images = try params.allocator.alloc(vkc.VkImage, n_images);

    if (vkc.vkGetSwapchainImagesKHR(params.device, params.swapchain, &n_images, images.ptr) != vkc.VK_SUCCESS) {
        return error.VulkanSwapchainImageError;
    }

    return images;
}

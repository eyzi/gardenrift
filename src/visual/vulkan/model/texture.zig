const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;
const physical_device = @import("../instance/physical-device.zig");

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
}) glfwc.VkImageCreateInfo {
    return glfwc.VkImageCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
        .imageType = glfwc.VK_IMAGE_TYPE_2D,
        .extent = .{
            .width = params.width,
            .height = params.height,
            .depth = 1,
        },
        .mipLevels = 1,
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

/// returns image memory. needs to be deallocated.
pub fn allocate(params: struct {
    device: glfwc.VkDevice,
    physical_device: glfwc.VkPhysicalDevice,
    image: glfwc.VkImage,
    properties: glfwc.VkMemoryPropertyFlags,
}) !glfwc.VkDeviceMemory {
    var memory_requirements: glfwc.VkMemoryRequirements = undefined;
    glfwc.vkGetImageMemoryRequirements(params.device, params.image, &memory_requirements);

    var memory_type_index = try physical_device.find_memory_type_index(.{
        .physical_device = params.physical_device,
        .type_filter = memory_requirements.memoryTypeBits,
        .properties = params.properties,
    });

    const allocate_info = glfwc.VkMemoryAllocateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .allocationSize = memory_requirements.size,
        .memoryTypeIndex = memory_type_index,
        .pNext = null,
    };

    var image_memory: glfwc.VkDeviceMemory = undefined;
    if (glfwc.vkAllocateMemory(params.device, &allocate_info, null, &image_memory) != glfwc.VK_SUCCESS) {
        return error.VulkanImageMemoryAllocateError;
    }

    if (glfwc.vkBindImageMemory(params.device, params.image, image_memory, 0) != glfwc.VK_SUCCESS) {
        return error.VulkanImageMemoryBindError;
    }

    return image_memory;
}

pub fn deallocate(params: struct {
    device: glfwc.VkDevice,
    image_memory: glfwc.VkDeviceMemory,
}) void {
    glfwc.vkFreeMemory(params.device, params.image_memory, null);
}

/// returns buffer tuple. needs to be destroyed and deallocated.
pub fn create_and_allocate(params: struct {
    device: glfwc.VkDevice,
    physical_device: glfwc.VkPhysicalDevice,
    width: u32,
    height: u32,
    format: glfwc.VkFormat = glfwc.VK_FORMAT_R8G8B8A8_SRGB,
    tiling: glfwc.VkImageTiling = glfwc.VK_IMAGE_TILING_OPTIMAL,
    usage: glfwc.VkImageUsageFlags = glfwc.VK_IMAGE_USAGE_TRANSFER_DST_BIT | glfwc.VK_IMAGE_USAGE_SAMPLED_BIT,
    sharing_mode: glfwc.VkSharingMode = glfwc.VK_SHARING_MODE_EXCLUSIVE,
    properties: glfwc.VkMemoryPropertyFlags,
}) !struct {
    image: glfwc.VkImage,
    image_create_info: glfwc.VkImageCreateInfo,
    image_memory: glfwc.VkDeviceMemory,
} {
    const image_create_info = info(.{
        .width = params.width,
        .height = params.height,
        .format = params.format,
        .tiling = params.tiling,
        .usage = params.usage,
        .sharing_mode = params.sharing_mode,
    });

    const image = try create(.{
        .device = params.device,
        .create_info = image_create_info,
    });

    const image_memory = try allocate(.{
        .device = params.device,
        .physical_device = params.physical_device,
        .image = image,
        .properties = params.properties,
    });

    return .{
        .image = image,
        .image_create_info = image_create_info,
        .image_memory = image_memory,
    };
}

pub fn destroy_and_deallocate(params: struct {
    device: glfwc.VkDevice,
    image: glfwc.VkImage,
    image_memory: glfwc.VkDeviceMemory,
}) void {
    deallocate(.{
        .device = params.device,
        .image_memory = params.image_memory,
    });

    destroy(.{
        .device = params.device,
        .image = params.image,
    });
}

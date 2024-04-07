const std = @import("std");
const vkc = @import("../vk-c.zig").c;
const surface = @import("../instance/surface.zig");
const queue_family = @import("../queue/family.zig");

/// creates swapchain. needs to be destroyed
pub fn create(params: struct {
    device: vkc.VkDevice,
    physical_device: vkc.VkPhysicalDevice,
    surface: vkc.VkSurfaceKHR,
    surface_format: vkc.VkSurfaceFormatKHR,
    extent: vkc.VkExtent2D,
    allocator: std.mem.Allocator,
    old_swap_chain: vkc.VkSwapchainKHR = null,
}) !vkc.VkSwapchainKHR {
    const capabilities = try surface.get_capabilities(.{
        .physical_device = params.physical_device,
        .surface = params.surface,
    });
    const present_mode = try choose_present_mode(.{
        .physical_device = params.physical_device,
        .surface = params.surface,
        .allocator = params.allocator,
    });
    const queue_famiy_indices = try queue_family.get_indices(.{
        .physical_device = params.physical_device,
        .surface = params.surface,
        .allocator = params.allocator,
    });

    var image_count = capabilities.minImageCount + 1;
    if (capabilities.maxImageCount > 0 and image_count > capabilities.maxImageCount) {
        image_count = capabilities.maxImageCount;
    }

    var image_sharing_mode = vkc.VK_SHARING_MODE_EXCLUSIVE;
    var queue_family_index_count: u32 = 0;
    var queue_family_indices_array: [2]u32 = undefined;
    if (queue_famiy_indices.graphics_family.? != queue_famiy_indices.present_family.?) {
        image_sharing_mode = vkc.VK_SHARING_MODE_CONCURRENT;
        queue_family_index_count = 2;
        queue_family_indices_array = [2]u32{ queue_famiy_indices.graphics_family.?, queue_famiy_indices.present_family.? };
    }

    const create_info = vkc.VkSwapchainCreateInfoKHR{
        .sType = vkc.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
        .surface = params.surface,
        .minImageCount = image_count,
        .imageFormat = params.surface_format.format,
        .imageColorSpace = params.surface_format.colorSpace,
        .imageExtent = params.extent,
        .imageArrayLayers = 1,
        .imageUsage = vkc.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
        .imageSharingMode = @intCast(image_sharing_mode),
        .queueFamilyIndexCount = queue_family_index_count,
        .pQueueFamilyIndices = &queue_family_indices_array,
        .preTransform = capabilities.currentTransform,
        .compositeAlpha = vkc.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        .presentMode = present_mode,
        .clipped = vkc.VK_TRUE,
        .oldSwapchain = params.old_swap_chain,
        .pNext = null,
        .flags = 0,
    };

    var swapchain: vkc.VkSwapchainKHR = undefined;
    if (vkc.vkCreateSwapchainKHR(params.device, &create_info, null, &swapchain) != vkc.VK_SUCCESS) {
        return error.VulkanSwapchainCreateError;
    }

    return swapchain;
}

pub fn destroy(params: struct {
    device: vkc.VkDevice,
    swapchain: vkc.VkSwapchainKHR,
}) void {
    vkc.vkDestroySwapchainKHR(params.device, params.swapchain, null);
}

pub fn is_adequate(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    surface: vkc.VkSurfaceKHR,
}) bool {
    const n_formats = surface.get_n_formats(.{
        .physical_device = params.physical_device,
        .surface = params.surface,
    });
    const n_present_modes = surface.get_n_present_modes(.{
        .physical_device = params.physical_device,
        .surface = params.surface,
    });
    return (n_formats > 0) and (n_present_modes > 0);
}

pub fn choose_surface_format(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    surface: vkc.VkSurfaceKHR,
    allocator: std.mem.Allocator,
    desired_format: vkc.VkFormat = vkc.VK_FORMAT_B8G8R8A8_SRGB,
    desired_color_space: vkc.VkColorSpaceKHR = vkc.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
}) !vkc.VkSurfaceFormatKHR {
    const available_formats = try surface.get_formats(.{
        .physical_device = params.physical_device,
        .surface = params.surface,
        .allocator = params.allocator,
    });
    defer params.allocator.free(available_formats);

    for (available_formats) |available_format| {
        if (available_format.format == params.desired_format and available_format.colorSpace == params.desired_color_space) {
            return available_format;
        }
    }

    return available_formats[0];
}

pub fn choose_present_mode(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    surface: vkc.VkSurfaceKHR,
    allocator: std.mem.Allocator,
}) !vkc.VkPresentModeKHR {
    const available_present_modes = try surface.get_present_modes(.{
        .physical_device = params.physical_device,
        .surface = params.surface,
        .allocator = params.allocator,
    });
    defer params.allocator.free(available_present_modes);

    for (available_present_modes) |available_present_mode| {
        if (available_present_mode == vkc.VK_PRESENT_MODE_MAILBOX_KHR) {
            return available_present_mode;
        }
    }

    return vkc.VK_PRESENT_MODE_FIFO_KHR;
}

pub fn choose_extent(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    surface: vkc.VkSurfaceKHR,
}) !vkc.VkExtent2D {
    const capabilities = try surface.get_capabilities(.{
        .physical_device = params.physical_device,
        .surface = params.surface,
    });

    // clamp
    var width = capabilities.currentExtent.width;
    if (width > capabilities.maxImageExtent.width) {
        width = capabilities.maxImageExtent.width;
    } else if (width < capabilities.minImageExtent.width) {
        width = capabilities.minImageExtent.width;
    }

    var height = capabilities.currentExtent.height;
    if (height > capabilities.maxImageExtent.height) {
        height = capabilities.maxImageExtent.height;
    } else if (height < capabilities.minImageExtent.height) {
        height = capabilities.minImageExtent.height;
    }

    return vkc.VkExtent2D{
        .width = width,
        .height = height,
    };
}

pub fn create_viewport(params: struct {
    extent: vkc.VkExtent2D,
}) vkc.VkViewport {
    return vkc.VkViewport{
        .x = 0.0,
        .y = 0.0,
        .minDepth = 0.0,
        .maxDepth = 1.0,
        .width = @as(f32, @floatFromInt(params.extent.width)),
        .height = @as(f32, @floatFromInt(params.extent.height)),
    };
}

pub fn create_scissor(params: struct {
    extent: vkc.VkExtent2D,
}) vkc.VkRect2D {
    return vkc.VkRect2D{
        .offset = vkc.VkOffset2D{
            .x = 0,
            .y = 0,
        },
        .extent = params.extent,
    };
}

pub fn aquire_next_image_index(params: struct {
    device: vkc.VkDevice,
    swapchain: vkc.VkSwapchainKHR,
    image_available_semaphore: vkc.VkSemaphore,
    timeout: u64 = std.math.maxInt(u64),
}) !u32 {
    var image_index: u32 = undefined;
    const vk_result = vkc.vkAcquireNextImageKHR(params.device, params.swapchain, params.timeout, params.image_available_semaphore, @ptrCast(vkc.VK_NULL_HANDLE), &image_index);
    switch (vk_result) {
        vkc.VK_SUCCESS => {},
        vkc.VK_ERROR_OUT_OF_DATE_KHR => {
            return error.OutOfDate;
        },
        else => {
            return error.VulkanImageAcquireError;
        },
    }
    return image_index;
}

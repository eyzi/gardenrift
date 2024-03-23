const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;
const surface = @import("./surface.zig");
const queue = @import("./queue.zig");

/// creates swapchain. needs to be destroyed
pub fn create(device: glfwc.VkDevice, physical_device: glfwc.VkPhysicalDevice, given_surface: glfwc.VkSurfaceKHR, surface_format: glfwc.VkSurfaceFormatKHR, allocator: std.mem.Allocator, old_swap_chain: glfwc.VkSwapchainKHR) !glfwc.VkSwapchainKHR {
    const capabilities = try surface.get_capabilities(physical_device, given_surface);
    const present_mode = try choose_present_mode(physical_device, given_surface, allocator);
    const queue_famiy_indices = try queue.get_family_indices(physical_device, given_surface, allocator);
    const extent = try choose_extent(physical_device, given_surface);

    var image_count = capabilities.minImageCount + 1;
    if (capabilities.maxImageCount > 0 and image_count > capabilities.maxImageCount) {
        image_count = capabilities.maxImageCount;
    }

    var image_sharing_mode = glfwc.VK_SHARING_MODE_EXCLUSIVE;
    var queue_family_index_count: u32 = 0;
    var queue_family_indices_array: [2]u32 = undefined;
    if (queue_famiy_indices.graphicsFamily.? != queue_famiy_indices.presentFamily.?) {
        image_sharing_mode = glfwc.VK_SHARING_MODE_CONCURRENT;
        queue_family_index_count = 2;
        queue_family_indices_array = [2]u32{ queue_famiy_indices.graphicsFamily.?, queue_famiy_indices.presentFamily.? };
    }

    const create_info = glfwc.VkSwapchainCreateInfoKHR{
        .sType = glfwc.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
        .surface = given_surface,
        .minImageCount = image_count,
        .imageFormat = surface_format.format,
        .imageColorSpace = surface_format.colorSpace,
        .imageExtent = extent,
        .imageArrayLayers = 1,
        .imageUsage = glfwc.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
        .imageSharingMode = @intCast(image_sharing_mode),
        .queueFamilyIndexCount = queue_family_index_count,
        .pQueueFamilyIndices = &queue_family_indices_array,
        .preTransform = capabilities.currentTransform,
        .compositeAlpha = glfwc.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        .presentMode = present_mode,
        .clipped = glfwc.VK_TRUE,
        .oldSwapchain = old_swap_chain,
        .pNext = null,
        .flags = 0,
    };

    var swapchain: glfwc.VkSwapchainKHR = undefined;
    if (glfwc.vkCreateSwapchainKHR(device, &create_info, null, &swapchain) != glfwc.VK_SUCCESS) {
        return error.VulkanSwapchainCreateError;
    }

    return swapchain;
}

pub fn destroy(device: glfwc.VkDevice, swapchain: glfwc.VkSwapchainKHR) void {
    glfwc.vkDestroySwapchainKHR(device, swapchain, null);
}

/// returns frame buffers. needs to be deallocated and destroyed
pub fn create_frame_buffers(device: glfwc.VkDevice, image_views: []glfwc.VkImageView, render_pass: glfwc.VkRenderPass, extent: glfwc.VkExtent2D, allocator: std.mem.Allocator) ![]glfwc.VkFramebuffer {
    var frame_buffers = try allocator.alloc(glfwc.VkFramebuffer, image_views.len);

    for (image_views, 0..) |image_view, i| {
        const attachments = [_]glfwc.VkImageView{
            image_view,
        };
        const create_info = glfwc.VkFramebufferCreateInfo{
            .sType = glfwc.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .renderPass = render_pass,
            .attachmentCount = attachments.len,
            .pAttachments = &attachments,
            .width = extent.width,
            .height = extent.height,
            .layers = 1,
            .pNext = null,
            .flags = 0,
        };

        if (glfwc.vkCreateFramebuffer(device, &create_info, null, &frame_buffers[i]) != glfwc.VK_SUCCESS) {
            return error.VulkanFrameBuffersCreateError;
        }
    }

    return frame_buffers;
}

pub fn destroy_frame_buffers(device: glfwc.VkDevice, frame_buffers: []glfwc.VkFramebuffer, allocator: std.mem.Allocator) void {
    for (frame_buffers) |frame_buffer| {
        glfwc.vkDestroyFramebuffer(device, frame_buffer, null);
    }
    allocator.free(frame_buffers);
}

pub fn is_adequate(physical_device: glfwc.VkPhysicalDevice, given_surface: glfwc.VkSurfaceKHR) bool {
    const n_formats = surface.get_n_formats(physical_device, given_surface);
    const n_present_modes = surface.get_n_present_modes(physical_device, given_surface);
    return (n_formats > 0) and (n_present_modes > 0);
}

pub fn choose_surface_format(physical_device: glfwc.VkPhysicalDevice, given_surface: glfwc.VkSurfaceKHR, allocator: std.mem.Allocator) !glfwc.VkSurfaceFormatKHR {
    const available_formats = try surface.get_formats(physical_device, given_surface, allocator);
    defer allocator.free(available_formats);

    for (available_formats) |available_format| {
        if (available_format.format == glfwc.VK_FORMAT_B8G8R8A8_SRGB and available_format.colorSpace == glfwc.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
            return available_format;
        }
    }

    return available_formats[0];
}

pub fn choose_present_mode(physical_device: glfwc.VkPhysicalDevice, given_surface: glfwc.VkSurfaceKHR, allocator: std.mem.Allocator) !glfwc.VkPresentModeKHR {
    const available_present_modes = try surface.get_present_modes(physical_device, given_surface, allocator);
    defer allocator.free(available_present_modes);

    for (available_present_modes) |available_present_mode| {
        if (available_present_mode == glfwc.VK_PRESENT_MODE_MAILBOX_KHR) {
            return available_present_mode;
        }
    }

    return glfwc.VK_PRESENT_MODE_FIFO_KHR;
}

pub fn choose_extent(physical_device: glfwc.VkPhysicalDevice, given_surface: glfwc.VkSurfaceKHR) !glfwc.VkExtent2D {
    const capabilities = try surface.get_capabilities(physical_device, given_surface);
    return capabilities.currentExtent;
}

pub fn create_viewport(extent: glfwc.VkExtent2D) glfwc.VkViewport {
    return glfwc.VkViewport{
        .x = 0.0,
        .y = 0.0,
        .minDepth = 0.0,
        .maxDepth = 1.0,
        .width = @as(f32, @floatFromInt(extent.width)),
        .height = @as(f32, @floatFromInt(extent.height)),
    };
}

pub fn create_scissor(extent: glfwc.VkExtent2D) glfwc.VkRect2D {
    return glfwc.VkRect2D{
        .offset = glfwc.VkOffset2D{
            .x = 0,
            .y = 0,
        },
        .extent = extent,
    };
}

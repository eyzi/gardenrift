const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;

pub const QueueFamilyIndices = struct {
    graphicsFamily: ?u32,
    presentFamily: ?u32,
};

pub fn create(device: glfwc.VkDevice, family_index: u32) glfwc.VkQueue {
    var queue: glfwc.VkQueue = undefined;
    glfwc.vkGetDeviceQueue(device, family_index, 0, &queue);
    return queue;
}

pub fn get_family_indices(physical_device: glfwc.VkPhysicalDevice, surface: glfwc.VkSurfaceKHR, allocator: std.mem.Allocator) !QueueFamilyIndices {
    var indices = QueueFamilyIndices{
        .graphicsFamily = null,
        .presentFamily = null,
    };

    const queue_families = try get_family_properties(physical_device, allocator);
    defer allocator.free(queue_families);

    for (queue_families, 0..) |queue_family, i| {
        const i_u32 = @as(u32, @intCast(i));
        if ((indices.graphicsFamily == null) and (queue_family.queueFlags & glfwc.VK_QUEUE_GRAPHICS_BIT == glfwc.VK_QUEUE_GRAPHICS_BIT)) {
            indices.graphicsFamily = i_u32;
        }
        if ((indices.presentFamily == null) and (is_present_supported(physical_device, i_u32, surface))) {
            indices.presentFamily = i_u32;
        }
        if ((indices.graphicsFamily != null) and (indices.presentFamily != null)) {
            break;
        }
    }

    return indices;
}

/// returns list of queue family properties. needs to be deallocated.
pub fn get_family_properties(physical_device: glfwc.VkPhysicalDevice, allocator: std.mem.Allocator) ![]glfwc.VkQueueFamilyProperties {
    var n_properties: u32 = undefined;
    glfwc.vkGetPhysicalDeviceQueueFamilyProperties(physical_device, &n_properties, null);
    if (n_properties == 0) {
        return error.DeviceQueueFamilyNone;
    }

    var property_list = try allocator.alloc(glfwc.VkQueueFamilyProperties, n_properties);
    glfwc.vkGetPhysicalDeviceQueueFamilyProperties(physical_device, &n_properties, property_list.ptr);
    return property_list;
}

pub fn is_present_supported(physical_device: glfwc.VkPhysicalDevice, queue_family_index: u32, surface: glfwc.VkSurfaceKHR) bool {
    var supported: u32 = glfwc.VK_FALSE;
    if (glfwc.vkGetPhysicalDeviceSurfaceSupportKHR(physical_device, queue_family_index, surface, &supported) != glfwc.VK_SUCCESS) {
        return false;
    }
    return (supported == glfwc.VK_TRUE);
}

/// returns a list of queue create infos. needs to be deallocated.
pub fn create_info(queue_family_indices: QueueFamilyIndices, allocator: std.mem.Allocator) ![]glfwc.VkDeviceQueueCreateInfo {
    var queue_create_infos: std.ArrayList(glfwc.VkDeviceQueueCreateInfo) = undefined;
    defer queue_create_infos.deinit();

    if (queue_family_indices.graphicsFamily.? == queue_family_indices.presentFamily.?) {
        queue_create_infos = try std.ArrayList(glfwc.VkDeviceQueueCreateInfo).initCapacity(allocator, 1);
        try queue_create_infos.append(glfwc.VkDeviceQueueCreateInfo{
            .sType = glfwc.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .queueFamilyIndex = queue_family_indices.graphicsFamily.?,
            .queueCount = 1,
            .pQueuePriorities = &@as(f32, 1.0),
        });
    } else {
        queue_create_infos = try std.ArrayList(glfwc.VkDeviceQueueCreateInfo).initCapacity(allocator, 2);
        try queue_create_infos.append(glfwc.VkDeviceQueueCreateInfo{
            .sType = glfwc.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .queueFamilyIndex = queue_family_indices.graphicsFamily.?,
            .queueCount = 1,
            .pQueuePriorities = &@as(f32, 1.0),
        });
        try queue_create_infos.append(glfwc.VkDeviceQueueCreateInfo{
            .sType = glfwc.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .queueFamilyIndex = queue_family_indices.presentFamily.?,
            .queueCount = 1,
            .pQueuePriorities = &@as(f32, 1.0),
        });
    }

    return queue_create_infos.toOwnedSlice();
}

pub fn submit(graphics_queue: glfwc.VkQueue, command_buffer: glfwc.VkCommandBuffer, image_available_semaphore: glfwc.VkSemaphore, render_finished_semaphore: glfwc.VkSemaphore, in_flight_fence: glfwc.VkFence) !void {
    const submit_info = glfwc.VkSubmitInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .waitSemaphoreCount = 1,
        .pWaitSemaphores = &[_]glfwc.VkSemaphore{
            image_available_semaphore,
        },
        .pWaitDstStageMask = &[_]glfwc.VkPipelineStageFlags{
            glfwc.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
        },
        .commandBufferCount = 1,
        .pCommandBuffers = &command_buffer,
        .signalSemaphoreCount = 1,
        .pSignalSemaphores = &[_]glfwc.VkSemaphore{
            render_finished_semaphore,
        },
        .pNext = null,
    };
    if (glfwc.vkQueueSubmit(graphics_queue, 1, &submit_info, in_flight_fence) != glfwc.VK_SUCCESS) {
        return error.VulkanQueueSubmitError;
    }
}

pub fn present(present_queue: glfwc.VkQueue, swapchain: glfwc.VkSwapchainKHR, image_index: u32, render_finished_semaphore: glfwc.VkSemaphore) !void {
    const present_info = glfwc.VkPresentInfoKHR{
        .sType = glfwc.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
        .waitSemaphoreCount = 1,
        .pWaitSemaphores = &[_]glfwc.VkSemaphore{
            render_finished_semaphore,
        },
        .swapchainCount = 1,
        .pSwapchains = &[_]glfwc.VkSwapchainKHR{
            swapchain,
        },
        .pImageIndices = &image_index,
        .pResults = null,
        .pNext = null,
    };
    if (glfwc.vkQueuePresentKHR(present_queue, &present_info) != glfwc.VK_SUCCESS) {
        return error.VulkanQueuePresentError;
    }
}

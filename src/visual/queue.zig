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
pub fn create_info(physical_device: glfwc.VkPhysicalDevice, surface: glfwc.VkSurfaceKHR, allocator: std.mem.Allocator) ![]glfwc.VkDeviceQueueCreateInfo {
    const queue_family_indices = try get_family_indices(physical_device, surface, allocator);

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

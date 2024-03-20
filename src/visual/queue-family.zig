const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;

pub const QueueFamilyIndices = struct {
    graphicsFamily: ?u32,
    presentFamily: ?u32,
};

pub fn get_indices(device: glfwc.VkPhysicalDevice, surface: glfwc.VkSurfaceKHR, allocator: std.mem.Allocator) !QueueFamilyIndices {
    var indices = QueueFamilyIndices{
        .graphicsFamily = null,
        .presentFamily = null,
    };

    const queue_families = try get_properties(device, allocator);
    defer allocator.free(queue_families);

    for (queue_families, 0..) |queue_family, i| {
        const i_u32 = @as(u32, @intCast(i));
        if ((indices.graphicsFamily == null) and (queue_family.queueFlags & glfwc.VK_QUEUE_GRAPHICS_BIT == glfwc.VK_QUEUE_GRAPHICS_BIT)) {
            indices.graphicsFamily = i_u32;
        }
        if ((indices.presentFamily == null) and (is_present_supported(device, i_u32, surface))) {
            indices.presentFamily = i_u32;
        }
        if ((indices.graphicsFamily != null) and (indices.presentFamily != null)) {
            break;
        }
    }

    return indices;
}

pub fn get_properties(device: glfwc.VkPhysicalDevice, allocator: std.mem.Allocator) ![]glfwc.VkQueueFamilyProperties {
    var n_properties: u32 = undefined;
    glfwc.vkGetPhysicalDeviceQueueFamilyProperties(device, &n_properties, null);
    if (n_properties == 0) {
        return error.DeviceQueueFamilyNone;
    }

    var property_list = try allocator.alloc(glfwc.VkQueueFamilyProperties, n_properties);
    glfwc.vkGetPhysicalDeviceQueueFamilyProperties(device, &n_properties, property_list.ptr);
    return property_list;
}

pub fn is_present_supported(device: glfwc.VkPhysicalDevice, queue_family_index: u32, surface: glfwc.VkSurfaceKHR) bool {
    var supported: u32 = glfwc.VK_FALSE;
    if (glfwc.vkGetPhysicalDeviceSurfaceSupportKHR(device, queue_family_index, surface, &supported) != glfwc.VK_SUCCESS) {
        return false;
    }
    return (supported == glfwc.VK_TRUE);
}

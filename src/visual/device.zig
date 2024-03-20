const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;
const queue_family = @import("./queue-family.zig");
const extension = @import("./extension.zig");

pub fn get_physical_devices(instance: glfwc.VkInstance, allocator: std.mem.Allocator) ![]glfwc.VkPhysicalDevice {
    var n_devices: u32 = undefined;
    if (glfwc.vkEnumeratePhysicalDevices(instance, &n_devices, null) != glfwc.VK_SUCCESS) {
        return error.VulkanDeviceEnumerateError;
    }
    if (n_devices == 0) {
        return error.VulkanDevicesNoneFound;
    }

    var device_list = try allocator.alloc(glfwc.VkPhysicalDevice, n_devices);
    if (glfwc.vkEnumeratePhysicalDevices(instance, &n_devices, device_list.ptr) != glfwc.VK_SUCCESS) {
        return error.VulkanDeviceEnumerateError;
    }

    return device_list;
}

pub fn get_physical_properties(device: glfwc.VkPhysicalDevice) !glfwc.VkPhysicalDeviceProperties {
    var properties: glfwc.VkPhysicalDeviceProperties = undefined;
    glfwc.vkGetPhysicalDeviceProperties(device, &properties);
    return properties;
}

pub fn get_physical_features(device: glfwc.VkPhysicalDevice) !glfwc.VkPhysicalDeviceFeatures {
    var features: glfwc.VkPhysicalDeviceFeatures = undefined;
    glfwc.vkGetPhysicalDeviceFeatures(device, &features);
    return features;
}

pub fn create(physical_device: glfwc.VkPhysicalDevice, surface: glfwc.VkSurfaceKHR, extensions: [][*:0]const u8, allocator: std.mem.Allocator) !glfwc.VkDevice {
    _ = extensions;

    const queue_family_indices = try queue_family.get_queue_family_indices(physical_device, surface, allocator);
    var queue_create_infos: std.ArrayList(glfwc.VkDeviceQueueCreateInfo) = undefined;
    defer queue_create_infos.deinit();
    const queue_priority: f32 = 1.0;
    if (queue_family_indices.graphicsFamily.? == queue_family_indices.presentFamily.?) {
        queue_create_infos = try std.ArrayList(glfwc.VkDeviceQueueCreateInfo).initCapacity(allocator, 1);
        try queue_create_infos.append(glfwc.VkDeviceQueueCreateInfo{
            .sType = glfwc.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .queueFamilyIndex = queue_family_indices.graphicsFamily.?,
            .queueCount = 1,
            .pQueuePriorities = &queue_priority,
        });
    } else {
        queue_create_infos = try std.ArrayList(glfwc.VkDeviceQueueCreateInfo).initCapacity(allocator, 2);
        try queue_create_infos.append(glfwc.VkDeviceQueueCreateInfo{
            .sType = glfwc.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .queueFamilyIndex = queue_family_indices.graphicsFamily.?,
            .queueCount = 1,
            .pQueuePriorities = &queue_priority,
        });
        try queue_create_infos.append(glfwc.VkDeviceQueueCreateInfo{
            .sType = glfwc.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .queueFamilyIndex = queue_family_indices.presentFamily.?,
            .queueCount = 1,
            .pQueuePriorities = &queue_priority,
        });
    }

    const device_create_info = glfwc.VkDeviceCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .queueCreateInfoCount = @as(u32, @intCast(queue_create_infos.items.len)),
        .pQueueCreateInfos = queue_create_infos.items.ptr,
        .enabledLayerCount = 0,
        .ppEnabledLayerNames = null,
        .enabledExtensionCount = 0, // @as(u32, @intCast(extensions.len)),
        .ppEnabledExtensionNames = null, // extensions.ptr,
        .pEnabledFeatures = null,
    };

    var device: glfwc.VkDevice = undefined;
    if (glfwc.vkCreateDevice(physical_device, &device_create_info, null, &device) != glfwc.VK_SUCCESS) {
        return error.VulkanDeviceCreationError;
    }
    return device;
}

pub fn destroy(device: glfwc.VkDevice) void {
    glfwc.vkDestroyDevice(device, null);
}

pub fn choose_suitable(device_list: []glfwc.VkPhysicalDevice, surface: glfwc.VkSurfaceKHR, allocator: std.mem.Allocator) !glfwc.VkPhysicalDevice {
    var chosen_device: glfwc.VkPhysicalDevice = undefined;
    for (device_list) |device| {
        if (try is_suitable(device, surface, allocator)) {
            chosen_device = device;
            break;
        }
    }
    if (chosen_device) |found_chosen_device| {
        return found_chosen_device;
    } else {
        return error.VulkanDeviceNoneFound;
    }
}

fn is_suitable(device: glfwc.VkPhysicalDevice, surface: glfwc.VkSurfaceKHR, allocator: std.mem.Allocator) !bool {
    const required_extension_names = [_][:0]const u8{
        glfwc.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
    };

    if (device) |valid_device| {
        const indices = try queue_family.get_queue_family_indices(valid_device, surface, allocator);
        const has_required_extensions = extension.has_required(device, &required_extension_names, allocator);
        return has_required_extensions and (indices.graphicsFamily != null) and (indices.presentFamily != null);
    }
    return false;
}

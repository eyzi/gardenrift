const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;
const queue_family = @import("./queue-family.zig");

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

pub fn create(physical_device: glfwc.VkPhysicalDevice, surface: glfwc.VkSurfaceKHR, allocator: std.mem.Allocator) !glfwc.VkDevice {

    // TODO: remove?
    const queue_family_properties_list = try queue_family.get_queue_family_properties(physical_device, allocator);
    defer allocator.free(queue_family_properties_list);
    const queue_family_properties = queue_family_properties_list[0];

    const queue_family_indices = try queue_family.get_queue_family_indices(physical_device, surface, allocator);
    _ = queue_family_indices;

    var device: glfwc.VkDevice = undefined;
    const queue_create_info = glfwc.VkDeviceQueueCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .queueFamilyIndex = 0, // TODO
        .queueCount = queue_family_properties.queueCount,
        .pQueuePriorities = null, // TODO
    };
    const device_create_info = glfwc.VkDeviceCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .queueCreateInfoCount = 0, // TODO
        .pQueueCreateInfos = &queue_create_info,
        .enabledLayerCount = 0,
        .ppEnabledLayerNames = null,
        .enabledExtensionCount = 0, // TODO
        .ppEnabledExtensionNames = null, // TODO
        .pEnabledFeatures = null,
    };
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
    if (device) |valid_device| {
        const indices = try queue_family.get_queue_family_indices(valid_device, surface, allocator);
        return (indices.graphicsFamily != null) and (indices.presentFamily != null);
    }
    return false;
}

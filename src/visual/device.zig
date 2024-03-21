const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;
const queue_family = @import("./queue.zig");
const extension = @import("./extension.zig");
const swapchain = @import("./swapchain.zig");

/// returns list of physical devices. needs to be deallocated.
pub fn get_physical_devices(instance: glfwc.VkInstance, allocator: std.mem.Allocator) ![]glfwc.VkPhysicalDevice {
    var n_physical_devices: u32 = undefined;
    if (glfwc.vkEnumeratePhysicalDevices(instance, &n_physical_devices, null) != glfwc.VK_SUCCESS) {
        return error.VulkanDeviceEnumerateError;
    }
    if (n_physical_devices == 0) {
        return error.VulkanDevicesNoneFound;
    }

    var physical_device_list = try allocator.alloc(glfwc.VkPhysicalDevice, n_physical_devices);
    if (glfwc.vkEnumeratePhysicalDevices(instance, &n_physical_devices, physical_device_list.ptr) != glfwc.VK_SUCCESS) {
        return error.VulkanDeviceEnumerateError;
    }

    return physical_device_list;
}

pub fn get_physical_properties(physical_device: glfwc.VkPhysicalDevice) !glfwc.VkPhysicalDeviceProperties {
    var properties: glfwc.VkPhysicalDeviceProperties = undefined;
    glfwc.vkGetPhysicalDeviceProperties(physical_device, &properties);
    return properties;
}

pub fn get_physical_features(physical_device: glfwc.VkPhysicalDevice) !glfwc.VkPhysicalDeviceFeatures {
    var features: glfwc.VkPhysicalDeviceFeatures = undefined;
    glfwc.vkGetPhysicalDeviceFeatures(physical_device, &features);
    return features;
}

/// creates device. needs to be destroyed.
pub fn create(physical_device: glfwc.VkPhysicalDevice, surface: glfwc.VkSurfaceKHR, extensions: []const [:0]const u8, allocator: std.mem.Allocator) !glfwc.VkDevice {
    const queue_create_infos = try queue_family.create_info(physical_device, surface, allocator);
    defer allocator.free(queue_create_infos);

    const device_create_info = glfwc.VkDeviceCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .queueCreateInfoCount = @as(u32, @intCast(queue_create_infos.len)),
        .pQueueCreateInfos = @ptrCast(queue_create_infos.ptr),
        .enabledLayerCount = 0,
        .ppEnabledLayerNames = null,
        .enabledExtensionCount = @as(u32, @intCast(extensions.len)),
        .ppEnabledExtensionNames = @ptrCast(extensions.ptr),
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

pub fn choose_suitable(physical_device_list: []glfwc.VkPhysicalDevice, surface: glfwc.VkSurfaceKHR, required_extension_names: []const [:0]const u8, allocator: std.mem.Allocator) !glfwc.VkPhysicalDevice {
    var chosen_physical_device: glfwc.VkPhysicalDevice = undefined;
    for (physical_device_list) |physical_device| {
        if (try is_suitable(physical_device, surface, required_extension_names, allocator)) {
            chosen_physical_device = physical_device;
            break;
        }
    }
    if (chosen_physical_device) |found_chosen_device| {
        return found_chosen_device;
    } else {
        return error.VulkanDeviceNoneFound;
    }
}

fn is_suitable(physical_device: glfwc.VkPhysicalDevice, surface: glfwc.VkSurfaceKHR, required_extension_names: []const [:0]const u8, allocator: std.mem.Allocator) !bool {
    if (physical_device) |valid_physical_device| {
        const indices = try queue_family.get_family_indices(valid_physical_device, surface, allocator);

        const has_required_extensions = extension.has_required(valid_physical_device, required_extension_names, allocator);

        var is_swapchain_adequate = false;
        if (has_required_extensions) {
            is_swapchain_adequate = swapchain.is_adequate(physical_device, surface);
        }

        return (indices.graphicsFamily != null) and (indices.presentFamily != null) and has_required_extensions and is_swapchain_adequate;
    }
    return false;
}

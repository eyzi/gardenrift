const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;
const queue_family = @import("../queue/family.zig");
const extension = @import("./extension.zig");
const swapchain = @import("../swapchain/swapchain.zig");

pub fn get_list(params: struct {
    instance: glfwc.VkInstance,
    allocator: std.mem.Allocator,
}) ![]glfwc.VkPhysicalDevice {
    var n_physical_devices: u32 = undefined;
    if (glfwc.vkEnumeratePhysicalDevices(params.instance, &n_physical_devices, null) != glfwc.VK_SUCCESS) {
        return error.VulkanDeviceEnumerateError;
    }
    if (n_physical_devices == 0) {
        return error.VulkanDevicesNoneFound;
    }

    var physical_device_list = try params.allocator.alloc(glfwc.VkPhysicalDevice, n_physical_devices);
    if (glfwc.vkEnumeratePhysicalDevices(params.instance, &n_physical_devices, physical_device_list.ptr) != glfwc.VK_SUCCESS) {
        return error.VulkanDeviceEnumerateError;
    }

    return physical_device_list;
}

pub fn get_properties(params: struct {
    physical_device: glfwc.VkPhysicalDevice,
}) !glfwc.VkPhysicalDeviceProperties {
    var properties: glfwc.VkPhysicalDeviceProperties = undefined;
    glfwc.vkGetPhysicalDeviceProperties(params.physical_device, &properties);
    return properties;
}

pub fn get_features(params: struct {
    physical_device: glfwc.VkPhysicalDevice,
}) !glfwc.VkPhysicalDeviceFeatures {
    var features: glfwc.VkPhysicalDeviceFeatures = undefined;
    glfwc.vkGetPhysicalDeviceFeatures(params.physical_device, &features);
    return features;
}

pub fn get_memory_properties(params: struct {
    physical_device: glfwc.VkPhysicalDevice,
}) !glfwc.VkPhysicalDeviceMemoryProperties {
    var memory_properties: glfwc.VkPhysicalDeviceMemoryProperties = undefined;
    glfwc.vkGetPhysicalDeviceMemoryProperties(params.physical_device, &memory_properties);
    return memory_properties;
}

pub fn get_supported_format(params: struct {
    physical_device: glfwc.VkPhysicalDevice,
    candidates: []const glfwc.VkFormat,
    tiling: glfwc.VkImageTiling,
    features: glfwc.VkFormatFeatureFlags,
}) !glfwc.VkFormat {
    for (params.candidates) |format| {
        var properties: glfwc.VkFormatProperties = undefined;
        glfwc.vkGetPhysicalDeviceFormatProperties(params.physical_device, format, &properties);
        if (params.tiling == glfwc.VK_IMAGE_TILING_LINEAR and (properties.linearTilingFeatures & params.features) == params.features) {
            return format;
        } else if (params.tiling == glfwc.VK_IMAGE_TILING_OPTIMAL and (properties.optimalTilingFeatures & params.features) == params.features) {
            return format;
        }
    }
    return error.VulkanPhysicalDeviceFormatPropertiesNoSupported;
}

pub fn find_memory_type_index(params: struct {
    physical_device: glfwc.VkPhysicalDevice,
    type_filter: u32,
    properties: glfwc.VkMemoryPropertyFlags,
}) !u32 {
    const memory_properties = try get_memory_properties(.{ .physical_device = params.physical_device });

    for (0..memory_properties.memoryTypeCount) |i| {
        const type_bit = @as(u32, 1) << @as(u5, @intCast(i));
        if (params.type_filter & type_bit == type_bit and memory_properties.memoryTypes[i].propertyFlags == params.properties) {
            return @as(u32, @intCast(i));
        }
    }

    return error.VulkanDeviceFindMemoryTypeError;
}

fn is_suitable(params: struct {
    physical_device: glfwc.VkPhysicalDevice,
    surface: glfwc.VkSurfaceKHR,
    required_extension_names: []const [:0]const u8,
    allocator: std.mem.Allocator,
}) bool {
    if (params.physical_device) |valid_physical_device| {
        const indices = queue_family.get_indices(.{
            .physical_device = valid_physical_device,
            .surface = params.surface,
            .allocator = params.allocator,
        }) catch return false;

        const has_required_extensions = extension.has_required(.{
            .physical_device = valid_physical_device,
            .required_extension_names = params.required_extension_names,
            .allocator = params.allocator,
        });

        var is_swapchain_adequate = false;
        if (has_required_extensions) {
            is_swapchain_adequate = swapchain.is_adequate(.{
                .physical_device = params.physical_device,
                .surface = params.surface,
            });
        }

        return (indices.graphicsFamily != null) and (indices.presentFamily != null) and has_required_extensions and is_swapchain_adequate;
    }
    return false;
}

pub fn choose_suitable(params: struct {
    physical_device_list: []glfwc.VkPhysicalDevice,
    surface: glfwc.VkSurfaceKHR,
    required_extension_names: []const [:0]const u8,
    allocator: std.mem.Allocator,
}) !glfwc.VkPhysicalDevice {
    var chosen_physical_device: glfwc.VkPhysicalDevice = undefined;
    for (params.physical_device_list) |physical_device| {
        if (is_suitable(.{
            .physical_device = physical_device,
            .surface = params.surface,
            .required_extension_names = params.required_extension_names,
            .allocator = params.allocator,
        })) {
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

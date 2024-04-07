const std = @import("std");
const vkc = @import("../vk-c.zig").c;
const queue_family = @import("../queue/family.zig");
const extension = @import("./extension.zig");
const swapchain = @import("../swapchain/swapchain.zig");

pub fn get_list(params: struct {
    instance: vkc.VkInstance,
    allocator: std.mem.Allocator,
}) ![]vkc.VkPhysicalDevice {
    var n_physical_devices: u32 = undefined;
    if (vkc.vkEnumeratePhysicalDevices(params.instance, &n_physical_devices, null) != vkc.VK_SUCCESS) {
        return error.VulkanDeviceEnumerateError;
    }
    if (n_physical_devices == 0) {
        return error.VulkanDevicesNoneFound;
    }

    var physical_device_list = try params.allocator.alloc(vkc.VkPhysicalDevice, n_physical_devices);
    if (vkc.vkEnumeratePhysicalDevices(params.instance, &n_physical_devices, physical_device_list.ptr) != vkc.VK_SUCCESS) {
        return error.VulkanDeviceEnumerateError;
    }

    return physical_device_list;
}

pub fn get_properties(params: struct {
    physical_device: vkc.VkPhysicalDevice,
}) !vkc.VkPhysicalDeviceProperties {
    var properties: vkc.VkPhysicalDeviceProperties = undefined;
    vkc.vkGetPhysicalDeviceProperties(params.physical_device, &properties);
    return properties;
}

pub fn get_features(params: struct {
    physical_device: vkc.VkPhysicalDevice,
}) !vkc.VkPhysicalDeviceFeatures {
    var features: vkc.VkPhysicalDeviceFeatures = undefined;
    vkc.vkGetPhysicalDeviceFeatures(params.physical_device, &features);
    return features;
}

pub fn get_memory_properties(params: struct {
    physical_device: vkc.VkPhysicalDevice,
}) !vkc.VkPhysicalDeviceMemoryProperties {
    var memory_properties: vkc.VkPhysicalDeviceMemoryProperties = undefined;
    vkc.vkGetPhysicalDeviceMemoryProperties(params.physical_device, &memory_properties);
    return memory_properties;
}

pub fn get_format_properties(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    format: vkc.VkFormat,
}) vkc.VkFormatProperties {
    var properties: vkc.VkFormatProperties = undefined;
    vkc.vkGetPhysicalDeviceFormatProperties(params.physical_device, params.format, &properties);
    return properties;
}

pub fn get_supported_format(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    candidates: []const vkc.VkFormat,
    tiling: vkc.VkImageTiling,
    features: vkc.VkFormatFeatureFlags,
}) !vkc.VkFormat {
    for (params.candidates) |format| {
        const properties = get_format_properties(.{ .physical_device = params.physical_device, .format = format });
        if (params.tiling == vkc.VK_IMAGE_TILING_LINEAR and (properties.linearTilingFeatures & params.features) == params.features) {
            return format;
        } else if (params.tiling == vkc.VK_IMAGE_TILING_OPTIMAL and (properties.optimalTilingFeatures & params.features) == params.features) {
            return format;
        }
    }
    return error.VulkanPhysicalDeviceFormatPropertiesNoSupported;
}

pub fn get_msaa_sample_count(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    format: vkc.VkFormat,
}) u32 {
    const properties = get_properties(.{ .physical_device = params.physical_device }) catch return vkc.VK_SAMPLE_COUNT_1_BIT;
    const counts: vkc.VkSampleCountFlags = properties.limits.framebufferColorSampleCounts & properties.limits.framebufferDepthSampleCounts;
    if (counts & vkc.VK_SAMPLE_COUNT_64_BIT == vkc.VK_SAMPLE_COUNT_64_BIT) return vkc.VK_SAMPLE_COUNT_64_BIT;
    if (counts & vkc.VK_SAMPLE_COUNT_32_BIT == vkc.VK_SAMPLE_COUNT_32_BIT) return vkc.VK_SAMPLE_COUNT_32_BIT;
    if (counts & vkc.VK_SAMPLE_COUNT_16_BIT == vkc.VK_SAMPLE_COUNT_16_BIT) return vkc.VK_SAMPLE_COUNT_16_BIT;
    if (counts & vkc.VK_SAMPLE_COUNT_8_BIT == vkc.VK_SAMPLE_COUNT_8_BIT) return vkc.VK_SAMPLE_COUNT_8_BIT;
    if (counts & vkc.VK_SAMPLE_COUNT_4_BIT == vkc.VK_SAMPLE_COUNT_4_BIT) return vkc.VK_SAMPLE_COUNT_4_BIT;
    if (counts & vkc.VK_SAMPLE_COUNT_2_BIT == vkc.VK_SAMPLE_COUNT_2_BIT) return vkc.VK_SAMPLE_COUNT_2_BIT;
    return vkc.VK_SAMPLE_COUNT_1_BIT;
}

pub fn find_memory_type_index(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    type_filter: u32,
    properties: vkc.VkMemoryPropertyFlags,
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
    physical_device: vkc.VkPhysicalDevice,
    surface: vkc.VkSurfaceKHR,
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

        return (indices.graphics_family != null) and (indices.present_family != null) and has_required_extensions and is_swapchain_adequate;
    }
    return false;
}

pub fn choose_suitable(params: struct {
    physical_device_list: []vkc.VkPhysicalDevice,
    surface: vkc.VkSurfaceKHR,
    required_extension_names: []const [:0]const u8,
    allocator: std.mem.Allocator,
}) !vkc.VkPhysicalDevice {
    var chosen_physical_device: vkc.VkPhysicalDevice = undefined;
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

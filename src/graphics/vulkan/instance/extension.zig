const std = @import("std");
const vkc = @import("../vk-c.zig").c;
const string_eql = @import("../glfw-c.zig").string_eql;

/// returns list of available extensions. needs to be deallocated.
pub fn get_available(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    allocator: std.mem.Allocator,
}) ![]vkc.VkExtensionProperties {
    var n_extensions: u32 = undefined;
    if (vkc.vkEnumerateDeviceExtensionProperties(params.physical_device, null, &n_extensions, null) != vkc.VK_SUCCESS) {
        return error.VulkanDeviceAvailableExtensionsError;
    }

    var available_extensions = try params.allocator.alloc(vkc.VkExtensionProperties, n_extensions);
    if (vkc.vkEnumerateDeviceExtensionProperties(params.physical_device, null, &n_extensions, available_extensions.ptr) != vkc.VK_SUCCESS) {
        return error.VulkanDeviceAvailableExtensionsError;
    }

    return available_extensions;
}

pub fn has_required(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    required_extension_names: []const [:0]const u8,
    allocator: std.mem.Allocator,
}) bool {
    const available_extensions = get_available(.{
        .physical_device = params.physical_device,
        .allocator = params.allocator,
    }) catch {
        return false;
    };
    defer params.allocator.free(available_extensions);

    for (params.required_extension_names) |required_extension_name| {
        var is_available = false;
        for (available_extensions) |available_extension| {
            if (string_eql(required_extension_name, &available_extension.extensionName)) {
                is_available = true;
                break;
            }
        }
        if (!is_available) {
            return false;
        }
    }

    return true;
}

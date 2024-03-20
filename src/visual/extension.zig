const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;

pub fn get_required(allocator: std.mem.Allocator) ![][*:0]const u8 {
    var n_extensions: u32 = undefined;
    const required_extensions_raw = glfwc.glfwGetRequiredInstanceExtensions(&n_extensions);
    const required_extensions: [][*:0]const u8 = @as([*][*:0]const u8, @ptrCast(required_extensions_raw))[0..n_extensions];

    var instance_extensions = try std.ArrayList([*:0]const u8).initCapacity(allocator, n_extensions + 1);
    defer instance_extensions.deinit();

    try instance_extensions.appendSlice(required_extensions);
    return instance_extensions.toOwnedSlice();
}

pub fn get_available(device: glfwc.VkPhysicalDevice, allocator: std.mem.Allocator) ![]glfwc.VkExtensionProperties {
    var n_extensions: u32 = undefined;
    if (glfwc.vkEnumerateDeviceExtensionProperties(device, null, &n_extensions, null) != glfwc.VK_SUCCESS) {
        return error.VulkanDeviceAvailableExtensionsError;
    }

    var available_extensions = try allocator.alloc(glfwc.VkExtensionProperties, n_extensions);
    if (glfwc.vkEnumerateDeviceExtensionProperties(device, null, &n_extensions, available_extensions.ptr) != glfwc.VK_SUCCESS) {
        return error.VulkanDeviceAvailableExtensionsError;
    }

    return available_extensions;
}

pub fn has_required(device: glfwc.VkPhysicalDevice, required_extension_names: []const [:0]const u8, allocator: std.mem.Allocator) bool {
    const available_extensions = get_available(device, allocator) catch {
        return false;
    };
    defer allocator.free(available_extensions);

    for (required_extension_names) |required_extension_name| {
        var is_available = false;
        for (available_extensions) |available_extension| {
            // NOTE: somehow, available_extension.extensionName always has a 256 character count
            // with 170 code as the last character. ignoring incomparable lengths and checking only
            // by required_extension_name length
            if (required_extension_name.len > available_extension.extensionName.len) {
                continue;
            } else if (std.mem.eql(u8, required_extension_name, available_extension.extensionName[0..required_extension_name.len])) {
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

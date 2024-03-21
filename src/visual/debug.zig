const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;

pub fn get_available_validation_layers(allocator: std.mem.Allocator) ![]glfwc.VkLayerProperties {
    var n_layers: u32 = undefined;
    if (glfwc.vkEnumerateInstanceLayerProperties(&n_layers, null) != glfwc.VK_SUCCESS) {
        return error.VulkanDebugInstanceLayerError;
    }

    var layers = try allocator.alloc(glfwc.VkLayerProperties, n_layers);
    if (glfwc.vkEnumerateInstanceLayerProperties(&n_layers, layers.ptr) != glfwc.VK_SUCCESS) {
        return error.VulkanDebugInstanceLayerError;
    }

    return layers;
}

pub fn are_layers_available(layers: []const []const u8, allocator: std.mem.Allocator) bool {
    const available_layers = get_available_validation_layers(allocator) catch return false;
    defer allocator.free(available_layers);

    for (layers) |layer| {
        var is_available = false;
        for (available_layers) |available_layer| {
            // NOTE: available_layer.layerName always has a 256 character count
            if (layer.len > available_layer.layerName.len) {
                continue;
            } else if (std.mem.eql(u8, layer, available_layer.layerName[0..layer.len])) {
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

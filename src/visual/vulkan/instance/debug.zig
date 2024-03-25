const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;
const string_eql = @import("../glfw-c.zig").string_eql;

pub fn get_available_validation_layers(params: struct {
    allocator: std.mem.Allocator,
}) ![]glfwc.VkLayerProperties {
    var n_layers: u32 = undefined;
    if (glfwc.vkEnumerateInstanceLayerProperties(&n_layers, null) != glfwc.VK_SUCCESS) {
        return error.VulkanDebugInstanceLayerError;
    }

    var layers = try params.allocator.alloc(glfwc.VkLayerProperties, n_layers);
    if (glfwc.vkEnumerateInstanceLayerProperties(&n_layers, layers.ptr) != glfwc.VK_SUCCESS) {
        return error.VulkanDebugInstanceLayerError;
    }

    return layers;
}

pub fn are_layers_available(params: struct {
    layers: []const [:0]const u8,
    allocator: std.mem.Allocator,
}) bool {
    const available_layers = get_available_validation_layers(.{ .allocator = params.allocator }) catch return false;
    defer params.allocator.free(available_layers);

    for (params.layers) |layer| {
        var is_available = false;
        for (available_layers) |available_layer| {
            if (string_eql(layer, &available_layer.layerName)) {
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

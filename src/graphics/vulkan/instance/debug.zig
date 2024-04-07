const std = @import("std");
const vkc = @import("../vk-c.zig").c;
const string_eql = @import("../vk-c.zig").string_eql;

pub fn get_available_validation_layers(params: struct {
    allocator: std.mem.Allocator,
}) ![]vkc.VkLayerProperties {
    var n_layers: u32 = undefined;
    if (vkc.vkEnumerateInstanceLayerProperties(&n_layers, null) != vkc.VK_SUCCESS) {
        return error.VulkanDebugInstanceLayerError;
    }

    var layers = try params.allocator.alloc(vkc.VkLayerProperties, n_layers);
    if (vkc.vkEnumerateInstanceLayerProperties(&n_layers, layers.ptr) != vkc.VK_SUCCESS) {
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

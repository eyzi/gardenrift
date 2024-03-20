const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;

pub fn get_available_validation_layers(allocator: std.mem.Allocator) !void {
    var n_layers: u32 = undefined;
    if (glfwc.vkEnumerateInstanceLayerProperties(&n_layers, null) != glfwc.VK_SUCCESS) {
        return error.VulkanDebugInstanceLayerError;
    }

    var layers = try allocator.alloc(glfwc.VkLayerProperties, n_layers);
    defer allocator.free(layers);

    if (glfwc.vkEnumerateInstanceLayerProperties(&n_layers, layers.ptr) != glfwc.VK_SUCCESS) {
        return error.VulkanDebugInstanceLayerError;
    }

    for (layers) |layer| {
        std.debug.print("{s}: {s}\n", .{ layer.layerName, layer.description });
    }
}

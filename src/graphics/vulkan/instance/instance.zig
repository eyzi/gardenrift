const std = @import("std");
const vkc = @import("../vk-c.zig").c;
const debug = @import("./debug.zig");

/// returns instance. needs to be destroyed.
pub fn create(params: struct {
    app_name: [:0]const u8,
    window_extensions: [][*:0]const u8,
    validation_layers: []const [:0]const u8,
    allocator: std.mem.Allocator,
}) !vkc.VkInstance {
    var pp_enabled_layer_names = std.ArrayList([]const u8).init(params.allocator);
    defer pp_enabled_layer_names.deinit();

    const enable_validation_layers = debug.are_layers_available(.{
        .layers = params.validation_layers,
        .allocator = params.allocator,
    });
    if (enable_validation_layers) {
        try pp_enabled_layer_names.appendSlice(params.validation_layers);
    }

    const app_info = vkc.VkApplicationInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .pApplicationName = params.app_name.ptr,
        .applicationVersion = vkc.VK_MAKE_VERSION(0, 0, 0),
        .pEngineName = params.app_name.ptr,
        .engineVersion = vkc.VK_MAKE_VERSION(0, 0, 0),
        .apiVersion = vkc.VK_MAKE_VERSION(1, 3, 280),
        .pNext = null,
    };

    const instance_create_info = vkc.VkInstanceCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &app_info,
        .enabledExtensionCount = @intCast(params.window_extensions.len),
        .ppEnabledExtensionNames = params.window_extensions.ptr,
        .enabledLayerCount = @as(u32, @intCast(pp_enabled_layer_names.items.len)),
        .ppEnabledLayerNames = @ptrCast(pp_enabled_layer_names.items.ptr),
        .pNext = null,
        .flags = 0,
    };

    var instance: vkc.VkInstance = undefined;
    if (vkc.vkCreateInstance(&instance_create_info, null, &instance) != vkc.VK_SUCCESS) {
        return error.VulkanInsanceCreateError;
    }

    return instance;
}

pub fn destroy(params: struct {
    instance: vkc.VkInstance,
}) void {
    vkc.vkDestroyInstance(params.instance, null);
}

pub fn get_proc_addr() vkc.PFN_vkVoidFunction {
    return vkc.vkGetInstanceProcAddr(null, "vkGetInstanceProcAddr");
}

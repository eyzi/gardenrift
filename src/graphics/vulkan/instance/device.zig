const std = @import("std");
const vkc = @import("../vk-c.zig").c;
const queue_family = @import("../queue/family.zig");
const QueueFamilyIndices = @import("../types.zig").QueueFamilyIndices;

pub fn wait_idle(params: struct {
    device: vkc.VkDevice,
}) !void {
    if (vkc.vkDeviceWaitIdle(params.device) != vkc.VK_SUCCESS) {
        return error.VulkanDeviceWaitIdleError;
    }
}

/// creates device. needs to be destroyed.
pub fn create(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    queue_family_indices: QueueFamilyIndices,
    extensions: []const [:0]const u8,
    allocator: std.mem.Allocator,
}) !vkc.VkDevice {
    const queue_create_infos = try queue_family.create_info(.{
        .indices = params.queue_family_indices,
        .allocator = params.allocator,
    });
    defer params.allocator.free(queue_create_infos);

    const features = std.mem.zeroInit(vkc.VkPhysicalDeviceFeatures, .{
        .samplerAnisotropy = vkc.VK_TRUE,
        .sampleRateShading = vkc.VK_TRUE,
    });

    const device_create_info = vkc.VkDeviceCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .queueCreateInfoCount = @as(u32, @intCast(queue_create_infos.len)),
        .pQueueCreateInfos = @ptrCast(queue_create_infos.ptr),
        .enabledLayerCount = 0,
        .ppEnabledLayerNames = null,
        .enabledExtensionCount = @as(u32, @intCast(params.extensions.len)),
        .ppEnabledExtensionNames = @ptrCast(params.extensions.ptr),
        .pEnabledFeatures = &features,
    };

    var device: vkc.VkDevice = undefined;
    if (vkc.vkCreateDevice(params.physical_device, &device_create_info, null, &device) != vkc.VK_SUCCESS) {
        return error.VulkanDeviceCreationError;
    }
    return device;
}

pub fn destroy(params: struct {
    device: vkc.VkDevice,
}) void {
    vkc.vkDestroyDevice(params.device, null);
}

const std = @import("std");
const vkc = @import("../vk-c.zig").c;
const QueueFamilyIndices = @import("../types.zig").QueueFamilyIndices;

pub fn get_indices(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    surface: vkc.VkSurfaceKHR,
    allocator: std.mem.Allocator,
}) !QueueFamilyIndices {
    var indices = QueueFamilyIndices{};

    const queue_families = try get_properties(.{
        .physical_device = params.physical_device,
        .allocator = params.allocator,
    });
    defer params.allocator.free(queue_families);

    for (queue_families, 0..) |queue_family, i| {
        const i_u32 = @as(u32, @intCast(i));
        if ((indices.graphics_family == null) and (queue_family.queueFlags & vkc.VK_QUEUE_GRAPHICS_BIT == vkc.VK_QUEUE_GRAPHICS_BIT)) {
            indices.graphics_family = i_u32;
        }
        if ((indices.transfer_family == null) and (queue_family.queueFlags & vkc.VK_QUEUE_TRANSFER_BIT == vkc.VK_QUEUE_TRANSFER_BIT)) {
            indices.transfer_family = i_u32;
        }
        if ((indices.compute_family == null) and (queue_family.queueFlags & vkc.VK_QUEUE_COMPUTE_BIT == vkc.VK_QUEUE_COMPUTE_BIT)) {
            indices.compute_family = i_u32;
        }
        if ((indices.present_family == null) and (is_present_supported(.{
            .physical_device = params.physical_device,
            .queue_family_index = i_u32,
            .surface = params.surface,
        }))) {
            indices.present_family = i_u32;
        }
        if ((indices.graphics_family != null) and (indices.present_family != null)) {
            break;
        }
    }

    // default transfer family to graphics family
    indices.transfer_family = indices.transfer_family orelse indices.graphics_family.?;

    return indices;
}

pub fn create_info(params: struct {
    indices: QueueFamilyIndices,
    allocator: std.mem.Allocator,
}) ![]vkc.VkDeviceQueueCreateInfo {
    var unique_indices = std.ArrayList(u32).init(params.allocator);
    defer unique_indices.deinit();

    var current_indices = std.ArrayList(u32).init(params.allocator);
    defer current_indices.deinit();

    inline for (std.meta.fields(QueueFamilyIndices)) |field| {
        const index = @as(field.type, @field(params.indices, field.name));
        if (index) |valid_index| {
            try current_indices.append(valid_index);
        }
    }

    for (current_indices.items) |index| {
        var unique = true;
        for (unique_indices.items) |unique_index| {
            if (unique_index == index) {
                unique = false;
            }
        }
        if (unique) {
            try unique_indices.append(index);
        }
    }

    var queue_create_infos = try std.ArrayList(vkc.VkDeviceQueueCreateInfo).initCapacity(params.allocator, unique_indices.items.len);
    defer queue_create_infos.deinit();

    for (unique_indices.items) |index| {
        try queue_create_infos.append(vkc.VkDeviceQueueCreateInfo{
            .sType = vkc.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .queueFamilyIndex = index,
            .queueCount = 1,
            .pQueuePriorities = &@as(f32, 1.0),
        });
    }

    return queue_create_infos.toOwnedSlice();
}

/// returns list of queue family properties. needs to be deallocated.
pub fn get_properties(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    allocator: std.mem.Allocator,
}) ![]vkc.VkQueueFamilyProperties {
    var n_properties: u32 = undefined;
    vkc.vkGetPhysicalDeviceQueueFamilyProperties(params.physical_device, &n_properties, null);
    if (n_properties == 0) {
        return error.DeviceQueueFamilyNone;
    }

    var property_list = try params.allocator.alloc(vkc.VkQueueFamilyProperties, n_properties);
    vkc.vkGetPhysicalDeviceQueueFamilyProperties(params.physical_device, &n_properties, property_list.ptr);
    return property_list;
}

pub fn is_present_supported(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    queue_family_index: u32,
    surface: vkc.VkSurfaceKHR,
}) bool {
    var supported: u32 = vkc.VK_FALSE;
    if (vkc.vkGetPhysicalDeviceSurfaceSupportKHR(params.physical_device, params.queue_family_index, params.surface, &supported) != vkc.VK_SUCCESS) {
        return false;
    }
    return supported == vkc.VK_TRUE;
}

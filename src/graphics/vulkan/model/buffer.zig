const std = @import("std");
const vkc = @import("../vk-c.zig").c;
const physical_device = @import("../instance/physical-device.zig");

/// returns buffer. needs to be destroyed.
pub fn create(params: struct {
    device: vkc.VkDevice,
    create_info: vkc.VkBufferCreateInfo,
}) !vkc.VkBuffer {
    var buffer: vkc.VkBuffer = undefined;
    if (vkc.vkCreateBuffer(params.device, &params.create_info, null, &buffer) != vkc.VK_SUCCESS) {
        return error.VulkanBufferCreateError;
    }

    return buffer;
}

pub fn destroy(params: struct {
    device: vkc.VkDevice,
    buffer: vkc.VkBuffer,
}) void {
    vkc.vkDestroyBuffer(params.device, params.buffer, null);
}

pub fn info(params: struct {
    size: vkc.VkDeviceSize,
    usage: vkc.VkBufferUsageFlags,
    sharing_mode: vkc.VkSharingMode = vkc.VK_SHARING_MODE_EXCLUSIVE,
}) vkc.VkBufferCreateInfo {
    return vkc.VkBufferCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .size = params.size,
        .usage = params.usage,
        .sharingMode = params.sharing_mode,
        .queueFamilyIndexCount = 0,
        .pQueueFamilyIndices = null,
        .pNext = null,
        .flags = 0,
    };
}

/// returns buffer memory. needs to be deallocated.
pub fn allocate(params: struct {
    device: vkc.VkDevice,
    physical_device: vkc.VkPhysicalDevice,
    buffer: vkc.VkBuffer,
    properties: vkc.VkMemoryPropertyFlags,
}) !vkc.VkDeviceMemory {
    var memory_requirements: vkc.VkMemoryRequirements = undefined;
    vkc.vkGetBufferMemoryRequirements(params.device, params.buffer, &memory_requirements);

    var memory_type_index = try physical_device.find_memory_type_index(.{
        .physical_device = params.physical_device,
        .type_filter = memory_requirements.memoryTypeBits,
        .properties = params.properties,
    });

    const allocate_info = vkc.VkMemoryAllocateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .allocationSize = memory_requirements.size,
        .memoryTypeIndex = memory_type_index,
        .pNext = null,
    };

    var buffer_memory: vkc.VkDeviceMemory = undefined;
    if (vkc.vkAllocateMemory(params.device, &allocate_info, null, &buffer_memory) != vkc.VK_SUCCESS) {
        return error.VulkanBufferMemoryAllocateError;
    }

    if (vkc.vkBindBufferMemory(params.device, params.buffer, buffer_memory, 0) != vkc.VK_SUCCESS) {
        return error.VulkanBufferMemoryBindError;
    }

    return buffer_memory;
}

pub fn deallocate(params: struct {
    device: vkc.VkDevice,
    buffer_memory: vkc.VkDeviceMemory,
}) void {
    vkc.vkFreeMemory(params.device, params.buffer_memory, null);
}

pub const BufferObject = struct {
    buffer: vkc.VkBuffer,
    buffer_create_info: vkc.VkBufferCreateInfo,
    buffer_memory: vkc.VkDeviceMemory,
};

/// returns buffer tuple. needs to be destroyed and deallocated.
pub fn create_and_allocate(params: struct {
    device: vkc.VkDevice,
    physical_device: vkc.VkPhysicalDevice,
    size: vkc.VkDeviceSize,
    usage: vkc.VkBufferUsageFlags,
    sharing_mode: vkc.VkSharingMode = vkc.VK_SHARING_MODE_EXCLUSIVE,
    properties: vkc.VkMemoryPropertyFlags,
}) !BufferObject {
    const buffer_create_info = info(.{
        .size = params.size,
        .usage = params.usage,
        .sharing_mode = params.sharing_mode,
    });

    const buffer = try create(.{
        .device = params.device,
        .create_info = buffer_create_info,
    });

    const buffer_memory = try allocate(.{
        .device = params.device,
        .physical_device = params.physical_device,
        .buffer = buffer,
        .properties = params.properties,
    });

    return .{
        .buffer = buffer,
        .buffer_create_info = buffer_create_info,
        .buffer_memory = buffer_memory,
    };
}

pub fn destroy_and_deallocate(params: struct {
    device: vkc.VkDevice,
    buffer: vkc.VkBuffer,
    buffer_memory: vkc.VkDeviceMemory,
}) void {
    deallocate(.{
        .device = params.device,
        .buffer_memory = params.buffer_memory,
    });

    destroy(.{
        .device = params.device,
        .buffer = params.buffer,
    });
}

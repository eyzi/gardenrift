const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;
const physical_device = @import("../instance/physical-device.zig");

/// returns buffer. needs to be destroyed.
pub fn create(params: struct {
    device: glfwc.VkDevice,
    create_info: glfwc.VkBufferCreateInfo,
}) !glfwc.VkBuffer {
    var buffer: glfwc.VkBuffer = undefined;
    if (glfwc.vkCreateBuffer(params.device, &params.create_info, null, &buffer) != glfwc.VK_SUCCESS) {
        return error.VulkanBufferCreateError;
    }

    return buffer;
}

pub fn destroy(params: struct {
    device: glfwc.VkDevice,
    buffer: glfwc.VkBuffer,
}) void {
    glfwc.vkDestroyBuffer(params.device, params.buffer, null);
}

pub fn info(params: struct {
    size: glfwc.VkDeviceSize,
    usage: glfwc.VkBufferUsageFlags,
    sharing_mode: glfwc.VkSharingMode = glfwc.VK_SHARING_MODE_EXCLUSIVE,
}) glfwc.VkBufferCreateInfo {
    return glfwc.VkBufferCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
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
    device: glfwc.VkDevice,
    physical_device: glfwc.VkPhysicalDevice,
    buffer: glfwc.VkBuffer,
    properties: glfwc.VkMemoryPropertyFlags,
}) !glfwc.VkDeviceMemory {
    var memory_requirements: glfwc.VkMemoryRequirements = undefined;
    glfwc.vkGetBufferMemoryRequirements(params.device, params.buffer, &memory_requirements);

    var memory_type_index = try physical_device.find_memory_type_index(.{
        .physical_device = params.physical_device,
        .type_filter = memory_requirements.memoryTypeBits,
        .properties = params.properties,
    });

    const allocate_info = glfwc.VkMemoryAllocateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .allocationSize = memory_requirements.size,
        .memoryTypeIndex = memory_type_index,
        .pNext = null,
    };

    var buffer_memory: glfwc.VkDeviceMemory = undefined;
    if (glfwc.vkAllocateMemory(params.device, &allocate_info, null, &buffer_memory) != glfwc.VK_SUCCESS) {
        return error.VulkanBufferMemoryAllocateError;
    }

    if (glfwc.vkBindBufferMemory(params.device, params.buffer, buffer_memory, 0) != glfwc.VK_SUCCESS) {
        return error.VulkanBufferMemoryBindError;
    }

    return buffer_memory;
}

pub fn deallocate(params: struct {
    device: glfwc.VkDevice,
    buffer_memory: glfwc.VkDeviceMemory,
}) void {
    glfwc.vkFreeMemory(params.device, params.buffer_memory, null);
}

pub const BufferObject = struct {
    buffer: glfwc.VkBuffer,
    buffer_create_info: glfwc.VkBufferCreateInfo,
    buffer_memory: glfwc.VkDeviceMemory,
};

/// returns buffer tuple. needs to be destroyed and deallocated.
pub fn create_and_allocate(params: struct {
    device: glfwc.VkDevice,
    physical_device: glfwc.VkPhysicalDevice,
    size: glfwc.VkDeviceSize,
    usage: glfwc.VkBufferUsageFlags,
    sharing_mode: glfwc.VkSharingMode = glfwc.VK_SHARING_MODE_EXCLUSIVE,
    properties: glfwc.VkMemoryPropertyFlags,
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
    device: glfwc.VkDevice,
    buffer: glfwc.VkBuffer,
    buffer_memory: glfwc.VkDeviceMemory,
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

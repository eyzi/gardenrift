const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;
const device = @import("./device.zig");

pub const Vertex = struct {
    position: [2]f32,
    color: [3]f32,
};

pub fn create_buffer_info(vertices: []Vertex) glfwc.VkBufferCreateInfo {
    return glfwc.VkBufferCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .size = @sizeOf(Vertex) * vertices.len,
        .usage = glfwc.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
        .sharingMode = glfwc.VK_SHARING_MODE_EXCLUSIVE,
        .queueFamilyIndexCount = 0,
        .pQueueFamilyIndices = null,
        .pNext = null,
        .flags = 0,
    };
}

/// returns a vertex buffer. needs to be destroyed.
pub fn create_buffer(given_device: glfwc.VkDevice, create_info: glfwc.VkBufferCreateInfo) !glfwc.VkBuffer {
    var buffer: glfwc.VkBuffer = undefined;
    if (glfwc.vkCreateBuffer(given_device, &create_info, null, &buffer) != glfwc.VK_SUCCESS) {
        return error.VulkanVertexBufferCreateError;
    }

    return buffer;
}

pub fn destroy_buffer(given_device: glfwc.VkDevice, buffer: glfwc.VkBuffer) void {
    glfwc.vkDestroyBuffer(given_device, buffer, null);
}

pub fn create_memory_requirements(given_device: glfwc.VkDevice, buffer: glfwc.VkBuffer) !glfwc.VkMemoryRequirements {
    var memory_requirements: glfwc.VkMemoryRequirements = undefined;
    glfwc.vkGetBufferMemoryRequirements(given_device, buffer, &memory_requirements);
    return memory_requirements;
}

/// allocates memory in device. needs to be deallocated.
pub fn allocate_memory(given_device: glfwc.VkDevice, physical_device: glfwc.VkPhysicalDevice, buffer: glfwc.VkBuffer) !glfwc.VkDeviceMemory {
    const memory_requirements = try create_memory_requirements(given_device, buffer);
    const memory_type = try device.find_memory_type(physical_device, memory_requirements.memoryTypeBits, glfwc.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | glfwc.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
    const allocate_info = glfwc.VkMemoryAllocateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .allocationSize = memory_requirements.size,
        .memoryTypeIndex = memory_type,
        .pNext = null,
    };

    var buffer_memory: glfwc.VkDeviceMemory = undefined;
    if (glfwc.vkAllocateMemory(given_device, &allocate_info, null, &buffer_memory) != glfwc.VK_SUCCESS) {
        return error.VulkanVertexBufferMemoryAllocateError;
    }

    if (glfwc.vkBindBufferMemory(given_device, buffer, buffer_memory, 0) != glfwc.VK_SUCCESS) {
        return error.VulkanMemoryBindError;
    }

    return buffer_memory;
}

pub fn deallocate_memory(given_device: glfwc.VkDevice, buffer_memory: glfwc.VkDeviceMemory) void {
    glfwc.vkFreeMemory(given_device, buffer_memory, null);
}

pub fn map_memory(given_device: glfwc.VkDevice, vertices: []Vertex, buffer_memory: glfwc.VkDeviceMemory, buffer_create_info: glfwc.VkBufferCreateInfo) !void {
    var data: [*]Vertex = undefined;
    if (glfwc.vkMapMemory(given_device, buffer_memory, 0, buffer_create_info.size, 0, @ptrCast(&data)) != glfwc.VK_SUCCESS) {
        return error.VulkanMemoryMapError;
    }
    @memcpy(data, vertices);
}

pub fn unmap_memory(given_device: glfwc.VkDevice, buffer_memory: glfwc.VkDeviceMemory) void {
    glfwc.vkUnmapMemory(given_device, buffer_memory);
}

pub fn get_binding_description() []const glfwc.VkVertexInputBindingDescription {
    return &[_]glfwc.VkVertexInputBindingDescription{
        glfwc.VkVertexInputBindingDescription{
            .binding = 0,
            .stride = @sizeOf(Vertex),
            .inputRate = glfwc.VK_VERTEX_INPUT_RATE_VERTEX,
        },
    };
}

pub fn get_attribute_descriptions() []const glfwc.VkVertexInputAttributeDescription {
    return &[_]glfwc.VkVertexInputAttributeDescription{
        glfwc.VkVertexInputAttributeDescription{
            .binding = 0,
            .location = 0,
            .format = glfwc.VK_FORMAT_R32G32_SFLOAT,
            .offset = @offsetOf(Vertex, "position"),
        },
        glfwc.VkVertexInputAttributeDescription{
            .binding = 0,
            .location = 1,
            .format = glfwc.VK_FORMAT_R32G32B32_SFLOAT,
            .offset = @offsetOf(Vertex, "color"),
        },
    };
}

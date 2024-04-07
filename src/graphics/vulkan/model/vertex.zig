const std = @import("std");
const vkc = @import("../vk-c.zig").c;
const Vertex = @import("../types.zig").Vertex;

pub fn get_binding_description() []const vkc.VkVertexInputBindingDescription {
    return &[_]vkc.VkVertexInputBindingDescription{
        vkc.VkVertexInputBindingDescription{
            .binding = 0,
            .stride = @sizeOf(Vertex),
            .inputRate = vkc.VK_VERTEX_INPUT_RATE_VERTEX,
        },
    };
}

pub fn get_attribute_descriptions() []const vkc.VkVertexInputAttributeDescription {
    return &[_]vkc.VkVertexInputAttributeDescription{
        vkc.VkVertexInputAttributeDescription{
            .binding = 0,
            .location = 0,
            .format = vkc.VK_FORMAT_R32G32B32_SFLOAT,
            .offset = @offsetOf(Vertex, "position"),
        },
        vkc.VkVertexInputAttributeDescription{
            .binding = 0,
            .location = 1,
            .format = vkc.VK_FORMAT_R32G32B32_SFLOAT,
            .offset = @offsetOf(Vertex, "color"),
        },
        vkc.VkVertexInputAttributeDescription{
            .binding = 0,
            .location = 2,
            .format = vkc.VK_FORMAT_R32G32_SFLOAT,
            .offset = @offsetOf(Vertex, "texCoord"),
        },
    };
}

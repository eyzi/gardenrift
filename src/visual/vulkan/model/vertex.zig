const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;
const Vertex = @import("../types.zig").Vertex;

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

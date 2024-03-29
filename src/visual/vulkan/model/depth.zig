const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;

pub fn has_stencil(params: struct {
    format: glfwc.VkFormat,
}) bool {
    return params.format == glfwc.VK_FORMAT_D32_SFLOAT_S8_UINT or params.format == glfwc.VK_FORMAT_D24_UNORM_S8_UINT;
}

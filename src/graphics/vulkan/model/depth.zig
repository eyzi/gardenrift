const std = @import("std");
const vkc = @import("../vk-c.zig").c;

pub fn has_stencil(params: struct {
    format: vkc.VkFormat,
}) bool {
    return params.format == vkc.VK_FORMAT_D32_SFLOAT_S8_UINT or params.format == vkc.VK_FORMAT_D24_UNORM_S8_UINT;
}

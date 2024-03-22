const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;

// returns file contents. needs to be deallocated.
pub fn get_file_content(filepath: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, (try file.stat()).size);
    return content;
}

/// returns shader module. needs to be destroyed
pub fn create_module(device: glfwc.VkDevice, filepath: []const u8, allocator: std.mem.Allocator) !glfwc.VkShaderModule {
    const code = try get_file_content(filepath, allocator);
    defer allocator.free(code);

    const create_info = glfwc.VkShaderModuleCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
        .codeSize = code.len,
        .pCode = @alignCast(@ptrCast(code.ptr)),
        .pNext = null,
        .flags = 0,
    };

    var module: glfwc.VkShaderModule = undefined;
    if (glfwc.vkCreateShaderModule(device, &create_info, null, &module) != glfwc.VK_SUCCESS) {
        return error.VulkanShaderModuleCreateError;
    }

    return module;
}

pub fn destroy_module(device: glfwc.VkDevice, module: glfwc.VkShaderModule) void {
    glfwc.vkDestroyShaderModule(device, module, null);
}

pub fn create_shader_stage_info(vert_shader_module: glfwc.VkShaderModule, frag_shader_module: glfwc.VkShaderModule) [2]glfwc.VkPipelineShaderStageCreateInfo {
    return [2]glfwc.VkPipelineShaderStageCreateInfo{
        glfwc.VkPipelineShaderStageCreateInfo{
            .sType = glfwc.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .stage = glfwc.VK_SHADER_STAGE_VERTEX_BIT,
            .module = vert_shader_module,
            .pName = "main",
            .pSpecializationInfo = null,
            .pNext = null,
            .flags = 0,
        },
        glfwc.VkPipelineShaderStageCreateInfo{
            .sType = glfwc.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .stage = glfwc.VK_SHADER_STAGE_FRAGMENT_BIT,
            .module = frag_shader_module,
            .pName = "main",
            .pSpecializationInfo = null,
            .pNext = null,
            .flags = 0,
        },
    };
}

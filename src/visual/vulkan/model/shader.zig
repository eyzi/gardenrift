const std = @import("std");
const file = @import("../../../library/file/main.zig");
const glfwc = @import("../glfw-c.zig").c;

/// returns shader module. needs to be destroyed
pub fn create_module(params: struct {
    device: glfwc.VkDevice,
    filepath: [:0]const u8,
    allocator: std.mem.Allocator,
}) !glfwc.VkShaderModule {
    const code = try file.get_content(params.filepath, params.allocator);
    defer params.allocator.free(code);

    const create_info = glfwc.VkShaderModuleCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
        .codeSize = code.len,
        .pCode = @alignCast(@ptrCast(code.ptr)),
        .pNext = null,
        .flags = 0,
    };

    var module: glfwc.VkShaderModule = undefined;
    if (glfwc.vkCreateShaderModule(params.device, &create_info, null, &module) != glfwc.VK_SUCCESS) {
        return error.VulkanShaderModuleCreateError;
    }

    return module;
}

pub fn destroy_module(params: struct {
    device: glfwc.VkDevice,
    module: glfwc.VkShaderModule,
}) void {
    glfwc.vkDestroyShaderModule(params.device, params.module, null);
}

pub fn create_shader_stage_info(
    params: struct {
        vert_shader_module: glfwc.VkShaderModule,
        frag_shader_module: glfwc.VkShaderModule,
        // comp_shader_module: glfwc.VkShaderModule,
    },
) [2]glfwc.VkPipelineShaderStageCreateInfo {
    return [2]glfwc.VkPipelineShaderStageCreateInfo{
        glfwc.VkPipelineShaderStageCreateInfo{
            .sType = glfwc.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .stage = glfwc.VK_SHADER_STAGE_VERTEX_BIT,
            .module = params.vert_shader_module,
            .pName = "main",
            .pSpecializationInfo = null,
            .pNext = null,
            .flags = 0,
        },
        glfwc.VkPipelineShaderStageCreateInfo{
            .sType = glfwc.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .stage = glfwc.VK_SHADER_STAGE_FRAGMENT_BIT,
            .module = params.frag_shader_module,
            .pName = "main",
            .pSpecializationInfo = null,
            .pNext = null,
            .flags = 0,
        },
        // glfwc.VkPipelineShaderStageCreateInfo{
        //     .sType = glfwc.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
        //     .stage = glfwc.VK_SHADER_STAGE_COMPUTE_BIT,
        //     .module = params.comp_shader_module,
        //     .pName = "main",
        //     .pSpecializationInfo = null,
        //     .pNext = null,
        //     .flags = 0,
        // },
    };
}

const std = @import("std");
const ember = @import("ember");
const vkc = @import("../vk-c.zig").c;

/// returns shader module. needs to be destroyed
pub fn create_module(params: struct {
    device: vkc.VkDevice,
    filepath: [:0]const u8,
    allocator: std.mem.Allocator,
}) !vkc.VkShaderModule {
    const code = try ember.load(params.filepath, params.allocator);
    defer params.allocator.free(code);

    const create_info = vkc.VkShaderModuleCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
        .codeSize = code.len,
        .pCode = @alignCast(@ptrCast(code.ptr)),
        .pNext = null,
        .flags = 0,
    };

    var module: vkc.VkShaderModule = undefined;
    if (vkc.vkCreateShaderModule(params.device, &create_info, null, &module) != vkc.VK_SUCCESS) {
        return error.VulkanShaderModuleCreateError;
    }

    return module;
}

pub fn destroy_module(params: struct {
    device: vkc.VkDevice,
    module: vkc.VkShaderModule,
}) void {
    vkc.vkDestroyShaderModule(params.device, params.module, null);
}

pub fn create_shader_stage_info(
    params: struct {
        vert_shader_module: vkc.VkShaderModule,
        frag_shader_module: vkc.VkShaderModule,
        // comp_shader_module: vkc.VkShaderModule,
    },
) [2]vkc.VkPipelineShaderStageCreateInfo {
    return [2]vkc.VkPipelineShaderStageCreateInfo{
        vkc.VkPipelineShaderStageCreateInfo{
            .sType = vkc.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .stage = vkc.VK_SHADER_STAGE_VERTEX_BIT,
            .module = params.vert_shader_module,
            .pName = "main",
            .pSpecializationInfo = null,
            .pNext = null,
            .flags = 0,
        },
        vkc.VkPipelineShaderStageCreateInfo{
            .sType = vkc.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .stage = vkc.VK_SHADER_STAGE_FRAGMENT_BIT,
            .module = params.frag_shader_module,
            .pName = "main",
            .pSpecializationInfo = null,
            .pNext = null,
            .flags = 0,
        },
        // vkc.VkPipelineShaderStageCreateInfo{
        //     .sType = vkc.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
        //     .stage = vkc.VK_SHADER_STAGE_COMPUTE_BIT,
        //     .module = params.comp_shader_module,
        //     .pName = "main",
        //     .pSpecializationInfo = null,
        //     .pNext = null,
        //     .flags = 0,
        // },
    };
}

const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;

/// returns descriptor sets. needs to be deallocated/destroyed.
pub fn create(params: struct {
    device: glfwc.VkDevice,
    descriptor_pool: glfwc.VkDescriptorPool,
    descriptor_set_layout: glfwc.VkDescriptorSetLayout,
    max_frames: u32,
    allocator: std.mem.Allocator,
}) ![]glfwc.VkDescriptorSet {
    var layouts = try std.ArrayList(glfwc.VkDescriptorSetLayout).initCapacity(params.allocator, params.max_frames);
    defer layouts.deinit();

    try layouts.appendNTimes(params.descriptor_set_layout, params.max_frames);

    const allocate_info = glfwc.VkDescriptorSetAllocateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
        .descriptorPool = params.descriptor_pool,
        .descriptorSetCount = params.max_frames,
        .pSetLayouts = layouts.items.ptr,
        .pNext = null,
    };

    var sets = try params.allocator.alloc(glfwc.VkDescriptorSet, params.max_frames);
    if (glfwc.vkAllocateDescriptorSets(params.device, &allocate_info, sets.ptr) != glfwc.VK_SUCCESS) {
        return error.VulkanDescriptorSetsCreateError;
    }
    return sets;
}

pub fn destroy(params: struct {
    descriptor_sets: []glfwc.VkDescriptorSet,
    allocator: std.mem.Allocator,
}) void {
    params.allocator.free(params.descriptor_sets);
}

pub fn update(params: struct {
    device: glfwc.VkDevice,
    buffer: glfwc.VkBuffer,
    descriptor_set: glfwc.VkDescriptorSet,
    range: u64,
}) !void {
    const buffer_info = glfwc.VkDescriptorBufferInfo{
        .buffer = params.buffer,
        .offset = 0,
        .range = params.range,
    };

    const set_write = glfwc.VkWriteDescriptorSet{
        .sType = glfwc.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
        .dstSet = params.descriptor_set,
        .dstBinding = 0,
        .dstArrayElement = 0,
        .descriptorType = glfwc.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = 1,
        .pBufferInfo = &buffer_info,
        .pImageInfo = null,
        .pTexelBufferView = null,
        .pNext = null,
    };

    glfwc.vkUpdateDescriptorSets(params.device, 1, &set_write, 0, null);
}

pub fn create_layout(params: struct {
    device: glfwc.VkDevice,
}) !glfwc.VkDescriptorSetLayout {
    const layout_binding = glfwc.VkDescriptorSetLayoutBinding{
        .binding = 0,
        .descriptorType = glfwc.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = 1,
        .stageFlags = glfwc.VK_SHADER_STAGE_VERTEX_BIT,
        .pImmutableSamplers = null,
    };

    const create_info = glfwc.VkDescriptorSetLayoutCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        .bindingCount = 1,
        .pBindings = &layout_binding,
        .pNext = null,
        .flags = 0,
    };

    var set_layout: glfwc.VkDescriptorSetLayout = undefined;
    if (glfwc.vkCreateDescriptorSetLayout(params.device, &create_info, null, &set_layout) != glfwc.VK_SUCCESS) {
        return error.VulkanDescriptorSetLayoutCreateError;
    }
    return set_layout;
}

pub fn destroy_layout(params: struct {
    device: glfwc.VkDevice,
    set_layout: glfwc.VkDescriptorSetLayout,
}) void {
    glfwc.vkDestroyDescriptorSetLayout(params.device, params.set_layout, null);
}

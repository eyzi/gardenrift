const std = @import("std");
const vkc = @import("../vk-c.zig").c;

/// returns descriptor sets. needs to be deallocated/destroyed.
pub fn create(params: struct {
    device: vkc.VkDevice,
    descriptor_pool: vkc.VkDescriptorPool,
    descriptor_set_layout: vkc.VkDescriptorSetLayout,
    max_frames: u32,
    allocator: std.mem.Allocator,
}) ![]vkc.VkDescriptorSet {
    var layouts = try std.ArrayList(vkc.VkDescriptorSetLayout).initCapacity(params.allocator, params.max_frames);
    defer layouts.deinit();

    try layouts.appendNTimes(params.descriptor_set_layout, params.max_frames);

    const allocate_info = vkc.VkDescriptorSetAllocateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
        .descriptorPool = params.descriptor_pool,
        .descriptorSetCount = params.max_frames,
        .pSetLayouts = layouts.items.ptr,
        .pNext = null,
    };

    var sets = try params.allocator.alloc(vkc.VkDescriptorSet, params.max_frames);
    if (vkc.vkAllocateDescriptorSets(params.device, &allocate_info, sets.ptr) != vkc.VK_SUCCESS) {
        return error.VulkanDescriptorSetsCreateError;
    }
    return sets;
}

pub fn destroy(params: struct {
    descriptor_sets: []vkc.VkDescriptorSet,
    allocator: std.mem.Allocator,
}) void {
    params.allocator.free(params.descriptor_sets);
}

pub fn update(params: struct {
    device: vkc.VkDevice,
    buffer: vkc.VkBuffer,
    range: u64,
    texture_image_view: vkc.VkImageView,
    texture_image_sampler: vkc.VkSampler,
    descriptor_set: vkc.VkDescriptorSet,
}) !void {
    const buffer_info = vkc.VkDescriptorBufferInfo{
        .buffer = params.buffer,
        .offset = 0,
        .range = params.range,
    };

    const image_info = vkc.VkDescriptorImageInfo{
        .imageLayout = vkc.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        .imageView = params.texture_image_view,
        .sampler = params.texture_image_sampler,
    };

    const set_write = [_]vkc.VkWriteDescriptorSet{
        .{
            .sType = vkc.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
            .dstSet = params.descriptor_set,
            .dstBinding = 0,
            .dstArrayElement = 0,
            .descriptorType = vkc.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
            .descriptorCount = 1,
            .pBufferInfo = &buffer_info,
            .pImageInfo = null,
            .pTexelBufferView = null,
            .pNext = null,
        },
        .{
            .sType = vkc.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
            .dstSet = params.descriptor_set,
            .dstBinding = 1,
            .dstArrayElement = 0,
            .descriptorType = vkc.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
            .descriptorCount = 1,
            .pBufferInfo = null,
            .pImageInfo = &image_info,
            .pTexelBufferView = null,
            .pNext = null,
        },
    };

    vkc.vkUpdateDescriptorSets(params.device, set_write.len, &set_write, 0, null);
}

pub fn create_layout(params: struct {
    device: vkc.VkDevice,
}) !vkc.VkDescriptorSetLayout {
    const ubo_layout_binding = vkc.VkDescriptorSetLayoutBinding{
        .binding = 0,
        .descriptorType = vkc.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = 1,
        .stageFlags = vkc.VK_SHADER_STAGE_VERTEX_BIT,
        .pImmutableSamplers = null,
    };

    const sampler_layout_binding = vkc.VkDescriptorSetLayoutBinding{
        .binding = 1,
        .descriptorType = vkc.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
        .descriptorCount = 1,
        .stageFlags = vkc.VK_SHADER_STAGE_FRAGMENT_BIT,
        .pImmutableSamplers = null,
    };

    const layout_bindings = [_]vkc.VkDescriptorSetLayoutBinding{
        ubo_layout_binding,
        sampler_layout_binding,
    };

    const create_info = vkc.VkDescriptorSetLayoutCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        .bindingCount = layout_bindings.len,
        .pBindings = &layout_bindings,
        .pNext = null,
        .flags = 0,
    };

    var set_layout: vkc.VkDescriptorSetLayout = undefined;
    if (vkc.vkCreateDescriptorSetLayout(params.device, &create_info, null, &set_layout) != vkc.VK_SUCCESS) {
        return error.VulkanDescriptorSetLayoutCreateError;
    }
    return set_layout;
}

pub fn destroy_layout(params: struct {
    device: vkc.VkDevice,
    set_layout: vkc.VkDescriptorSetLayout,
}) void {
    vkc.vkDestroyDescriptorSetLayout(params.device, params.set_layout, null);
}

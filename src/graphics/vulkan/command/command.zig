const std = @import("std");
const vkc = @import("../vk-c.zig").c;
const renderpass = @import("../pipeline/renderpass.zig");
const swapchain = @import("../swapchain/swapchain.zig");

pub fn record(params: struct {
    pipeline: vkc.VkPipeline,
    renderpass: vkc.VkRenderPass,
    command_buffer: vkc.VkCommandBuffer,
    frame_buffer: vkc.VkFramebuffer,
    vertex_buffer: vkc.VkBuffer,
    extent: vkc.VkExtent2D,
}) !void {
    try begin(.{ .command_buffer = params.command_buffer });
    renderpass.begin(.{
        .renderpass = params.renderpass,
        .command_buffer = params.command_buffer,
        .frame_buffer = params.frame_buffer,
        .extent = params.extent,
    });
    vkc.vkCmdBindPipeline(params.command_buffer, vkc.VK_PIPELINE_BIND_POINT_GRAPHICS, params.pipeline);
    vkc.vkCmdSetViewport(params.command_buffer, 0, 1, &swapchain.create_viewport(.{ .extent = params.extent }));
    vkc.vkCmdSetScissor(params.command_buffer, 0, 1, &swapchain.create_scissor(.{ .extent = params.extent }));
    vkc.vkCmdBindVertexBuffers(params.command_buffer, 0, 1, &[_]vkc.VkBuffer{params.vertex_buffer}, &[_]vkc.VkDeviceSize{0});
    vkc.vkCmdDraw(params.command_buffer, 3, 1, 0, 0);
    renderpass.end(.{ .command_buffer = params.command_buffer });
    try end(.{ .command_buffer = params.command_buffer });
}

pub fn record_indexed(params: struct {
    pipeline: vkc.VkPipeline,
    renderpass: vkc.VkRenderPass,
    layout: vkc.VkPipelineLayout,
    command_buffer: vkc.VkCommandBuffer,
    frame_buffer: vkc.VkFramebuffer,
    vertex_buffer: vkc.VkBuffer,
    index_buffer: vkc.VkBuffer,
    descriptor_set: vkc.VkDescriptorSet,
    n_index: u32,
    extent: vkc.VkExtent2D,
}) !void {
    try begin(.{ .command_buffer = params.command_buffer });
    renderpass.begin(.{
        .renderpass = params.renderpass,
        .command_buffer = params.command_buffer,
        .frame_buffer = params.frame_buffer,
        .extent = params.extent,
        .clear_values = &[_]vkc.VkClearValue{ vkc.VkClearValue{
            .color = vkc.VkClearColorValue{
                .float32 = [4]f32{ 0.0, 0.0, 0.0, 0.0 },
            },
        }, vkc.VkClearValue{
            .depthStencil = vkc.VkClearDepthStencilValue{
                .depth = 1.0,
                .stencil = 0,
            },
        } },
    });
    vkc.vkCmdBindPipeline(params.command_buffer, vkc.VK_PIPELINE_BIND_POINT_GRAPHICS, params.pipeline);
    vkc.vkCmdSetViewport(params.command_buffer, 0, 1, &swapchain.create_viewport(.{ .extent = params.extent }));
    vkc.vkCmdSetScissor(params.command_buffer, 0, 1, &swapchain.create_scissor(.{ .extent = params.extent }));
    vkc.vkCmdBindVertexBuffers(params.command_buffer, 0, 1, &[_]vkc.VkBuffer{params.vertex_buffer}, &[_]vkc.VkDeviceSize{0});
    vkc.vkCmdBindIndexBuffer(params.command_buffer, params.index_buffer, 0, vkc.VK_INDEX_TYPE_UINT32);
    vkc.vkCmdBindDescriptorSets(params.command_buffer, vkc.VK_PIPELINE_BIND_POINT_GRAPHICS, params.layout, 0, 1, &params.descriptor_set, 0, null);
    vkc.vkCmdDrawIndexed(params.command_buffer, params.n_index, 1, 0, 0, 0);
    renderpass.end(.{ .command_buffer = params.command_buffer });
    try end(.{ .command_buffer = params.command_buffer });
}

pub fn reset(params: struct {
    command_buffer: vkc.VkCommandBuffer,
    flags: vkc.VkCommandBufferResetFlags = 0,
}) !void {
    if (vkc.vkResetCommandBuffer(params.command_buffer, params.flags) != vkc.VK_SUCCESS) {
        return error.VulkanCommandBufferResetError;
    }
}

pub fn begin(params: struct {
    command_buffer: vkc.VkCommandBuffer,
    flags: vkc.VkCommandBufferResetFlags = 0,
}) !void {
    const begin_info = vkc.VkCommandBufferBeginInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = params.flags,
        .pInheritanceInfo = null,
        .pNext = null,
    };

    if (vkc.vkBeginCommandBuffer(params.command_buffer, &begin_info) != vkc.VK_SUCCESS) {
        return error.VulkanCommandBufferRecordError;
    }
}

pub fn end(params: struct {
    command_buffer: vkc.VkCommandBuffer,
}) !void {
    if (vkc.vkEndCommandBuffer(params.command_buffer) != vkc.VK_SUCCESS) {
        return error.VulkanCommandBufferEndError;
    }
}

pub fn copy(params: struct {
    command_buffer: vkc.VkCommandBuffer,
    src_buffer: vkc.VkBuffer,
    dst_buffer: vkc.VkBuffer,
    size: vkc.VkDeviceSize,
}) !void {
    const copy_region = vkc.VkBufferCopy{
        .srcOffset = 0,
        .dstOffset = 0,
        .size = params.size,
    };
    vkc.vkCmdCopyBuffer(params.command_buffer, params.src_buffer, params.dst_buffer, 1, &copy_region);
}

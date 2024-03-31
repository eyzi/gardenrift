const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;
const renderpass = @import("../pipeline/renderpass.zig");
const swapchain = @import("../swapchain/swapchain.zig");

pub fn record(params: struct {
    pipeline: glfwc.VkPipeline,
    renderpass: glfwc.VkRenderPass,
    command_buffer: glfwc.VkCommandBuffer,
    frame_buffer: glfwc.VkFramebuffer,
    vertex_buffer: glfwc.VkBuffer,
    extent: glfwc.VkExtent2D,
}) !void {
    try begin(.{ .command_buffer = params.command_buffer });
    renderpass.begin(.{
        .renderpass = params.renderpass,
        .command_buffer = params.command_buffer,
        .frame_buffer = params.frame_buffer,
        .extent = params.extent,
    });
    glfwc.vkCmdBindPipeline(params.command_buffer, glfwc.VK_PIPELINE_BIND_POINT_GRAPHICS, params.pipeline);
    glfwc.vkCmdSetViewport(params.command_buffer, 0, 1, &swapchain.create_viewport(.{ .extent = params.extent }));
    glfwc.vkCmdSetScissor(params.command_buffer, 0, 1, &swapchain.create_scissor(.{ .extent = params.extent }));
    glfwc.vkCmdBindVertexBuffers(params.command_buffer, 0, 1, &[_]glfwc.VkBuffer{params.vertex_buffer}, &[_]glfwc.VkDeviceSize{0});
    glfwc.vkCmdDraw(params.command_buffer, 3, 1, 0, 0);
    renderpass.end(.{ .command_buffer = params.command_buffer });
    try end(.{ .command_buffer = params.command_buffer });
}

pub fn record_indexed(params: struct {
    pipeline: glfwc.VkPipeline,
    renderpass: glfwc.VkRenderPass,
    layout: glfwc.VkPipelineLayout,
    command_buffer: glfwc.VkCommandBuffer,
    frame_buffer: glfwc.VkFramebuffer,
    vertex_buffer: glfwc.VkBuffer,
    index_buffer: glfwc.VkBuffer,
    descriptor_set: glfwc.VkDescriptorSet,
    n_index: u32,
    extent: glfwc.VkExtent2D,
}) !void {
    try begin(.{ .command_buffer = params.command_buffer });
    renderpass.begin(.{
        .renderpass = params.renderpass,
        .command_buffer = params.command_buffer,
        .frame_buffer = params.frame_buffer,
        .extent = params.extent,
        .clear_values = &[_]glfwc.VkClearValue{ glfwc.VkClearValue{
            .color = glfwc.VkClearColorValue{
                .float32 = [4]f32{ 0.0, 0.0, 0.0, 0.0 },
            },
        }, glfwc.VkClearValue{
            .depthStencil = glfwc.VkClearDepthStencilValue{
                .depth = 1.0,
                .stencil = 0,
            },
        } },
    });
    glfwc.vkCmdBindPipeline(params.command_buffer, glfwc.VK_PIPELINE_BIND_POINT_GRAPHICS, params.pipeline);
    glfwc.vkCmdSetViewport(params.command_buffer, 0, 1, &swapchain.create_viewport(.{ .extent = params.extent }));
    glfwc.vkCmdSetScissor(params.command_buffer, 0, 1, &swapchain.create_scissor(.{ .extent = params.extent }));
    glfwc.vkCmdBindVertexBuffers(params.command_buffer, 0, 1, &[_]glfwc.VkBuffer{params.vertex_buffer}, &[_]glfwc.VkDeviceSize{0});
    glfwc.vkCmdBindIndexBuffer(params.command_buffer, params.index_buffer, 0, glfwc.VK_INDEX_TYPE_UINT32);
    glfwc.vkCmdBindDescriptorSets(params.command_buffer, glfwc.VK_PIPELINE_BIND_POINT_GRAPHICS, params.layout, 0, 1, &params.descriptor_set, 0, null);
    glfwc.vkCmdDrawIndexed(params.command_buffer, params.n_index, 1, 0, 0, 0);
    renderpass.end(.{ .command_buffer = params.command_buffer });
    try end(.{ .command_buffer = params.command_buffer });
}

pub fn reset(params: struct {
    command_buffer: glfwc.VkCommandBuffer,
    flags: glfwc.VkCommandBufferResetFlags = 0,
}) !void {
    if (glfwc.vkResetCommandBuffer(params.command_buffer, params.flags) != glfwc.VK_SUCCESS) {
        return error.VulkanCommandBufferResetError;
    }
}

pub fn begin(params: struct {
    command_buffer: glfwc.VkCommandBuffer,
    flags: glfwc.VkCommandBufferResetFlags = 0,
}) !void {
    const begin_info = glfwc.VkCommandBufferBeginInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = params.flags,
        .pInheritanceInfo = null,
        .pNext = null,
    };

    if (glfwc.vkBeginCommandBuffer(params.command_buffer, &begin_info) != glfwc.VK_SUCCESS) {
        return error.VulkanCommandBufferRecordError;
    }
}

pub fn end(params: struct {
    command_buffer: glfwc.VkCommandBuffer,
}) !void {
    if (glfwc.vkEndCommandBuffer(params.command_buffer) != glfwc.VK_SUCCESS) {
        return error.VulkanCommandBufferEndError;
    }
}

pub fn copy(params: struct {
    command_buffer: glfwc.VkCommandBuffer,
    src_buffer: glfwc.VkBuffer,
    dst_buffer: glfwc.VkBuffer,
    size: glfwc.VkDeviceSize,
}) !void {
    const copy_region = glfwc.VkBufferCopy{
        .srcOffset = 0,
        .dstOffset = 0,
        .size = params.size,
    };
    glfwc.vkCmdCopyBuffer(params.command_buffer, params.src_buffer, params.dst_buffer, 1, &copy_region);
}

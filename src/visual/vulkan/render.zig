const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;
const command = @import("./command.zig");
const swapchain = @import("./swapchain.zig");
const queue = @import("./queue.zig");
const state = @import("../state.zig");

/// returns a render pass. needs to be destroyed.
pub fn create_render_pass(device: glfwc.VkDevice, surface_format: glfwc.VkSurfaceFormatKHR) !glfwc.VkRenderPass {
    const color_attachment = glfwc.VkAttachmentDescription{
        .format = surface_format.format,
        .samples = glfwc.VK_SAMPLE_COUNT_1_BIT,
        .loadOp = glfwc.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = glfwc.VK_ATTACHMENT_STORE_OP_STORE,
        .stencilLoadOp = glfwc.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        .stencilStoreOp = glfwc.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .initialLayout = glfwc.VK_IMAGE_LAYOUT_UNDEFINED,
        .finalLayout = glfwc.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
        .flags = 0,
    };

    const color_attachment_ref = glfwc.VkAttachmentReference{
        .attachment = 0,
        .layout = glfwc.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
    };

    const subpass = glfwc.VkSubpassDescription{
        .pipelineBindPoint = glfwc.VK_PIPELINE_BIND_POINT_GRAPHICS,
        .colorAttachmentCount = 1,
        .pColorAttachments = &color_attachment_ref,
        .inputAttachmentCount = 0,
        .pInputAttachments = null,
        .pResolveAttachments = null,
        .pDepthStencilAttachment = null,
        .preserveAttachmentCount = 0,
        .pPreserveAttachments = null,
        .flags = 0,
    };

    const dependency = glfwc.VkSubpassDependency{
        .srcSubpass = glfwc.VK_SUBPASS_EXTERNAL,
        .dstSubpass = 0,
        .srcStageMask = glfwc.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
        .srcAccessMask = 0,
        .dstStageMask = glfwc.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
        .dstAccessMask = glfwc.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
        .dependencyFlags = 0,
    };

    const create_info = glfwc.VkRenderPassCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .attachmentCount = 1,
        .pAttachments = &color_attachment,
        .subpassCount = 1,
        .pSubpasses = &subpass,
        .dependencyCount = 1,
        .pDependencies = &dependency,
        .pNext = null,
        .flags = 0,
    };

    var render_pass: glfwc.VkRenderPass = undefined;
    if (glfwc.vkCreateRenderPass(device, &create_info, null, &render_pass) != glfwc.VK_SUCCESS) {
        return error.VulkanRenderPassCreateError;
    }

    return render_pass;
}

pub fn destroy_render_pass(device: glfwc.VkDevice, render_pass: glfwc.VkRenderPass) void {
    glfwc.vkDestroyRenderPass(device, render_pass, null);
}

pub fn begin(render_pass: glfwc.VkRenderPass, command_buffer: glfwc.VkCommandBuffer, frame_buffer: glfwc.VkFramebuffer, extent: glfwc.VkExtent2D) void {
    const pass_info = glfwc.VkRenderPassBeginInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
        .renderPass = render_pass,
        .framebuffer = frame_buffer,
        .renderArea = .{
            .offset = glfwc.VkOffset2D{
                .x = 0,
                .y = 0,
            },
            .extent = extent,
        },
        .clearValueCount = 1,
        .pClearValues = &glfwc.VkClearValue{
            .color = glfwc.VkClearColorValue{
                .float32 = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            },
        },
        .pNext = null,
    };

    glfwc.vkCmdBeginRenderPass(command_buffer, &pass_info, glfwc.VK_SUBPASS_CONTENTS_INLINE);
}

pub fn end(command_buffer: glfwc.VkCommandBuffer) void {
    glfwc.vkCmdEndRenderPass(command_buffer);
}

pub fn draw_frame(current_state: *state.State) !void {
    const timeout = std.math.maxInt(u64);
    const command_buffer = current_state.*.frames.command_buffers[current_state.*.frames.frame_index];
    const image_available_semaphore = current_state.*.frames.image_available_semaphores[current_state.*.frames.frame_index];
    const render_finished_semaphore = current_state.*.frames.render_finished_semaphores[current_state.*.frames.frame_index];
    const in_flight_fence = current_state.*.frames.in_flight_fences[current_state.*.frames.frame_index];

    _ = glfwc.vkWaitForFences(current_state.*.objects.device, 1, &in_flight_fence, glfwc.VK_TRUE, timeout);

    var image_index: u32 = undefined;
    switch (glfwc.vkAcquireNextImageKHR(current_state.*.objects.device, current_state.*.frames.swapchain, timeout, image_available_semaphore, @ptrCast(glfwc.VK_NULL_HANDLE), &image_index)) {
        glfwc.VK_SUCCESS => {},
        else => {
            try swapchain.recreate(current_state);
            return;
        },
    }

    _ = glfwc.vkResetFences(current_state.*.objects.device, 1, &in_flight_fence);

    const frame_buffer = current_state.*.frames.frame_buffers[image_index];

    command.reset(command_buffer) catch |err| {
        current_state.*.run_state = .Failing;
        std.log.warn("command reset: {any}", .{err});
        return err;
    };
    command.begin(command_buffer) catch |err| {
        current_state.*.run_state = .Failing;
        std.log.warn("command begin: {any}", .{err});
        return err;
    };
    begin(current_state.*.objects.render_pass, command_buffer, frame_buffer, current_state.*.frames.extent);
    glfwc.vkCmdBindPipeline(command_buffer, glfwc.VK_PIPELINE_BIND_POINT_GRAPHICS, current_state.*.objects.pipeline);
    glfwc.vkCmdSetViewport(command_buffer, 0, 1, &swapchain.create_viewport(current_state.*.frames.extent));
    glfwc.vkCmdSetScissor(command_buffer, 0, 1, &swapchain.create_scissor(current_state.*.frames.extent));
    glfwc.vkCmdDraw(command_buffer, 3, 1, 0, 0);
    end(command_buffer);
    command.end(command_buffer) catch |err| {
        current_state.*.run_state = .Failing;
        std.log.warn("command end: {any}", .{err});
        return err;
    };

    try queue.submit(current_state.*.objects.graphics_queue, command_buffer, image_available_semaphore, render_finished_semaphore, in_flight_fence, current_state);
    try queue.present(current_state.*.objects.present_queue, current_state.*.frames.swapchain, image_index, render_finished_semaphore, current_state);
}

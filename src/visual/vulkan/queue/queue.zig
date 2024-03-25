const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;

pub fn create(params: struct {
    device: glfwc.VkDevice,
    family_index: u32,
    queue_index: u32 = 0,
}) glfwc.VkQueue {
    var queue: glfwc.VkQueue = undefined;
    glfwc.vkGetDeviceQueue(params.device, params.family_index, params.queue_index, &queue);
    return queue;
}

pub fn submit(params: struct {
    graphics_queue: glfwc.VkQueue,
    command_buffer: glfwc.VkCommandBuffer,
    wait_semaphore: ?glfwc.VkSemaphore = null,
    signal_semaphore: ?glfwc.VkSemaphore = null,
    fence: ?glfwc.VkFence = null,
}) !void {
    var n_wait_semaphore: u32 = 0;
    var wait_semaphores: [1]glfwc.VkSemaphore = undefined;
    if (params.wait_semaphore) |wait_semaphore| {
        n_wait_semaphore = 1;
        wait_semaphores = [1]glfwc.VkSemaphore{
            wait_semaphore,
        };
    }

    var n_signal_semaphore: u32 = 0;
    var signal_semaphores: [1]glfwc.VkSemaphore = undefined;
    if (params.signal_semaphore) |signal_semaphore| {
        n_signal_semaphore = 1;
        signal_semaphores = [1]glfwc.VkSemaphore{
            signal_semaphore,
        };
    }

    var submit_fence: glfwc.VkFence = params.fence orelse @ptrCast(glfwc.VK_NULL_HANDLE);

    const submit_info = glfwc.VkSubmitInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .waitSemaphoreCount = n_wait_semaphore,
        .pWaitSemaphores = &wait_semaphores,
        .pWaitDstStageMask = &[_]glfwc.VkPipelineStageFlags{
            glfwc.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
        },
        .commandBufferCount = 1,
        .pCommandBuffers = &params.command_buffer,
        .signalSemaphoreCount = n_signal_semaphore,
        .pSignalSemaphores = &signal_semaphores,
        .pNext = null,
    };
    if (glfwc.vkQueueSubmit(params.graphics_queue, 1, &submit_info, submit_fence) != glfwc.VK_SUCCESS) {
        return error.VulkanQueueSubmitError;
    }
}

pub fn present(params: struct {
    present_queue: glfwc.VkQueue,
    swapchain: glfwc.VkSwapchainKHR,
    image_index: u32,
    render_finished_semaphore: glfwc.VkSemaphore,
}) !void {
    const present_info = glfwc.VkPresentInfoKHR{
        .sType = glfwc.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
        .waitSemaphoreCount = 1,
        .pWaitSemaphores = &[_]glfwc.VkSemaphore{
            params.render_finished_semaphore,
        },
        .swapchainCount = 1,
        .pSwapchains = &[_]glfwc.VkSwapchainKHR{
            params.swapchain,
        },
        .pImageIndices = &params.image_index,
        .pResults = null,
        .pNext = null,
    };

    switch (glfwc.vkQueuePresentKHR(params.present_queue, &present_info)) {
        glfwc.VK_SUCCESS => {},
        glfwc.VK_ERROR_OUT_OF_DATE_KHR, glfwc.VK_SUBOPTIMAL_KHR => {
            return error.OutOfDate;
        },
        else => return error.VulkanQueuePresentError,
    }
}

pub fn wait_idle(params: struct {
    graphics_queue: glfwc.VkQueue,
}) !void {
    if (glfwc.vkQueueWaitIdle(params.graphics_queue) != glfwc.VK_SUCCESS) {
        return error.VulkanQueueWaitIdleError;
    }
}

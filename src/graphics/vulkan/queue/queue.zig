const std = @import("std");
const vkc = @import("../vk-c.zig").c;

pub fn create(params: struct {
    device: vkc.VkDevice,
    family_index: u32,
    queue_index: u32 = 0,
}) vkc.VkQueue {
    var queue: vkc.VkQueue = undefined;
    vkc.vkGetDeviceQueue(params.device, params.family_index, params.queue_index, &queue);
    return queue;
}

pub fn submit(params: struct {
    graphics_queue: vkc.VkQueue,
    command_buffer: vkc.VkCommandBuffer,
    wait_semaphore: ?vkc.VkSemaphore = null,
    signal_semaphore: ?vkc.VkSemaphore = null,
    fence: ?vkc.VkFence = null,
}) !void {
    var n_wait_semaphore: u32 = 0;
    var wait_semaphores: [1]vkc.VkSemaphore = undefined;
    if (params.wait_semaphore) |wait_semaphore| {
        n_wait_semaphore = 1;
        wait_semaphores = [1]vkc.VkSemaphore{
            wait_semaphore,
        };
    }

    var n_signal_semaphore: u32 = 0;
    var signal_semaphores: [1]vkc.VkSemaphore = undefined;
    if (params.signal_semaphore) |signal_semaphore| {
        n_signal_semaphore = 1;
        signal_semaphores = [1]vkc.VkSemaphore{
            signal_semaphore,
        };
    }

    var submit_fence: vkc.VkFence = params.fence orelse @ptrCast(vkc.VK_NULL_HANDLE);

    const submit_info = vkc.VkSubmitInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .waitSemaphoreCount = n_wait_semaphore,
        .pWaitSemaphores = &wait_semaphores,
        .pWaitDstStageMask = &[_]vkc.VkPipelineStageFlags{
            vkc.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
        },
        .commandBufferCount = 1,
        .pCommandBuffers = &params.command_buffer,
        .signalSemaphoreCount = n_signal_semaphore,
        .pSignalSemaphores = &signal_semaphores,
        .pNext = null,
    };
    if (vkc.vkQueueSubmit(params.graphics_queue, 1, &submit_info, submit_fence) != vkc.VK_SUCCESS) {
        return error.VulkanQueueSubmitError;
    }
}

pub fn present(params: struct {
    present_queue: vkc.VkQueue,
    swapchain: vkc.VkSwapchainKHR,
    image_index: u32,
    render_finished_semaphore: vkc.VkSemaphore,
}) !void {
    const present_info = vkc.VkPresentInfoKHR{
        .sType = vkc.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
        .waitSemaphoreCount = 1,
        .pWaitSemaphores = &[_]vkc.VkSemaphore{
            params.render_finished_semaphore,
        },
        .swapchainCount = 1,
        .pSwapchains = &[_]vkc.VkSwapchainKHR{
            params.swapchain,
        },
        .pImageIndices = &params.image_index,
        .pResults = null,
        .pNext = null,
    };

    switch (vkc.vkQueuePresentKHR(params.present_queue, &present_info)) {
        vkc.VK_SUCCESS => {},
        vkc.VK_ERROR_OUT_OF_DATE_KHR, vkc.VK_SUBOPTIMAL_KHR => {
            return error.OutOfDate;
        },
        else => return error.VulkanQueuePresentError,
    }
}

pub fn wait_idle(params: struct {
    graphics_queue: vkc.VkQueue,
}) !void {
    if (vkc.vkQueueWaitIdle(params.graphics_queue) != vkc.VK_SUCCESS) {
        return error.VulkanQueueWaitIdleError;
    }
}

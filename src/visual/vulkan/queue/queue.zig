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
    image_available_semaphore: glfwc.VkSemaphore,
    render_finished_semaphore: glfwc.VkSemaphore,
    in_flight_fence: glfwc.VkFence,
}) !void {
    const submit_info = glfwc.VkSubmitInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .waitSemaphoreCount = 1,
        .pWaitSemaphores = &[_]glfwc.VkSemaphore{
            params.image_available_semaphore,
        },
        .pWaitDstStageMask = &[_]glfwc.VkPipelineStageFlags{
            glfwc.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
        },
        .commandBufferCount = 1,
        .pCommandBuffers = &params.command_buffer,
        .signalSemaphoreCount = 1,
        .pSignalSemaphores = &[_]glfwc.VkSemaphore{
            params.render_finished_semaphore,
        },
        .pNext = null,
    };
    if (glfwc.vkQueueSubmit(params.graphics_queue, 1, &submit_info, params.in_flight_fence) != glfwc.VK_SUCCESS) {
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

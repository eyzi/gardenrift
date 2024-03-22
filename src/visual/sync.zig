const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;

/// returns a semaphore. needs to be destroyed.
pub fn create_semaphore(device: glfwc.VkDevice) !glfwc.VkSemaphore {
    const create_info = glfwc.VkSemaphoreCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
    };
    var semaphore: glfwc.VkSemaphore = undefined;
    if (glfwc.vkCreateSemaphore(device, &create_info, null, &semaphore) != glfwc.VK_SUCCESS) {
        return error.VulkanSemaphoreCreateError;
    }
    return semaphore;
}

pub fn destroy_semaphore(device: glfwc.VkDevice, semaphore: glfwc.VkSemaphore) void {
    glfwc.vkDestroySemaphore(device, semaphore, null);
}

/// returns a fence. needs to be destroyed.
pub fn create_fence(device: glfwc.VkDevice) !glfwc.VkFence {
    const create_info = glfwc.VkFenceCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        .flags = glfwc.VK_FENCE_CREATE_SIGNALED_BIT,
        .pNext = null,
    };
    var fence: glfwc.VkFence = undefined;
    if (glfwc.vkCreateFence(device, &create_info, null, &fence) != glfwc.VK_SUCCESS) {
        return error.VulkanFenceCreateError;
    }
    return fence;
}

pub fn destroy_fence(device: glfwc.VkDevice, fence: glfwc.VkFence) void {
    glfwc.vkDestroyFence(device, fence, null);
}

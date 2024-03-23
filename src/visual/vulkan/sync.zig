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

/// returns a list of semaphores. needs to be destroyed.
pub fn create_semaphores(device: glfwc.VkDevice, n_semaphores: usize, allocator: std.mem.Allocator) ![]glfwc.VkSemaphore {
    var semaphores = try std.ArrayList(glfwc.VkSemaphore).initCapacity(allocator, n_semaphores);
    defer semaphores.deinit();

    for (0..semaphores.capacity) |_| {
        const s = try create_semaphore(device);
        try semaphores.append(s);
    }

    return semaphores.toOwnedSlice();
}

pub fn destroy_semaphores(device: glfwc.VkDevice, semaphores: []glfwc.VkSemaphore, allocator: std.mem.Allocator) void {
    for (semaphores) |semaphore| {
        destroy_semaphore(device, semaphore);
    }
    allocator.free(semaphores);
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

/// returns a list of fences. needs to be destroyed.
pub fn create_fences(device: glfwc.VkDevice, n_fences: usize, allocator: std.mem.Allocator) ![]glfwc.VkFence {
    var fences = try std.ArrayList(glfwc.VkFence).initCapacity(allocator, n_fences);
    defer fences.deinit();

    for (0..fences.capacity) |_| {
        try fences.append(try create_fence(device));
    }

    return fences.toOwnedSlice();
}

pub fn destroy_fences(device: glfwc.VkDevice, fences: []glfwc.VkFence, allocator: std.mem.Allocator) void {
    for (fences) |fence| {
        destroy_fence(device, fence);
    }
    allocator.free(fences);
}

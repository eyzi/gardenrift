const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;

/// returns a semaphore. needs to be destroyed.
pub fn create_semaphore(params: struct {
    device: glfwc.VkDevice,
}) !glfwc.VkSemaphore {
    const create_info = glfwc.VkSemaphoreCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
    };
    var semaphore: glfwc.VkSemaphore = undefined;
    if (glfwc.vkCreateSemaphore(params.device, &create_info, null, &semaphore) != glfwc.VK_SUCCESS) {
        return error.VulkanSemaphoreCreateError;
    }
    return semaphore;
}

pub fn destroy_semaphore(params: struct {
    device: glfwc.VkDevice,
    semaphore: glfwc.VkSemaphore,
}) void {
    glfwc.vkDestroySemaphore(params.device, params.semaphore, null);
}

/// returns a list of semaphores. needs to be destroyed.
pub fn create_semaphores(params: struct {
    device: glfwc.VkDevice,
    n_semaphores: usize,
    allocator: std.mem.Allocator,
}) ![]glfwc.VkSemaphore {
    var semaphores = try std.ArrayList(glfwc.VkSemaphore).initCapacity(params.allocator, params.n_semaphores);
    defer semaphores.deinit();

    for (0..semaphores.capacity) |_| {
        const s = try create_semaphore(.{ .device = params.device });
        try semaphores.append(s);
    }

    return semaphores.toOwnedSlice();
}

pub fn destroy_semaphores(params: struct {
    device: glfwc.VkDevice,
    semaphores: []glfwc.VkSemaphore,
    allocator: std.mem.Allocator,
}) void {
    for (params.semaphores) |semaphore| {
        destroy_semaphore(.{
            .device = params.device,
            .semaphore = semaphore,
        });
    }
    params.allocator.free(params.semaphores);
}

/// returns a fence. needs to be destroyed.
pub fn create_fence(params: struct {
    device: glfwc.VkDevice,
}) !glfwc.VkFence {
    const create_info = glfwc.VkFenceCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        .flags = glfwc.VK_FENCE_CREATE_SIGNALED_BIT,
        .pNext = null,
    };
    var fence: glfwc.VkFence = undefined;
    if (glfwc.vkCreateFence(params.device, &create_info, null, &fence) != glfwc.VK_SUCCESS) {
        return error.VulkanFenceCreateError;
    }
    return fence;
}

pub fn destroy_fence(params: struct {
    device: glfwc.VkDevice,
    fence: glfwc.VkFence,
}) void {
    glfwc.vkDestroyFence(params.device, params.fence, null);
}

/// returns a list of fences. needs to be destroyed.
pub fn create_fences(params: struct {
    device: glfwc.VkDevice,
    n_fences: usize,
    allocator: std.mem.Allocator,
}) ![]glfwc.VkFence {
    var fences = try std.ArrayList(glfwc.VkFence).initCapacity(params.allocator, params.n_fences);
    defer fences.deinit();

    for (0..fences.capacity) |_| {
        try fences.append(try create_fence(.{ .device = params.device }));
    }

    return fences.toOwnedSlice();
}

pub fn destroy_fences(params: struct {
    device: glfwc.VkDevice,
    fences: []glfwc.VkFence,
    allocator: std.mem.Allocator,
}) void {
    for (params.fences) |fence| {
        destroy_fence(.{
            .device = params.device,
            .fence = fence,
        });
    }
    params.allocator.free(params.fences);
}

pub fn wait_for_fences(params: struct {
    device: glfwc.VkDevice,
    fences: []const glfwc.VkFence,
    timeout: u64 = std.math.maxInt(u64),
}) !void {
    if (glfwc.vkWaitForFences(params.device, @as(u32, @intCast(params.fences.len)), params.fences.ptr, glfwc.VK_TRUE, params.timeout) != glfwc.VK_SUCCESS) {
        return error.VulkanFencesWaitError;
    }
}

pub fn wait_for_fence(params: struct {
    device: glfwc.VkDevice,
    fence: glfwc.VkFence,
    timeout: u64 = std.math.maxInt(u64),
}) !void {
    try wait_for_fences(.{
        .device = params.device,
        .fences = &[_]glfwc.VkFence{params.fence},
        .timeout = params.timeout,
    });
}

pub fn reset_fences(params: struct {
    device: glfwc.VkDevice,
    fences: []const glfwc.VkFence,
}) !void {
    if (glfwc.vkResetFences(params.device, @as(u32, @intCast(params.fences.len)), params.fences.ptr) != glfwc.VK_SUCCESS) {
        return error.VulkanFencesResetError;
    }
}

pub fn reset_fence(params: struct {
    device: glfwc.VkDevice,
    fence: glfwc.VkFence,
}) !void {
    try reset_fences(.{
        .device = params.device,
        .fences = &[_]glfwc.VkFence{params.fence},
    });
}

const std = @import("std");
const vkc = @import("../vk-c.zig").c;

/// returns a semaphore. needs to be destroyed.
pub fn create_semaphore(params: struct {
    device: vkc.VkDevice,
}) !vkc.VkSemaphore {
    const create_info = vkc.VkSemaphoreCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
    };
    var semaphore: vkc.VkSemaphore = undefined;
    if (vkc.vkCreateSemaphore(params.device, &create_info, null, &semaphore) != vkc.VK_SUCCESS) {
        return error.VulkanSemaphoreCreateError;
    }
    return semaphore;
}

pub fn destroy_semaphore(params: struct {
    device: vkc.VkDevice,
    semaphore: vkc.VkSemaphore,
}) void {
    vkc.vkDestroySemaphore(params.device, params.semaphore, null);
}

/// returns a list of semaphores. needs to be destroyed.
pub fn create_semaphores(params: struct {
    device: vkc.VkDevice,
    n_semaphores: usize,
    allocator: std.mem.Allocator,
}) ![]vkc.VkSemaphore {
    var semaphores = try std.ArrayList(vkc.VkSemaphore).initCapacity(params.allocator, params.n_semaphores);
    defer semaphores.deinit();

    for (0..semaphores.capacity) |_| {
        const s = try create_semaphore(.{ .device = params.device });
        try semaphores.append(s);
    }

    return semaphores.toOwnedSlice();
}

pub fn destroy_semaphores(params: struct {
    device: vkc.VkDevice,
    semaphores: []vkc.VkSemaphore,
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
    device: vkc.VkDevice,
}) !vkc.VkFence {
    const create_info = vkc.VkFenceCreateInfo{
        .sType = vkc.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        .flags = vkc.VK_FENCE_CREATE_SIGNALED_BIT,
        .pNext = null,
    };
    var fence: vkc.VkFence = undefined;
    if (vkc.vkCreateFence(params.device, &create_info, null, &fence) != vkc.VK_SUCCESS) {
        return error.VulkanFenceCreateError;
    }
    return fence;
}

pub fn destroy_fence(params: struct {
    device: vkc.VkDevice,
    fence: vkc.VkFence,
}) void {
    vkc.vkDestroyFence(params.device, params.fence, null);
}

/// returns a list of fences. needs to be destroyed.
pub fn create_fences(params: struct {
    device: vkc.VkDevice,
    n_fences: usize,
    allocator: std.mem.Allocator,
}) ![]vkc.VkFence {
    var fences = try std.ArrayList(vkc.VkFence).initCapacity(params.allocator, params.n_fences);
    defer fences.deinit();

    for (0..fences.capacity) |_| {
        try fences.append(try create_fence(.{ .device = params.device }));
    }

    return fences.toOwnedSlice();
}

pub fn destroy_fences(params: struct {
    device: vkc.VkDevice,
    fences: []vkc.VkFence,
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
    device: vkc.VkDevice,
    fences: []const vkc.VkFence,
    timeout: u64 = std.math.maxInt(u64),
}) !void {
    if (vkc.vkWaitForFences(params.device, @as(u32, @intCast(params.fences.len)), params.fences.ptr, vkc.VK_TRUE, params.timeout) != vkc.VK_SUCCESS) {
        return error.VulkanFencesWaitError;
    }
}

pub fn wait_for_fence(params: struct {
    device: vkc.VkDevice,
    fence: vkc.VkFence,
    timeout: u64 = std.math.maxInt(u64),
}) !void {
    try wait_for_fences(.{
        .device = params.device,
        .fences = &[_]vkc.VkFence{params.fence},
        .timeout = params.timeout,
    });
}

pub fn reset_fences(params: struct {
    device: vkc.VkDevice,
    fences: []const vkc.VkFence,
}) !void {
    if (vkc.vkResetFences(params.device, @as(u32, @intCast(params.fences.len)), params.fences.ptr) != vkc.VK_SUCCESS) {
        return error.VulkanFencesResetError;
    }
}

pub fn reset_fence(params: struct {
    device: vkc.VkDevice,
    fence: vkc.VkFence,
}) !void {
    try reset_fences(.{
        .device = params.device,
        .fences = &[_]vkc.VkFence{params.fence},
    });
}

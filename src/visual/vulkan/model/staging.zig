const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;
const buffer = @import("./buffer.zig");
const command = @import("../command/command.zig");
const command_buffer = @import("../command/buffer.zig");
const command_pool = @import("../command/pool.zig");
const memory = @import("./memory.zig");
const queue = @import("../queue/queue.zig");
const QueueFamilyIndices = @import("../types.zig").QueueFamilyIndices;

pub fn stage(comptime T: type, params: struct {
    device: glfwc.VkDevice,
    physical_device: glfwc.VkPhysicalDevice,
    queue_family_indices: QueueFamilyIndices,
    graphics_queue: glfwc.VkQueue,
    data: []const T,
    dst_buffer: glfwc.VkBuffer,
    allocator: std.mem.Allocator,
}) !void {
    // create staging buffer
    const staging_buffer_object = try buffer.create_and_allocate(.{
        .device = params.device,
        .physical_device = params.physical_device,
        .size = @sizeOf(T) * params.data.len,
        .usage = glfwc.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
        .sharing_mode = glfwc.VK_SHARING_MODE_EXCLUSIVE,
        .properties = glfwc.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | glfwc.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
    });
    defer buffer.destroy_and_deallocate(.{
        .device = params.device,
        .buffer = staging_buffer_object.buffer,
        .buffer_memory = staging_buffer_object.buffer_memory,
    });

    // map buffer to memory
    _ = try memory.map_memory(T, .{
        .device = params.device,
        .data = params.data,
        .buffer_create_info = staging_buffer_object.buffer_create_info,
        .buffer_memory = staging_buffer_object.buffer_memory,
    });
    defer memory.unmap_memory(.{
        .device = params.device,
        .buffer_memory = staging_buffer_object.buffer_memory,
    });

    // create command pool for staging buffer copy
    const staging_command_pool = try command_pool.create(.{
        .device = params.device,
        .queue_family_indices = params.queue_family_indices,
        .flags = glfwc.VK_COMMAND_POOL_CREATE_TRANSIENT_BIT,
    });
    defer command_pool.destroy(.{
        .device = params.device,
        .command_pool = staging_command_pool,
    });

    // create command buffer for staging buffer copy
    const staging_command_buffers = try command_buffer.create(.{
        .device = params.device,
        .command_pool = staging_command_pool,
        .n_buffers = 1,
        .allocator = params.allocator,
    });
    defer command_buffer.destroy(.{
        .command_buffers = staging_command_buffers,
        .allocator = params.allocator,
    });

    // begin copy command
    try command.begin(.{
        .command_buffer = staging_command_buffers[0],
        .flags = glfwc.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
    });
    try command.copy(.{
        .command_buffer = staging_command_buffers[0],
        .src_buffer = staging_buffer_object.buffer,
        .dst_buffer = params.dst_buffer,
        .size = @sizeOf(T) * params.data.len,
    });

    // end copy command
    try command.end(.{ .command_buffer = staging_command_buffers[0] });
    try queue.submit(.{
        .graphics_queue = params.graphics_queue,
        .command_buffer = staging_command_buffers[0],
    });
    try queue.wait_idle(.{ .graphics_queue = params.graphics_queue });
}

const std = @import("std");
const vkc = @import("../vk-c.zig").c;
const buffer = @import("../model/buffer.zig");
const command = @import("./command.zig");
const command_buffer = @import("./buffer.zig");
const command_pool = @import("./pool.zig");
const memory = @import("../model/memory.zig");
const queue = @import("../queue/queue.zig");
const QueueFamilyIndices = @import("../types.zig").QueueFamilyIndices;

pub fn stage(comptime T: type, params: struct {
    device: vkc.VkDevice,
    physical_device: vkc.VkPhysicalDevice,
    queue_family_indices: QueueFamilyIndices,
    graphics_queue: vkc.VkQueue,
    data: []const T,
    dst_buffer: vkc.VkBuffer,
    allocator: std.mem.Allocator,
}) !void {
    // create staging buffer
    const staging_buffer_object = try buffer.create_and_allocate(.{
        .device = params.device,
        .physical_device = params.physical_device,
        .size = @sizeOf(T) * params.data.len,
        .usage = vkc.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
        .sharing_mode = vkc.VK_SHARING_MODE_EXCLUSIVE,
        .properties = vkc.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vkc.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
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
        .flags = vkc.VK_COMMAND_POOL_CREATE_TRANSIENT_BIT,
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
        .flags = vkc.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
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

    command_buffer.free(.{
        .device = params.device,
        .command_pool = staging_command_pool,
        .command_buffers = staging_command_buffers,
    });
}

pub fn stage_image_transition(params: struct {
    device: vkc.VkDevice,
    physical_device: vkc.VkPhysicalDevice,
    queue_family_indices: QueueFamilyIndices,
    graphics_queue: vkc.VkQueue,
    image: vkc.VkImage,
    width: u32,
    height: u32,
    old_layout: u32,
    new_layout: u32,
    src_access_mask: u32 = 0,
    dst_access_mask: u32 = 0,
    src_stage_mask: u32 = 0,
    dst_stage_mask: u32 = 0,
    mip_levels: u32 = 1,
    aspect_mask: vkc.VkImageAspectFlags = vkc.VK_IMAGE_ASPECT_COLOR_BIT,
    allocator: std.mem.Allocator,
}) !void {
    // create command pool for staging buffer copy
    const staging_command_pool = try command_pool.create(.{
        .device = params.device,
        .queue_family_indices = params.queue_family_indices,
        .flags = vkc.VK_COMMAND_POOL_CREATE_TRANSIENT_BIT,
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
        .flags = vkc.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
    });

    // IMAGE SPECIFIC AREA START

    const barrier = vkc.VkImageMemoryBarrier{
        .sType = vkc.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        .oldLayout = params.old_layout,
        .newLayout = params.new_layout,
        .srcQueueFamilyIndex = vkc.VK_QUEUE_FAMILY_IGNORED,
        .dstQueueFamilyIndex = vkc.VK_QUEUE_FAMILY_IGNORED,
        .image = params.image,
        .subresourceRange = .{
            .aspectMask = params.aspect_mask,
            .baseMipLevel = 0,
            .levelCount = params.mip_levels,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
        .srcAccessMask = params.src_access_mask,
        .dstAccessMask = params.dst_access_mask,
        .pNext = null,
    };
    vkc.vkCmdPipelineBarrier(
        staging_command_buffers[0],
        params.src_stage_mask,
        params.dst_stage_mask,
        0,
        0,
        null,
        0,
        null,
        1,
        &barrier,
    );

    // IMAGE SPECIFIC AREA END

    // end copy command
    try command.end(.{ .command_buffer = staging_command_buffers[0] });
    try queue.submit(.{
        .graphics_queue = params.graphics_queue,
        .command_buffer = staging_command_buffers[0],
    });
    try queue.wait_idle(.{ .graphics_queue = params.graphics_queue });

    command_buffer.free(.{
        .device = params.device,
        .command_pool = staging_command_pool,
        .command_buffers = staging_command_buffers,
    });
}

pub fn stage_image_copy(comptime T: type, params: struct {
    device: vkc.VkDevice,
    physical_device: vkc.VkPhysicalDevice,
    queue_family_indices: QueueFamilyIndices,
    graphics_queue: vkc.VkQueue,
    data: []const T,
    image: vkc.VkImage,
    width: u32,
    height: u32,
    allocator: std.mem.Allocator,
}) !void {
    // create staging buffer
    const staging_buffer_object = try buffer.create_and_allocate(.{
        .device = params.device,
        .physical_device = params.physical_device,
        .size = @sizeOf(T) * params.data.len,
        .usage = vkc.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
        .sharing_mode = vkc.VK_SHARING_MODE_EXCLUSIVE,
        .properties = vkc.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vkc.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
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
        .flags = vkc.VK_COMMAND_POOL_CREATE_TRANSIENT_BIT,
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
        .flags = vkc.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
    });

    // IMAGE SPECIFIC AREA START

    const region = vkc.VkBufferImageCopy{
        .bufferOffset = 0,
        .bufferRowLength = 0,
        .bufferImageHeight = 0,
        .imageSubresource = .{
            .aspectMask = vkc.VK_IMAGE_ASPECT_COLOR_BIT,
            .mipLevel = 0,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
        .imageOffset = .{ .x = 0, .y = 0, .z = 0 },
        .imageExtent = .{ .width = params.width, .height = params.height, .depth = 1 },
    };
    vkc.vkCmdCopyBufferToImage(
        staging_command_buffers[0],
        staging_buffer_object.buffer,
        params.image,
        vkc.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        1,
        &region,
    );

    // IMAGE SPECIFIC AREA END

    // end copy command
    try command.end(.{ .command_buffer = staging_command_buffers[0] });
    try queue.submit(.{
        .graphics_queue = params.graphics_queue,
        .command_buffer = staging_command_buffers[0],
    });
    try queue.wait_idle(.{ .graphics_queue = params.graphics_queue });

    command_buffer.free(.{
        .device = params.device,
        .command_pool = staging_command_pool,
        .command_buffers = staging_command_buffers,
    });
}

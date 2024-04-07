const std = @import("std");
const vkc = @import("../vk-c.zig").c;
const command = @import("../command/command.zig");
const command_buffer = @import("../command/buffer.zig");
const command_pool = @import("../command/pool.zig");
const physical_device = @import("../instance/physical-device.zig");
const queue = @import("../queue/queue.zig");
const QueueFamilyIndices = @import("../types.zig").QueueFamilyIndices;

pub fn generate(params: struct {
    device: vkc.VkDevice,
    physical_device: vkc.VkPhysicalDevice,
    queue_family_indices: QueueFamilyIndices,
    graphics_queue: vkc.VkQueue,
    image: vkc.VkImage,
    format: vkc.VkFormat,
    width: u32,
    height: u32,
    mip_levels: u32 = 1,
    aspect_mask: vkc.VkImageAspectFlags = vkc.VK_IMAGE_ASPECT_COLOR_BIT,
    allocator: std.mem.Allocator,
}) !void {
    const properties = physical_device.get_format_properties(.{ .physical_device = params.physical_device, .format = params.format });
    if (properties.optimalTilingFeatures & vkc.VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT != vkc.VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT) {
        return error.MipmapNotSupported;
    }

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

    var mip_width: i32 = @as(i32, @intCast(params.width));
    var mip_height: i32 = @as(i32, @intCast(params.height));

    for (1..params.mip_levels) |mip_level| {
        const barrier = vkc.VkImageMemoryBarrier{
            .sType = vkc.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            .image = params.image,
            .oldLayout = vkc.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
            .newLayout = vkc.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
            .srcQueueFamilyIndex = vkc.VK_QUEUE_FAMILY_IGNORED,
            .dstQueueFamilyIndex = vkc.VK_QUEUE_FAMILY_IGNORED,
            .subresourceRange = .{
                .aspectMask = params.aspect_mask,
                .baseMipLevel = @as(u32, @intCast(mip_level - 1)),
                .levelCount = 1,
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
            .srcAccessMask = vkc.VK_ACCESS_TRANSFER_WRITE_BIT,
            .dstAccessMask = vkc.VK_ACCESS_TRANSFER_READ_BIT,
            .pNext = null,
        };
        vkc.vkCmdPipelineBarrier(
            staging_command_buffers[0],
            vkc.VK_PIPELINE_STAGE_TRANSFER_BIT,
            vkc.VK_PIPELINE_STAGE_TRANSFER_BIT,
            0,
            0,
            null,
            0,
            null,
            1,
            &barrier,
        );

        const blit = vkc.VkImageBlit{
            .srcOffsets = [2]vkc.VkOffset3D{
                vkc.VkOffset3D{ .x = 0, .y = 0, .z = 0 },
                vkc.VkOffset3D{
                    .x = mip_width,
                    .y = mip_height,
                    .z = 1,
                },
            },
            .srcSubresource = .{
                .aspectMask = params.aspect_mask,
                .mipLevel = @as(u32, @intCast(mip_level - 1)),
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
            .dstOffsets = [2]vkc.VkOffset3D{
                vkc.VkOffset3D{ .x = 0, .y = 0, .z = 0 },
                vkc.VkOffset3D{
                    .x = if (mip_width > 1) @divFloor(mip_width, 2) else 1,
                    .y = if (mip_height > 1) @divFloor(mip_height, 2) else 1,
                    .z = 1,
                },
            },
            .dstSubresource = .{
                .aspectMask = params.aspect_mask,
                .mipLevel = @as(u32, @intCast(mip_level)),
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
        };
        vkc.vkCmdBlitImage(
            staging_command_buffers[0],
            params.image,
            vkc.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
            params.image,
            vkc.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
            1,
            &blit,
            vkc.VK_FILTER_LINEAR,
        );

        const barrier2 = vkc.VkImageMemoryBarrier{
            .sType = vkc.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            .image = params.image,
            .oldLayout = vkc.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
            .newLayout = vkc.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
            .srcQueueFamilyIndex = vkc.VK_QUEUE_FAMILY_IGNORED,
            .dstQueueFamilyIndex = vkc.VK_QUEUE_FAMILY_IGNORED,
            .subresourceRange = .{
                .aspectMask = params.aspect_mask,
                .baseMipLevel = @as(u32, @intCast(mip_level - 1)),
                .levelCount = 1,
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
            .srcAccessMask = vkc.VK_ACCESS_TRANSFER_READ_BIT,
            .dstAccessMask = vkc.VK_ACCESS_SHADER_READ_BIT,
            .pNext = null,
        };
        vkc.vkCmdPipelineBarrier(
            staging_command_buffers[0],
            vkc.VK_PIPELINE_STAGE_TRANSFER_BIT,
            vkc.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
            0,
            0,
            null,
            0,
            null,
            1,
            &barrier2,
        );

        if (mip_width > 1) {
            mip_width = @divFloor(mip_width, 2);
        } else {
            mip_width = 1;
        }
        if (mip_height > 1) {
            mip_height = @divFloor(mip_height, 2);
        } else {
            mip_height = 1;
        }
    }

    const barrier_last = vkc.VkImageMemoryBarrier{
        .sType = vkc.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        .image = params.image,
        .oldLayout = vkc.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        .newLayout = vkc.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        .srcQueueFamilyIndex = vkc.VK_QUEUE_FAMILY_IGNORED,
        .dstQueueFamilyIndex = vkc.VK_QUEUE_FAMILY_IGNORED,
        .subresourceRange = .{
            .aspectMask = params.aspect_mask,
            .baseMipLevel = params.mip_levels - 1,
            .levelCount = 1,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
        .srcAccessMask = vkc.VK_ACCESS_TRANSFER_WRITE_BIT,
        .dstAccessMask = vkc.VK_ACCESS_SHADER_READ_BIT,
        .pNext = null,
    };
    vkc.vkCmdPipelineBarrier(
        staging_command_buffers[0],
        vkc.VK_PIPELINE_STAGE_TRANSFER_BIT,
        vkc.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
        0,
        0,
        null,
        0,
        null,
        1,
        &barrier_last,
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

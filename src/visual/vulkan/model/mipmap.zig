const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;
const command = @import("../command/command.zig");
const command_buffer = @import("../command/buffer.zig");
const command_pool = @import("../command/pool.zig");
const physical_device = @import("../instance/physical-device.zig");
const queue = @import("../queue/queue.zig");
const QueueFamilyIndices = @import("../types.zig").QueueFamilyIndices;

pub fn generate(params: struct {
    device: glfwc.VkDevice,
    physical_device: glfwc.VkPhysicalDevice,
    queue_family_indices: QueueFamilyIndices,
    graphics_queue: glfwc.VkQueue,
    image: glfwc.VkImage,
    format: glfwc.VkFormat,
    width: u32,
    height: u32,
    mip_levels: u32 = 1,
    aspect_mask: glfwc.VkImageAspectFlags = glfwc.VK_IMAGE_ASPECT_COLOR_BIT,
    allocator: std.mem.Allocator,
}) !void {
    const properties = physical_device.get_format_properties(.{ .physical_device = params.physical_device, .format = params.format });
    if (properties.optimalTilingFeatures & glfwc.VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT != glfwc.VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT) {
        return error.MipmapNotSupported;
    }

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

    // IMAGE SPECIFIC AREA START

    var mip_width: i32 = @as(i32, @intCast(params.width));
    var mip_height: i32 = @as(i32, @intCast(params.height));

    for (1..params.mip_levels) |mip_level| {
        const barrier = glfwc.VkImageMemoryBarrier{
            .sType = glfwc.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            .image = params.image,
            .oldLayout = glfwc.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
            .newLayout = glfwc.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
            .srcQueueFamilyIndex = glfwc.VK_QUEUE_FAMILY_IGNORED,
            .dstQueueFamilyIndex = glfwc.VK_QUEUE_FAMILY_IGNORED,
            .subresourceRange = .{
                .aspectMask = params.aspect_mask,
                .baseMipLevel = @as(u32, @intCast(mip_level - 1)),
                .levelCount = 1,
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
            .srcAccessMask = glfwc.VK_ACCESS_TRANSFER_WRITE_BIT,
            .dstAccessMask = glfwc.VK_ACCESS_TRANSFER_READ_BIT,
            .pNext = null,
        };
        glfwc.vkCmdPipelineBarrier(
            staging_command_buffers[0],
            glfwc.VK_PIPELINE_STAGE_TRANSFER_BIT,
            glfwc.VK_PIPELINE_STAGE_TRANSFER_BIT,
            0,
            0,
            null,
            0,
            null,
            1,
            &barrier,
        );

        const blit = glfwc.VkImageBlit{
            .srcOffsets = [2]glfwc.VkOffset3D{
                glfwc.VkOffset3D{ .x = 0, .y = 0, .z = 0 },
                glfwc.VkOffset3D{
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
            .dstOffsets = [2]glfwc.VkOffset3D{
                glfwc.VkOffset3D{ .x = 0, .y = 0, .z = 0 },
                glfwc.VkOffset3D{
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
        glfwc.vkCmdBlitImage(
            staging_command_buffers[0],
            params.image,
            glfwc.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
            params.image,
            glfwc.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
            1,
            &blit,
            glfwc.VK_FILTER_LINEAR,
        );

        const barrier2 = glfwc.VkImageMemoryBarrier{
            .sType = glfwc.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            .image = params.image,
            .oldLayout = glfwc.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
            .newLayout = glfwc.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
            .srcQueueFamilyIndex = glfwc.VK_QUEUE_FAMILY_IGNORED,
            .dstQueueFamilyIndex = glfwc.VK_QUEUE_FAMILY_IGNORED,
            .subresourceRange = .{
                .aspectMask = params.aspect_mask,
                .baseMipLevel = @as(u32, @intCast(mip_level - 1)),
                .levelCount = 1,
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
            .srcAccessMask = glfwc.VK_ACCESS_TRANSFER_READ_BIT,
            .dstAccessMask = glfwc.VK_ACCESS_SHADER_READ_BIT,
            .pNext = null,
        };
        glfwc.vkCmdPipelineBarrier(
            staging_command_buffers[0],
            glfwc.VK_PIPELINE_STAGE_TRANSFER_BIT,
            glfwc.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
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

    const barrier_last = glfwc.VkImageMemoryBarrier{
        .sType = glfwc.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        .image = params.image,
        .oldLayout = glfwc.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        .newLayout = glfwc.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        .srcQueueFamilyIndex = glfwc.VK_QUEUE_FAMILY_IGNORED,
        .dstQueueFamilyIndex = glfwc.VK_QUEUE_FAMILY_IGNORED,
        .subresourceRange = .{
            .aspectMask = params.aspect_mask,
            .baseMipLevel = params.mip_levels - 1,
            .levelCount = 1,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
        .srcAccessMask = glfwc.VK_ACCESS_TRANSFER_WRITE_BIT,
        .dstAccessMask = glfwc.VK_ACCESS_SHADER_READ_BIT,
        .pNext = null,
    };
    glfwc.vkCmdPipelineBarrier(
        staging_command_buffers[0],
        glfwc.VK_PIPELINE_STAGE_TRANSFER_BIT,
        glfwc.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
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

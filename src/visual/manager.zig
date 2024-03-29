const std = @import("std");
const vulkan = @import("./vulkan/main.zig");
const image = @import("../library/image/main.zig");
const create_state = @import("./state.zig").create;
const State = @import("./state.zig").State;
const RunState = @import("./state.zig").RunState;
const Vertex = @import("./vulkan/types.zig").Vertex;
const UniformBufferObject = @import("./vulkan/types.zig").UniformBufferObject;

/// initializes objects. needs to be cleaned up.
pub fn setup(params: struct {
    app_name: [:0]const u8,
    initial_window_width: usize,
    initial_window_height: usize,
    window_resizable: bool,
    required_extension_names: []const [:0]const u8,
    validation_layers: []const [:0]const u8,
    allocator: std.mem.Allocator,
    icon_file: [:0]const u8,
}) !State {
    var current_state = create_state(.{
        .app_name = params.app_name,
        .initial_window_width = params.initial_window_width,
        .initial_window_height = params.initial_window_height,
        .window_resizable = params.window_resizable,
        .required_extension_names = params.required_extension_names,
        .validation_layers = params.validation_layers,
        .allocator = params.allocator,
        .icon_file = params.icon_file,
    });
    try create_instance(&current_state);
    try create_model(&current_state);
    try create_texture_image(&current_state);
    try create_depth_resources(&current_state);
    try create_descriptor(&current_state);
    try create_pipeline(&current_state);
    try create_command(&current_state);
    try create_swapchain(&current_state, null);
    return current_state;
}

pub fn loop(state: *State) !void {
    const draw_loop_thread = try std.Thread.spawn(.{}, draw_loop, .{state});
    state.loop.run_state = .Looping;
    vulkan.window.keep_open(.{ .window = state.*.instance.window });
    state.loop.run_state = .Deinitializing;
    draw_loop_thread.join();
    try vulkan.device.wait_idle(.{ .device = state.*.instance.device });
}

/// generally should be in reverse order of the setup.
pub fn cleanup(state: *State) void {
    destroy_swapchain(state, false);
    destroy_command(state);
    destroy_pipeline(state);
    destroy_descriptor(state);
    destroy_depth_resources(state);
    destroy_texture_image(state);
    destroy_model(state);
    destroy_instance(state);
}

// Loopers

fn draw_loop(state: *State) !void {
    state.*.loop.timer = try std.time.Timer.start();
    while (state.*.loop.run_state != .Deinitializing) {
        if (state.*.loop.run_state == .Looping) {
            draw_frame(state) catch |err| {
                std.log.err("draw loop error: {any}", .{err});
                continue;
            };
            state.*.loop.frame_index = @mod(state.*.loop.frame_index + 1, state.*.configs.max_frames);
        }

        switch (state.*.loop.run_state) {
            .Sleeping => {
                std.time.sleep(1000 * std.time.ns_per_ms);
                state.*.loop.run_state = .Looping;
            },
            .Resizing => {
                state.*.swapchain.extent = vulkan.swapchain.choose_extent(.{
                    .physical_device = state.*.instance.physical_device,
                    .surface = state.*.instance.surface,
                }) catch |err| {
                    std.log.err("error choosing extent during resize: {any}", .{err});
                    state.*.loop.run_state = .Looping;
                    continue;
                };
                if (state.*.swapchain.extent.width == 0 or state.*.swapchain.extent.height == 0) {
                    state.*.loop.run_state = .Sleeping;
                    continue;
                }

                vulkan.device.wait_idle(.{ .device = state.*.instance.device }) catch |err| {
                    std.log.err("error waiting for device during resize: {any}", .{err});
                    state.*.loop.run_state = .Looping;
                    continue;
                };
                const old_swapchain = state.*.swapchain.swapchain;
                destroy_swapchain(state, true);
                create_swapchain(state, old_swapchain) catch |err| {
                    std.log.err("error creating swapchain during resize: {any}", .{err});
                    state.*.loop.run_state = .Looping;
                    continue;
                };
                vulkan.swapchain.destroy(.{
                    .device = state.*.instance.device,
                    .swapchain = old_swapchain,
                });

                state.*.loop.run_state = .Looping;
            },
            else => {},
        }
    }
}

fn draw_frame(state: *State) !void {
    const command_buffer = state.*.command.buffers[state.*.loop.frame_index];
    const image_available_semaphore = state.*.command.image_available_semaphores[state.*.loop.frame_index];
    const render_finished_semaphore = state.*.command.render_finished_semaphores[state.*.loop.frame_index];
    const in_flight_fence = state.*.command.in_flight_fences[state.*.loop.frame_index];
    const descriptor_set = state.*.pipeline.descriptor_sets[state.*.loop.frame_index];

    try vulkan.sync.wait_for_fence(.{
        .device = state.*.instance.device,
        .fence = in_flight_fence,
    });

    const image_index = vulkan.swapchain.aquire_next_image_index(.{
        .device = state.*.instance.device,
        .swapchain = state.*.swapchain.swapchain,
        .image_available_semaphore = image_available_semaphore,
    }) catch |err| {
        switch (err) {
            error.OutOfDate => {
                state.*.loop.run_state = .Resizing;
                return;
            },
            else => return err,
        }
    };

    try vulkan.sync.reset_fence(.{
        .device = state.*.instance.device,
        .fence = in_flight_fence,
    });

    const frame_buffer = state.*.swapchain.frame_buffers[image_index];

    try vulkan.command.reset(.{ .command_buffer = command_buffer });
    try vulkan.command.record_indexed(.{
        .pipeline = state.*.pipeline.pipeline,
        .renderpass = state.*.pipeline.renderpass,
        .layout = state.*.pipeline.layout,
        .command_buffer = command_buffer,
        .frame_buffer = frame_buffer,
        .vertex_buffer = state.*.model.vertex_buffer,
        .index_buffer = state.*.model.index_buffer,
        .descriptor_set = descriptor_set,
        .n_index = @as(u32, @intCast(state.*.model.indices.len)),
        .extent = state.*.swapchain.extent,
    });

    try vulkan.uniform.update(.{
        .index = @as(u32, @intCast(state.*.loop.frame_index)),
        .map = state.*.model.uniform_buffer_map[state.*.loop.frame_index],
        .time = state.*.loop.timer.read(),
    });

    try vulkan.queue.submit(.{
        .graphics_queue = state.*.instance.graphics_queue,
        .command_buffer = command_buffer,
        .wait_semaphore = image_available_semaphore,
        .signal_semaphore = render_finished_semaphore,
        .fence = in_flight_fence,
    });
    vulkan.queue.present(.{
        .present_queue = state.*.instance.present_queue,
        .swapchain = state.*.swapchain.swapchain,
        .image_index = image_index,
        .render_finished_semaphore = render_finished_semaphore,
    }) catch |err| {
        switch (err) {
            error.OutOfDate => {
                state.*.loop.run_state = .Resizing;
                return;
            },
            else => {
                return error.VulkanQueueSubmitError;
            },
        }
    };
}

// Creators

fn create_instance(state: *State) !void {
    // create window
    state.*.instance.window = try vulkan.window.create(.{
        .app_name = state.*.configs.app_name,
        .width = state.*.configs.initial_window_width,
        .height = state.*.configs.initial_window_height,
        .resizable = state.*.configs.window_resizable,
    });

    // set icon
    if (state.*.configs.icon_file) |icon_file| {
        state.*.objects.icon = try image.bmp.parse_file(icon_file, state.*.configs.allocator);
        try vulkan.window.set_icon_from_image(.{
            .window = state.*.instance.window,
            .image = state.*.objects.icon.?,
        });
    }

    // create instance
    state.*.instance.window_extensions = try vulkan.window.get_required_extensions(.{ .allocator = state.*.configs.allocator });
    state.instance.instance = try vulkan.instance.create(.{
        .app_name = state.*.configs.app_name,
        .window_extensions = state.*.instance.window_extensions,
        .validation_layers = state.*.configs.validation_layers,
        .allocator = state.*.configs.allocator,
    });

    // create surface
    state.*.instance.surface = try vulkan.surface.create(.{
        .instance = state.*.instance.instance,
        .window = state.*.instance.window,
    });

    // choose suitable physical device
    const physical_device_list = try vulkan.physical_device.get_list(.{
        .instance = state.*.instance.instance,
        .allocator = state.*.configs.allocator,
    });
    state.*.instance.physical_device = try vulkan.physical_device.choose_suitable(.{
        .physical_device_list = physical_device_list,
        .surface = state.*.instance.surface,
        .required_extension_names = state.*.configs.required_extension_names,
        .allocator = state.*.configs.allocator,
    });
    state.*.configs.allocator.free(physical_device_list);
    state.*.instance.physical_device_properties = try vulkan.physical_device.get_properties(.{ .physical_device = state.*.instance.physical_device });
    std.debug.print("Using device: {s}\n", .{state.*.instance.physical_device_properties.deviceName});

    state.*.instance.queue_family_indices = try vulkan.queue_family.get_indices(.{
        .physical_device = state.*.instance.physical_device,
        .surface = state.*.instance.surface,
        .allocator = state.*.configs.allocator,
    });

    // create logical device
    state.*.instance.device = try vulkan.device.create(.{
        .physical_device = state.*.instance.physical_device,
        .queue_family_indices = state.*.instance.queue_family_indices,
        .extensions = state.*.configs.required_extension_names,
        .allocator = state.*.configs.allocator,
    });

    // create queues
    state.*.instance.graphics_queue = vulkan.queue.create(.{
        .device = state.*.instance.device,
        .family_index = state.*.instance.queue_family_indices.graphicsFamily.?,
    });
    state.*.instance.present_queue = vulkan.queue.create(.{
        .device = state.*.instance.device,
        .family_index = state.*.instance.queue_family_indices.presentFamily.?,
    });
    state.*.instance.transfer_queue = vulkan.queue.create(.{
        .device = state.*.instance.device,
        .family_index = state.*.instance.queue_family_indices.transferFamily.?,
    });

    // get surface allocator
    state.*.instance.surface_format = try vulkan.swapchain.choose_surface_format(.{
        .physical_device = state.*.instance.physical_device,
        .surface = state.*.instance.surface,
        .allocator = state.*.configs.allocator,
    });

    // create extent
    state.*.swapchain.extent = try vulkan.swapchain.choose_extent(.{
        .physical_device = state.*.instance.physical_device,
        .surface = state.*.instance.surface,
    });
}

fn create_model(state: *State) !void {
    state.*.model.vertices = &[_]Vertex{
        Vertex{
            .position = @Vector(3, f32){ -0.5, -0.5, 0.0 },
            .color = @Vector(3, f32){ 1.0, 0.0, 0.0 },
            .texCoord = @Vector(2, f32){ 1.0, 0.0 },
        },
        Vertex{
            .position = @Vector(3, f32){ 0.5, -0.5, 0.0 },
            .color = @Vector(3, f32){ 1.0, 1.0, 1.0 },
            .texCoord = @Vector(2, f32){ 0.0, 0.0 },
        },
        Vertex{
            .position = @Vector(3, f32){ 0.5, 0.5, 0.0 },
            .color = @Vector(3, f32){ 0.0, 0.0, 1.0 },
            .texCoord = @Vector(2, f32){ 0.0, 1.0 },
        },
        Vertex{
            .position = @Vector(3, f32){ -0.5, 0.5, 0.0 },
            .color = @Vector(3, f32){ 1.0, 0.0, 1.0 },
            .texCoord = @Vector(2, f32){ 1.0, 1.0 },
        },

        Vertex{
            .position = @Vector(3, f32){ -0.3, -0.3, 0.5 },
            .color = @Vector(3, f32){ 1.0, 0.0, 0.0 },
            .texCoord = @Vector(2, f32){ 1.0, 0.0 },
        },
        Vertex{
            .position = @Vector(3, f32){ 0.7, -0.3, 0.5 },
            .color = @Vector(3, f32){ 1.0, 1.0, 1.0 },
            .texCoord = @Vector(2, f32){ 0.0, 0.0 },
        },
        Vertex{
            .position = @Vector(3, f32){ 0.7, 0.7, 0.5 },
            .color = @Vector(3, f32){ 0.0, 0.0, 1.0 },
            .texCoord = @Vector(2, f32){ 0.0, 1.0 },
        },
        Vertex{
            .position = @Vector(3, f32){ -0.3, 0.7, 0.5 },
            .color = @Vector(3, f32){ 1.0, 0.0, 1.0 },
            .texCoord = @Vector(2, f32){ 1.0, 1.0 },
        },
    };

    state.*.model.indices = &[_]u32{ 0, 1, 2, 2, 3, 0, 4, 5, 6, 6, 7, 4 };

    // if graphics and transfer families are different, set sharing mode to concurrent
    var sharing_mode: vulkan.glfwc.VkSharingMode = vulkan.glfwc.VK_SHARING_MODE_EXCLUSIVE;
    if (state.*.instance.queue_family_indices.graphicsFamily.? != state.*.instance.queue_family_indices.transferFamily.?) {
        sharing_mode = vulkan.glfwc.VK_SHARING_MODE_CONCURRENT;
    }

    // create vertex buffer
    const vertex_buffer_object = try vulkan.buffer.create_and_allocate(.{
        .device = state.*.instance.device,
        .physical_device = state.*.instance.physical_device,
        .size = @sizeOf(Vertex) * state.*.model.vertices.len,
        .usage = vulkan.glfwc.VK_BUFFER_USAGE_TRANSFER_DST_BIT | vulkan.glfwc.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
        .sharing_mode = sharing_mode,
        .properties = vulkan.glfwc.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
    });
    state.*.model.vertex_buffer = vertex_buffer_object.buffer;
    state.*.model.vertex_buffer_memory = vertex_buffer_object.buffer_memory;
    try vulkan.stage.stage(Vertex, .{
        .device = state.*.instance.device,
        .physical_device = state.*.instance.physical_device,
        .queue_family_indices = state.*.instance.queue_family_indices,
        .graphics_queue = state.*.instance.graphics_queue,
        .data = state.*.model.vertices,
        .dst_buffer = state.*.model.vertex_buffer,
        .allocator = state.*.configs.allocator,
    });

    // create index buffer
    const index_buffer_object = try vulkan.buffer.create_and_allocate(.{
        .device = state.*.instance.device,
        .physical_device = state.*.instance.physical_device,
        .size = @sizeOf(u32) * state.*.model.indices.len,
        .usage = vulkan.glfwc.VK_BUFFER_USAGE_TRANSFER_DST_BIT | vulkan.glfwc.VK_BUFFER_USAGE_INDEX_BUFFER_BIT,
        .sharing_mode = sharing_mode,
        .properties = vulkan.glfwc.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
    });
    state.*.model.index_buffer = index_buffer_object.buffer;
    state.*.model.index_buffer_memory = index_buffer_object.buffer_memory;
    try vulkan.stage.stage(u32, .{
        .device = state.*.instance.device,
        .physical_device = state.*.instance.physical_device,
        .queue_family_indices = state.*.instance.queue_family_indices,
        .graphics_queue = state.*.instance.graphics_queue,
        .data = state.*.model.indices,
        .dst_buffer = state.*.model.index_buffer,
        .allocator = state.*.configs.allocator,
    });

    // create shader modules
    state.*.model.vert_shader_module = try vulkan.shader.create_module(.{
        .device = state.*.instance.device,
        .filepath = "shaders/shader.vert.spv",
        .allocator = state.*.configs.allocator,
    });
    state.*.model.frag_shader_module = try vulkan.shader.create_module(.{
        .device = state.*.instance.device,
        .filepath = "shaders/shader.frag.spv",
        .allocator = state.*.configs.allocator,
    });
}

fn create_texture_image(state: *State) !void {
    const texture_image = try image.bmp.parse_file("images/hoshino-ai.bmp", state.*.configs.allocator);

    var image_pixels = try std.ArrayList(u8).initCapacity(state.*.configs.allocator, 4 * texture_image.width * texture_image.height);
    for (texture_image.pixels) |pixel| {
        try image_pixels.append(pixel.red);
        try image_pixels.append(pixel.green);
        try image_pixels.append(pixel.blue);
        try image_pixels.append(255);
    }
    texture_image.deallocate(state.*.configs.allocator);

    const image_object = try vulkan.texture.create_and_allocate(.{
        .device = state.*.instance.device,
        .physical_device = state.*.instance.physical_device,
        .width = @as(u32, @intCast(texture_image.width)),
        .height = @as(u32, @intCast(texture_image.height)),
        .properties = vulkan.glfwc.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
    });
    state.*.swapchain.texture_image = image_object.image;
    state.*.swapchain.texture_image_memory = image_object.image_memory;

    try vulkan.stage.stage_image_transition(.{
        .device = state.*.instance.device,
        .physical_device = state.*.instance.physical_device,
        .queue_family_indices = state.*.instance.queue_family_indices,
        .graphics_queue = state.*.instance.graphics_queue,
        .image = image_object.image,
        .width = @as(u32, @intCast(texture_image.width)),
        .height = @as(u32, @intCast(texture_image.height)),
        .old_layout = vulkan.glfwc.VK_IMAGE_LAYOUT_UNDEFINED,
        .new_layout = vulkan.glfwc.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        .src_access_mask = 0,
        .dst_access_mask = vulkan.glfwc.VK_ACCESS_TRANSFER_WRITE_BIT,
        .src_stage_mask = vulkan.glfwc.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
        .dst_stage_mask = vulkan.glfwc.VK_PIPELINE_STAGE_TRANSFER_BIT,
        .allocator = state.*.configs.allocator,
    });
    try vulkan.stage.stage_image_copy(u8, .{
        .device = state.*.instance.device,
        .physical_device = state.*.instance.physical_device,
        .queue_family_indices = state.*.instance.queue_family_indices,
        .graphics_queue = state.*.instance.graphics_queue,
        .data = image_pixels.items,
        .image = image_object.image,
        .width = @as(u32, @intCast(texture_image.width)),
        .height = @as(u32, @intCast(texture_image.height)),
        .allocator = state.*.configs.allocator,
    });
    try vulkan.stage.stage_image_transition(.{
        .device = state.*.instance.device,
        .physical_device = state.*.instance.physical_device,
        .queue_family_indices = state.*.instance.queue_family_indices,
        .graphics_queue = state.*.instance.graphics_queue,
        .image = image_object.image,
        .width = @as(u32, @intCast(texture_image.width)),
        .height = @as(u32, @intCast(texture_image.height)),
        .old_layout = vulkan.glfwc.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        .new_layout = vulkan.glfwc.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        .src_access_mask = vulkan.glfwc.VK_ACCESS_TRANSFER_WRITE_BIT,
        .dst_access_mask = vulkan.glfwc.VK_ACCESS_SHADER_READ_BIT,
        .src_stage_mask = vulkan.glfwc.VK_PIPELINE_STAGE_TRANSFER_BIT,
        .dst_stage_mask = vulkan.glfwc.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
        .allocator = state.*.configs.allocator,
    });

    // create image view
    state.*.swapchain.texture_image_view = try vulkan.image_view.create(.{
        .device = state.*.instance.device,
        .image = image_object.image,
        .format = vulkan.glfwc.VK_FORMAT_R8G8B8A8_SRGB,
    });

    // create sampler
    state.*.swapchain.texture_sampler = try vulkan.sampler.create(.{
        .device = state.*.instance.device,
        .physical_device = state.*.instance.physical_device,
    });

    image_pixels.deinit();
}

fn create_depth_resources(state: *State) !void {
    state.*.swapchain.depth_format = try vulkan.physical_device.get_supported_format(.{
        .physical_device = state.*.instance.physical_device,
        .candidates = &[_]vulkan.glfwc.VkFormat{ vulkan.glfwc.VK_FORMAT_D32_SFLOAT, vulkan.glfwc.VK_FORMAT_D32_SFLOAT_S8_UINT, vulkan.glfwc.VK_FORMAT_D24_UNORM_S8_UINT },
        .tiling = vulkan.glfwc.VK_IMAGE_TILING_OPTIMAL,
        .features = vulkan.glfwc.VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT,
    });
    const depth_image_object = try vulkan.texture.create_and_allocate(.{
        .device = state.*.instance.device,
        .physical_device = state.*.instance.physical_device,
        .width = state.*.swapchain.extent.width,
        .height = state.*.swapchain.extent.height,
        .format = state.*.swapchain.depth_format,
        .tiling = vulkan.glfwc.VK_IMAGE_TILING_OPTIMAL,
        .usage = vulkan.glfwc.VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT,
        .sharing_mode = vulkan.glfwc.VK_SHARING_MODE_EXCLUSIVE,
        .properties = vulkan.glfwc.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
    });
    const depth_image_view = try vulkan.image_view.create(.{
        .device = state.*.instance.device,
        .image = depth_image_object.image,
        .format = state.*.swapchain.depth_format,
        .aspect_mask = vulkan.glfwc.VK_IMAGE_ASPECT_DEPTH_BIT,
    });
    var barrier_aspect_mask = vulkan.glfwc.VK_IMAGE_ASPECT_DEPTH_BIT;
    if (vulkan.depth.has_stencil(.{ .format = state.*.swapchain.depth_format })) {
        barrier_aspect_mask |= vulkan.glfwc.VK_IMAGE_ASPECT_STENCIL_BIT;
    }
    // try vulkan.stage.stage_image_transition(.{
    //     .device = state.*.instance.device,
    //     .physical_device = state.*.instance.physical_device,
    //     .queue_family_indices = state.*.instance.queue_family_indices,
    //     .graphics_queue = state.*.instance.graphics_queue,
    //     .image = depth_image_object.image,
    //     .width = state.*.swapchain.extent.width,
    //     .height = state.*.swapchain.extent.height,
    //     .old_layout = vulkan.glfwc.VK_IMAGE_LAYOUT_UNDEFINED,
    //     .new_layout = vulkan.glfwc.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
    //     .src_access_mask = 0,
    //     .dst_access_mask = vulkan.glfwc.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT | vulkan.glfwc.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
    //     .src_stage_mask = vulkan.glfwc.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
    //     .dst_stage_mask = vulkan.glfwc.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
    //     .aspect_mask = @intCast(barrier_aspect_mask),
    //     .allocator = state.*.configs.allocator,
    // });
    state.*.swapchain.depth_image = depth_image_object.image;
    state.*.swapchain.depth_image_view = depth_image_view;
    state.*.swapchain.depth_image_memory = depth_image_object.image_memory;
}

fn create_descriptor(state: *State) !void {
    // create uniform buffers
    var uniform_buffers = try std.ArrayList(vulkan.glfwc.VkBuffer).initCapacity(state.*.configs.allocator, state.*.configs.max_frames);
    var uniform_buffers_memory = try std.ArrayList(vulkan.glfwc.VkDeviceMemory).initCapacity(state.*.configs.allocator, state.*.configs.max_frames);
    var uniform_buffers_map = try std.ArrayList([*]UniformBufferObject).initCapacity(state.*.configs.allocator, state.*.configs.max_frames);
    defer uniform_buffers.deinit();
    defer uniform_buffers_memory.deinit();
    defer uniform_buffers_map.deinit();
    for (0..state.*.configs.max_frames) |_| {
        const ubo_object = try vulkan.buffer.create_and_allocate(.{
            .device = state.*.instance.device,
            .physical_device = state.*.instance.physical_device,
            .size = @sizeOf(UniformBufferObject) * state.*.model.vertices.len,
            .usage = vulkan.glfwc.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT,
            .sharing_mode = vulkan.glfwc.VK_SHARING_MODE_EXCLUSIVE,
            .properties = vulkan.glfwc.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vulkan.glfwc.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        });
        const ubo_map = try vulkan.memory.map_memory(UniformBufferObject, .{
            .device = state.*.instance.device,
            .buffer_create_info = ubo_object.buffer_create_info,
            .buffer_memory = ubo_object.buffer_memory,
            .memcpy = false,
        });
        try uniform_buffers.append(ubo_object.buffer);
        try uniform_buffers_memory.append(ubo_object.buffer_memory);
        try uniform_buffers_map.append(ubo_map);
    }
    state.*.model.uniform_buffer = try uniform_buffers.toOwnedSlice();
    state.*.model.uniform_buffer_memory = try uniform_buffers_memory.toOwnedSlice();
    state.*.model.uniform_buffer_map = try uniform_buffers_map.toOwnedSlice();

    // create descriptor set layout
    state.*.pipeline.descriptor_set_layout = try vulkan.descriptor_set.create_layout(.{ .device = state.*.instance.device });

    // create descriptor pool
    state.*.pipeline.descriptor_pool = try vulkan.descriptor_pool.create(.{
        .device = state.*.instance.device,
        .max_frames = @as(u32, @intCast(state.*.configs.max_frames)),
    });

    // create descriptor sets
    state.*.pipeline.descriptor_sets = try vulkan.descriptor_set.create(.{
        .device = state.*.instance.device,
        .descriptor_pool = state.*.pipeline.descriptor_pool,
        .descriptor_set_layout = state.*.pipeline.descriptor_set_layout,
        .max_frames = @as(u32, @intCast(state.*.configs.max_frames)),
        .allocator = state.*.configs.allocator,
    });

    for (0..state.*.configs.max_frames) |i| {
        try vulkan.descriptor_set.update(.{
            .device = state.*.instance.device,
            .buffer = state.*.model.uniform_buffer[i],
            .range = @sizeOf(UniformBufferObject),
            .texture_image_view = state.*.swapchain.texture_image_view,
            .texture_image_sampler = state.*.swapchain.texture_sampler,
            .descriptor_set = state.*.pipeline.descriptor_sets[i],
        });
    }
}

fn create_pipeline(state: *State) !void {
    // create layout
    state.*.pipeline.layout = try vulkan.layout.create(.{
        .device = state.*.instance.device,
        .descriptor_set_layout = state.*.pipeline.descriptor_set_layout,
    });

    // create renderpass
    state.*.pipeline.renderpass = try vulkan.renderpass.create(.{
        .device = state.instance.device,
        .surface_format = state.*.instance.surface_format,
        .depth_format = state.*.swapchain.depth_format,
    });

    // create pipeline
    const shader_stages = vulkan.shader.create_shader_stage_info(.{
        .vert_shader_module = state.*.model.vert_shader_module,
        .frag_shader_module = state.*.model.frag_shader_module,
    });
    state.*.pipeline.pipeline = try vulkan.pipeline.create(.{
        .device = state.*.instance.device,
        .shader_stages = shader_stages,
        .layout = state.*.pipeline.layout,
        .renderpass = state.*.pipeline.renderpass,
    });
}

fn create_command(state: *State) !void {
    // create command pool
    state.*.command.pool = try vulkan.command_pool.create(.{
        .device = state.*.instance.device,
        .queue_family_indices = state.*.instance.queue_family_indices,
    });

    // create command_buffers
    state.*.command.buffers = try vulkan.command_buffer.create(.{
        .device = state.*.instance.device,
        .command_pool = state.*.command.pool,
        .n_buffers = state.*.configs.max_frames,
        .allocator = state.*.configs.allocator,
    });

    // create image_available_semaphores
    state.*.command.image_available_semaphores = try vulkan.sync.create_semaphores(.{
        .device = state.*.instance.device,
        .n_semaphores = state.*.configs.max_frames,
        .allocator = state.*.configs.allocator,
    });

    // create render_finished_semaphores
    state.*.command.render_finished_semaphores = try vulkan.sync.create_semaphores(.{
        .device = state.*.instance.device,
        .n_semaphores = state.*.configs.max_frames,
        .allocator = state.*.configs.allocator,
    });

    // create in_flight_fences
    state.*.command.in_flight_fences = try vulkan.sync.create_fences(.{
        .device = state.*.instance.device,
        .n_fences = state.*.configs.max_frames,
        .allocator = state.*.configs.allocator,
    });
}

fn create_swapchain(state: *State, old_swapchain: vulkan.glfwc.VkSwapchainKHR) !void {
    // create swapchain
    state.*.swapchain.swapchain = try vulkan.swapchain.create(.{
        .device = state.*.instance.device,
        .physical_device = state.*.instance.physical_device,
        .surface = state.*.instance.surface,
        .surface_format = state.*.instance.surface_format,
        .extent = state.*.swapchain.extent,
        .allocator = state.*.configs.allocator,
        .old_swap_chain = old_swapchain,
    });

    // create images
    state.*.swapchain.images = try vulkan.image.get_swapchain_images(.{
        .device = state.*.instance.device,
        .swapchain = state.*.swapchain.swapchain,
        .allocator = state.*.configs.allocator,
    });

    // create image views
    state.*.swapchain.image_views = try vulkan.image_view.create_many(.{
        .device = state.*.instance.device,
        .images = state.*.swapchain.images,
        .format = state.*.instance.surface_format.format,
        .allocator = state.*.configs.allocator,
    });

    // create frame buffers
    state.*.swapchain.frame_buffers = try vulkan.frame_buffer.create(.{
        .device = state.*.instance.device,
        .image_views = state.*.swapchain.image_views,
        .depth_image_view = state.*.swapchain.depth_image_view,
        .renderpass = state.*.pipeline.renderpass,
        .extent = state.*.swapchain.extent,
        .allocator = state.*.configs.allocator,
    });
}

// Destroyers

fn destroy_instance(state: *State) void {
    vulkan.device.destroy(.{
        .device = state.*.instance.device,
    });

    vulkan.surface.destroy(.{
        .instance = state.*.instance.instance,
        .surface = state.*.instance.surface,
    });

    vulkan.instance.destroy(.{ .instance = state.*.instance.instance });
    state.*.configs.allocator.free(state.*.instance.window_extensions);

    if (state.*.configs.icon_file) |_| {
        state.*.objects.icon.?.deallocate(state.*.configs.allocator);
    }

    vulkan.window.destroy(.{
        .window = state.instance.window,
    });
}

fn destroy_model(state: *State) void {
    vulkan.shader.destroy_module(.{
        .device = state.*.instance.device,
        .module = state.*.model.frag_shader_module,
    });
    vulkan.shader.destroy_module(.{
        .device = state.*.instance.device,
        .module = state.*.model.vert_shader_module,
    });

    vulkan.buffer.destroy_and_deallocate(.{
        .device = state.*.instance.device,
        .buffer = state.*.model.index_buffer,
        .buffer_memory = state.*.model.index_buffer_memory,
    });

    vulkan.buffer.destroy_and_deallocate(.{
        .device = state.*.instance.device,
        .buffer = state.*.model.vertex_buffer,
        .buffer_memory = state.*.model.vertex_buffer_memory,
    });
}

fn destroy_texture_image(state: *State) void {
    vulkan.sampler.destroy(.{
        .device = state.*.instance.device,
        .sampler = state.*.swapchain.texture_sampler,
    });

    vulkan.image_view.destroy(.{
        .device = state.*.instance.device,
        .image_view = state.*.swapchain.texture_image_view,
    });

    vulkan.texture.destroy_and_deallocate(.{
        .device = state.*.instance.device,
        .image = state.*.swapchain.texture_image,
        .image_memory = state.*.swapchain.texture_image_memory,
    });
}

fn destroy_depth_resources(state: *State) void {
    vulkan.image_view.destroy(.{
        .device = state.*.instance.device,
        .image_view = state.*.swapchain.depth_image_view,
    });

    vulkan.texture.destroy_and_deallocate(.{
        .device = state.*.instance.device,
        .image = state.*.swapchain.depth_image,
        .image_memory = state.*.swapchain.depth_image_memory,
    });
}

fn destroy_descriptor(state: *State) void {
    vulkan.descriptor_set.destroy(.{
        .descriptor_sets = state.*.pipeline.descriptor_sets,
        .allocator = state.*.configs.allocator,
    });

    vulkan.descriptor_pool.destroy(.{
        .device = state.*.instance.device,
        .descriptor_pool = state.*.pipeline.descriptor_pool,
    });

    for (0..state.*.configs.max_frames) |i| {
        vulkan.buffer.destroy_and_deallocate(.{
            .device = state.*.instance.device,
            .buffer = state.*.model.uniform_buffer[i],
            .buffer_memory = state.*.model.uniform_buffer_memory[i],
        });
    }
    state.*.configs.allocator.free(state.*.model.uniform_buffer);
    state.*.configs.allocator.free(state.*.model.uniform_buffer_memory);
    state.*.configs.allocator.free(state.*.model.uniform_buffer_map);
}

fn destroy_pipeline(state: *State) void {
    vulkan.pipeline.destroy(.{
        .device = state.*.instance.device,
        .pipeline = state.*.pipeline.pipeline,
    });

    vulkan.renderpass.destroy(.{
        .device = state.*.instance.device,
        .renderpass = state.*.pipeline.renderpass,
    });

    vulkan.layout.destroy(.{
        .device = state.*.instance.device,
        .layout = state.*.pipeline.layout,
    });

    vulkan.descriptor_set.destroy_layout(.{
        .device = state.*.instance.device,
        .set_layout = state.*.pipeline.descriptor_set_layout,
    });
}

fn destroy_command(state: *State) void {
    vulkan.sync.destroy_fences(.{
        .device = state.*.instance.device,
        .fences = state.*.command.in_flight_fences,
        .allocator = state.*.configs.allocator,
    });
    vulkan.sync.destroy_semaphores(.{
        .device = state.*.instance.device,
        .semaphores = state.*.command.render_finished_semaphores,
        .allocator = state.*.configs.allocator,
    });
    vulkan.sync.destroy_semaphores(.{
        .device = state.*.instance.device,
        .semaphores = state.*.command.image_available_semaphores,
        .allocator = state.*.configs.allocator,
    });

    vulkan.command_buffer.destroy(.{
        .command_buffers = state.*.command.buffers,
        .allocator = state.*.configs.allocator,
    });

    vulkan.command_pool.destroy(.{
        .device = state.*.instance.device,
        .command_pool = state.*.command.pool,
    });
}

fn destroy_swapchain(state: *State, skip_swapchain: bool) void {
    vulkan.frame_buffer.destroy(.{
        .device = state.*.instance.device,
        .frame_buffers = state.*.swapchain.frame_buffers,
        .allocator = state.*.configs.allocator,
    });

    vulkan.image_view.destroy_many(.{
        .device = state.*.instance.device,
        .image_views = state.*.swapchain.image_views,
        .allocator = state.*.configs.allocator,
    });

    vulkan.image.destroy_many(.{
        .device = state.*.instance.device,
        .images = state.*.swapchain.images,
        .allocator = state.*.configs.allocator,
        .destroy_images = false,
    });

    if (!skip_swapchain) {
        vulkan.swapchain.destroy(.{
            .device = state.*.instance.device,
            .swapchain = state.*.swapchain.swapchain,
        });
    }
}

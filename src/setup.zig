const std = @import("std");
const visual = @import("./visual/main.zig");

pub fn graphics(app_name: [:0]const u8, allocator: std.mem.Allocator) !void {
    const game_window = try visual.window.create(app_name, 400, 300);
    defer visual.window.destroy(game_window);

    const game_window_extensions = try visual.extension.get_required(allocator);
    defer allocator.free(game_window_extensions);

    const game_instance = try visual.instance.create(app_name, game_window_extensions, allocator);
    defer visual.instance.destroy(game_instance);

    const game_surface = try visual.surface.create(game_instance, game_window);
    defer visual.surface.destroy(game_instance, game_surface);

    const physical_devices = try visual.device.get_physical_devices(game_instance, allocator);
    defer allocator.free(physical_devices);

    const required_extension_names = [_][:0]const u8{
        visual.glfwc.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
    };
    const chosen_physical_device = try visual.device.choose_suitable(physical_devices, game_surface, &required_extension_names, allocator);
    const chosen_physical_device_properties = try visual.device.get_physical_properties(chosen_physical_device);
    std.debug.print("Using device: {s}\n", .{chosen_physical_device_properties.deviceName});

    const queue_family_indices = try visual.queue.get_family_indices(chosen_physical_device, game_surface, allocator);

    const game_device = try visual.device.create(chosen_physical_device, queue_family_indices, &required_extension_names, allocator);
    defer visual.device.destroy(game_device);

    const graphics_queue = visual.queue.create(game_device, queue_family_indices.graphicsFamily.?);
    const present_queue = visual.queue.create(game_device, queue_family_indices.presentFamily.?);

    const surface_format = try visual.swapchain.choose_surface_format(chosen_physical_device, game_surface, allocator);

    const game_swapchain = try visual.swapchain.create(game_device, chosen_physical_device, game_surface, surface_format, allocator, null);
    defer visual.swapchain.destroy(game_device, game_swapchain);

    const images = try visual.image.create(game_device, game_swapchain, allocator);
    defer allocator.free(images);

    const image_views = try visual.image.create_views(game_device, images, surface_format, allocator);
    defer visual.image.destroy_views(game_device, image_views, allocator);

    const vert_shader_module = try visual.shader.create_module(game_device, "shaders/shader.vert.spv", allocator);
    const frag_shader_module = try visual.shader.create_module(game_device, "shaders/shader.frag.spv", allocator);
    defer visual.shader.destroy_module(game_device, vert_shader_module);
    defer visual.shader.destroy_module(game_device, frag_shader_module);

    const shader_stages = visual.shader.create_shader_stage_info(vert_shader_module, frag_shader_module);

    const layout = try visual.pipeline.create_layout(game_device);
    defer visual.pipeline.destroy_layout(game_device, layout);

    const render_pass = try visual.render.create_render_pass(game_device, surface_format);
    defer visual.render.destroy_render_pass(game_device, render_pass);

    const extent = try visual.swapchain.choose_extent(chosen_physical_device, game_surface);
    const graphics_pipeline = try visual.pipeline.create(game_device, shader_stages, layout, render_pass, extent);
    defer visual.pipeline.destroy(game_device, graphics_pipeline);

    const command_pool = try visual.command.create_pool(game_device, queue_family_indices);
    defer visual.command.destroy_pool(game_device, command_pool);

    const MAX_FRAMES_IN_FLIGHT: usize = 2;

    const command_buffers = try visual.command.create_buffers(game_device, command_pool, MAX_FRAMES_IN_FLIGHT, allocator);
    defer visual.command.destroy_buffers(command_buffers, allocator);

    const image_available_semaphores = try visual.sync.create_semaphores(game_device, MAX_FRAMES_IN_FLIGHT, allocator);
    defer visual.sync.destroy_semaphores(game_device, image_available_semaphores, allocator);

    const render_finished_semaphores = try visual.sync.create_semaphores(game_device, MAX_FRAMES_IN_FLIGHT, allocator);
    defer visual.sync.destroy_semaphores(game_device, render_finished_semaphores, allocator);

    const in_flight_fences = try visual.sync.create_fences(game_device, MAX_FRAMES_IN_FLIGHT, allocator);
    defer visual.sync.destroy_fences(game_device, in_flight_fences, allocator);

    const frame_buffers = try visual.swapchain.create_frame_buffers(game_device, image_views, render_pass, extent, allocator);
    defer visual.swapchain.destroy_frame_buffers(game_device, frame_buffers, allocator);

    var current_frame: usize = 0;
    while (visual.glfwc.glfwWindowShouldClose(game_window) == 0) {
        _ = visual.glfwc.glfwPollEvents();
        try draw_frame(
            game_device,
            graphics_pipeline,
            render_pass,
            frame_buffers,
            graphics_queue,
            present_queue,
            game_swapchain,
            command_buffers[current_frame],
            extent,
            in_flight_fences[current_frame],
            image_available_semaphores[current_frame],
            render_finished_semaphores[current_frame],
        );

        current_frame = @mod(current_frame + 1, MAX_FRAMES_IN_FLIGHT);
    }

    if (visual.glfwc.vkDeviceWaitIdle(game_device) != visual.glfwc.VK_SUCCESS) {
        return error.VulkanDeviceWaitIdleError;
    }
}

fn draw_frame(
    device: visual.glfwc.VkDevice,
    graphics_pipeline: visual.glfwc.VkPipeline,
    render_pass: visual.glfwc.VkRenderPass,
    frame_buffers: []visual.glfwc.VkFramebuffer,
    graphics_queue: visual.glfwc.VkQueue,
    present_queue: visual.glfwc.VkQueue,
    game_swapchain: visual.glfwc.VkSwapchainKHR,
    command_buffer: visual.glfwc.VkCommandBuffer,
    extent: visual.glfwc.VkExtent2D,
    in_flight_fence: visual.glfwc.VkFence,
    image_available_semaphore: visual.glfwc.VkSemaphore,
    render_finished_semaphore: visual.glfwc.VkSemaphore,
) !void {
    const timeout = std.math.maxInt(u64);

    _ = visual.glfwc.vkWaitForFences(device, 1, &in_flight_fence, visual.glfwc.VK_TRUE, timeout);
    _ = visual.glfwc.vkResetFences(device, 1, &in_flight_fence);

    var image_index: u32 = undefined;
    _ = visual.glfwc.vkAcquireNextImageKHR(device, game_swapchain, timeout, image_available_semaphore, @ptrCast(visual.glfwc.VK_NULL_HANDLE), &image_index);

    try visual.command.reset(command_buffer);
    try visual.command.record_buffer(command_buffer, graphics_pipeline, render_pass, frame_buffers[image_index], extent);

    try visual.queue.submit(graphics_queue, command_buffer, image_available_semaphore, render_finished_semaphore, in_flight_fence);
    try visual.queue.present(present_queue, game_swapchain, image_index, render_finished_semaphore);
}

fn refresh_callback(game_window: ?*visual.glfwc.GLFWwindow) callconv(.C) void {
    var width2: u32 = undefined;
    var height2: u32 = undefined;
    visual.glfwc.glfwGetFramebufferSize(game_window, @ptrCast(&width2), @ptrCast(&height2));
    std.debug.print("refreshed: {any}x{any}\n", .{ width2, height2 });
}

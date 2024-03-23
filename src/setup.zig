const std = @import("std");
const visual = @import("./visual/main.zig");

pub fn graphics(app_name: [:0]const u8, allocator: std.mem.Allocator) !void {
    var state = visual.state.create(app_name, 400, 300, "images/icon.bmp", allocator);

    state.objects.window = try visual.vulkan.window.create(state.configs.app_name, state.configs.initial_window_width, state.configs.initial_window_height);
    defer visual.vulkan.window.destroy(state.objects.window);

    if (state.configs.icon_file) |icon_file| {
        state.objects.icon = try visual.icon.parse_icon(icon_file, state.configs.allocator);
        visual.vulkan.window.set_icon(state.objects.window, state.objects.icon.?.width, state.objects.icon.?.height, state.objects.icon.?.pixels);
        defer state.configs.allocator.free(state.objects.icon.?.pixels);
    }

    state.objects.window_extensions = try visual.vulkan.extension.get_required(state.configs.allocator);
    defer state.configs.allocator.free(state.objects.window_extensions);

    state.objects.instance = try visual.vulkan.instance.create(app_name, state.objects.window_extensions, state.configs.allocator);
    defer visual.vulkan.instance.destroy(state.objects.instance);

    state.objects.surface = try visual.vulkan.surface.create(state.objects.instance, state.objects.window);
    defer visual.vulkan.surface.destroy(state.objects.instance, state.objects.surface);

    const required_extension_names = [_][:0]const u8{
        visual.vulkan.glfwc.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
    };
    const physical_devices = try visual.vulkan.device.get_physical_devices(state.objects.instance, state.configs.allocator);
    defer state.configs.allocator.free(physical_devices);

    state.objects.physical_device = try visual.vulkan.device.choose_suitable(physical_devices, state.objects.surface, &required_extension_names, state.configs.allocator);
    state.objects.physical_device_properties = try visual.vulkan.device.get_physical_properties(state.objects.physical_device);
    std.debug.print("Using device: {s}\n", .{state.objects.physical_device_properties.deviceName});

    state.objects.queue_family_indices = try visual.vulkan.queue.get_family_indices(state.objects.physical_device, state.objects.surface, state.configs.allocator);

    state.objects.device = try visual.vulkan.device.create(state.objects.physical_device, state.objects.queue_family_indices, &required_extension_names, state.configs.allocator);
    defer visual.vulkan.device.destroy(state.objects.device);

    state.objects.graphics_queue = visual.vulkan.queue.create(state.objects.device, state.objects.queue_family_indices.graphicsFamily.?);
    state.objects.present_queue = visual.vulkan.queue.create(state.objects.device, state.objects.queue_family_indices.presentFamily.?);

    state.objects.surface_format = try visual.vulkan.swapchain.choose_surface_format(state.objects.physical_device, state.objects.surface, state.configs.allocator);

    const vert_shader_module = try visual.vulkan.shader.create_module(state.objects.device, "shaders/shader.vert.spv", state.configs.allocator);
    const frag_shader_module = try visual.vulkan.shader.create_module(state.objects.device, "shaders/shader.frag.spv", state.configs.allocator);
    defer visual.vulkan.shader.destroy_module(state.objects.device, vert_shader_module);
    defer visual.vulkan.shader.destroy_module(state.objects.device, frag_shader_module);

    const shader_stages = visual.vulkan.shader.create_shader_stage_info(vert_shader_module, frag_shader_module);

    state.objects.layout = try visual.vulkan.pipeline.create_layout(state.objects.device);
    defer visual.vulkan.pipeline.destroy_layout(state.objects.device, state.objects.layout);

    state.objects.render_pass = try visual.vulkan.render.create_render_pass(state.objects.device, state.objects.surface_format);
    defer visual.vulkan.render.destroy_render_pass(state.objects.device, state.objects.render_pass);

    state.frames.extent = try visual.vulkan.swapchain.choose_extent(state.objects.physical_device, state.objects.surface);
    state.objects.pipeline = try visual.vulkan.pipeline.create(state.objects.device, shader_stages, state.objects.layout, state.objects.render_pass, state.frames.extent);
    defer visual.vulkan.pipeline.destroy(state.objects.device, state.objects.pipeline);

    state.frames.command_pool = try visual.vulkan.command.create_pool(state.objects.device, state.objects.queue_family_indices);
    defer visual.vulkan.command.destroy_pool(state.objects.device, state.frames.command_pool);

    state.frames.command_buffers = try visual.vulkan.command.create_buffers(state.objects.device, state.frames.command_pool, state.configs.max_frames, state.configs.allocator);
    defer visual.vulkan.command.destroy_buffers(state.frames.command_buffers, state.configs.allocator);

    state.frames.image_available_semaphores = try visual.vulkan.sync.create_semaphores(state.objects.device, state.configs.max_frames, state.configs.allocator);
    defer visual.vulkan.sync.destroy_semaphores(state.objects.device, state.frames.image_available_semaphores, state.configs.allocator);

    state.frames.render_finished_semaphores = try visual.vulkan.sync.create_semaphores(state.objects.device, state.configs.max_frames, state.configs.allocator);
    defer visual.vulkan.sync.destroy_semaphores(state.objects.device, state.frames.render_finished_semaphores, state.configs.allocator);

    state.frames.in_flight_fences = try visual.vulkan.sync.create_fences(state.objects.device, state.configs.max_frames, state.configs.allocator);
    defer visual.vulkan.sync.destroy_fences(state.objects.device, state.frames.in_flight_fences, state.configs.allocator);

    state.frames.swapchain = try visual.vulkan.swapchain.create(state.objects.device, state.objects.physical_device, state.objects.surface, state.objects.surface_format, state.configs.allocator, null);
    defer visual.vulkan.swapchain.destroy(state.objects.device, state.frames.swapchain);

    state.frames.images = try visual.vulkan.image.create(state.objects.device, state.frames.swapchain, state.configs.allocator);
    defer allocator.free(state.frames.images);

    state.frames.image_views = try visual.vulkan.image.create_views(state.objects.device, state.frames.images, state.objects.surface_format, state.configs.allocator);
    defer visual.vulkan.image.destroy_views(state.objects.device, state.frames.image_views, state.configs.allocator);

    state.frames.frame_buffers = try visual.vulkan.swapchain.create_frame_buffers(state.objects.device, state.frames.image_views, state.objects.render_pass, state.frames.extent, state.configs.allocator);
    defer visual.vulkan.swapchain.destroy_frame_buffers(state.objects.device, state.frames.frame_buffers, state.configs.allocator);

    const draw_loop_thread = try std.Thread.spawn(.{}, draw_loop, .{&state});
    state.run_state = .Looping;
    visual.vulkan.window.keep_open(state.objects.window, null);
    state.run_state = .Deinitializing;
    draw_loop_thread.join();
    if (visual.vulkan.glfwc.vkDeviceWaitIdle(state.objects.device) != visual.vulkan.glfwc.VK_SUCCESS) {
        return error.VulkanDeviceWaitIdleError;
    }
}

fn draw_loop(state: *visual.state.State) !void {
    // possibly need to handle error
    while (state.*.run_state != .Deinitializing) {
        if (state.*.run_state != .Looping) continue;
        try visual.vulkan.render.draw_frame(state);
        state.*.frames.frame_index = @mod(state.*.frames.frame_index + 1, state.*.configs.max_frames);
    }
}

fn refresh_callback(game_window: ?*visual.vulkan.glfwc.GLFWwindow) callconv(.C) void {
    var width2: u32 = undefined;
    var height2: u32 = undefined;
    visual.vulkan.glfwc.glfwGetFramebufferSize(game_window, @ptrCast(&width2), @ptrCast(&height2));
    std.debug.print("refreshed: {any}x{any}\n", .{ width2, height2 });
}

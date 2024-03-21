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

    const game_device = try visual.device.create(chosen_physical_device, game_surface, &required_extension_names, allocator);
    defer visual.device.destroy(game_device);

    const graphics_queue_handler = visual.queue.create(game_device, queue_family_indices.graphicsFamily.?);
    const present_queue_handler = visual.queue.create(game_device, queue_family_indices.presentFamily.?);
    _ = graphics_queue_handler;
    _ = present_queue_handler;

    const surface_format = try visual.swapchain.choose_surface_format(chosen_physical_device, game_surface, allocator);

    const game_swapchain = try visual.swapchain.create(game_device, chosen_physical_device, game_surface, surface_format, allocator, null);
    defer visual.swapchain.destroy(game_device, game_swapchain);

    const images = try visual.image.create(game_device, game_swapchain, allocator);
    defer allocator.free(images);

    const image_views = try visual.image.create_views(game_device, images, surface_format, allocator);
    defer visual.image.destroy_views(game_device, image_views, allocator);

    visual.window.keep_open(game_window, refresh_callback);
}

fn refresh_callback(game_window: ?*visual.glfwc.GLFWwindow) callconv(.C) void {
    var width2: u32 = undefined;
    var height2: u32 = undefined;
    visual.glfwc.glfwGetFramebufferSize(game_window, @ptrCast(&width2), @ptrCast(&height2));
    std.debug.print("refreshed: {any}x{any}\n", .{ width2, height2 });
}

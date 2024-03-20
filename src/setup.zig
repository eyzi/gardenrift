const std = @import("std");
const visual = @import("./visual/main.zig");

pub fn graphics(app_name: [:0]const u8, allocator: std.mem.Allocator) !void {
    const game_window = try visual.window.init(app_name, 400, 300);
    defer visual.window.deinit(game_window);

    const game_window_extensions = try visual.extension.get_required(allocator);
    defer allocator.free(game_window_extensions);

    const game_instance = try visual.instance.create(app_name, game_window_extensions);
    defer visual.instance.destroy(game_instance);

    const game_surface = try visual.surface.create(game_instance, game_window);
    defer visual.surface.destroy(game_instance, game_surface);

    const physical_devices = try visual.device.get_physical_devices(game_instance, allocator);
    defer allocator.free(physical_devices);
    const chosen_physical_device = try visual.device.choose_suitable(physical_devices, game_surface, allocator);
    const chosen_physical_device_properties = try visual.device.get_physical_properties(chosen_physical_device);
    std.debug.print("Using device: {s}\n", .{chosen_physical_device_properties.deviceName});

    const game_device = try visual.device.create(chosen_physical_device, game_surface, allocator);
    defer visual.device.destroy(game_device);

    visual.window.keep_open(game_window, refresh_callback);
}

fn refresh_callback(game_window: ?*visual.glfwc.GLFWwindow) callconv(.C) void {
    _ = game_window;
    std.debug.print("window refreshed!\n", .{});
}

const std = @import("std");
const visual_manager = @import("./visual/manager.zig");

pub fn main() !void {
    const app_name = "Gardenrift";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    std.debug.print("\r===== {s} =====                           \n", .{app_name});

    var visual_state = try visual_manager.setup(.{
        .app_name = app_name,
        .initial_window_width = 400,
        .initial_window_height = 300,
        .window_resizable = false,
        .icon_file = "images/icon.bmp",
        .required_extension_names = &[_][:0]const u8{
            "VK_KHR_swapchain",
        },
        .validation_layers = &[_][:0]const u8{
            "VK_LAYER_KHRONOS_validation",
        },
        .allocator = gpa.allocator(),
    });
    defer visual_manager.cleanup(&visual_state);

    try visual_manager.loop(&visual_state);
}

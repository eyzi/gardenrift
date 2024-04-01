const std = @import("std");
const graphics_manager = @import("./graphics/manager.zig");
const acoustics_manager = @import("./acoustics/manager.zig");
const sound = @import("./library/sound/_.zig");

pub fn main() !void {
    const app_name = "Gardenrift";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    std.debug.print("\r===== {s} =====                           \n", .{app_name});

    try acoustics_manager.setup(.{
        .allocator = gpa.allocator(),
    });

    // var graphics_state = try graphics_manager.setup(.{
    //     .app_name = app_name,
    //     .initial_window_width = 720,
    //     .initial_window_height = 720,
    //     .window_resizable = false,
    //     .window_decorated = true,
    //     .window_transparent = true,
    //     .icon_file = "images/icon.bmp",
    //     .required_extension_names = &[_][:0]const u8{
    //         "VK_KHR_swapchain",
    //     },
    //     .validation_layers = &[_][:0]const u8{
    //         "VK_LAYER_KHRONOS_validation",
    //     },
    //     .model_obj = "models/viking_room.obj",
    //     .model_texture = "textures/viking_room.bmp",
    //     .allocator = gpa.allocator(),
    // });
    // defer graphics_manager.cleanup(&graphics_state);
    // try graphics_manager.loop(&graphics_state);
}

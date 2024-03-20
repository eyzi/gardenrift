const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;

pub fn get_required(allocator: std.mem.Allocator) ![][*:0]const u8 {
    var n_extensions: u32 = undefined;
    const required_extensions_raw = glfwc.glfwGetRequiredInstanceExtensions(&n_extensions);
    const required_extensions: [][*:0]const u8 = @as([*][*:0]const u8, @ptrCast(required_extensions_raw))[0..n_extensions];

    var instance_extensions = try std.ArrayList([*:0]const u8).initCapacity(allocator, n_extensions + 1);
    defer instance_extensions.deinit();

    try instance_extensions.appendSlice(required_extensions);
    return instance_extensions.toOwnedSlice();
}

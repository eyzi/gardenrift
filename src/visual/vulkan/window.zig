const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;
const state = @import("../state.zig");
const RgbaImage = @import("../../library/image/types.zig").RgbaImage;

pub fn keep_open(window: *glfwc.GLFWwindow, refresh_callback: ?glfwc.GLFWwindowrefreshfun) void {
    if (refresh_callback) |valid_refresh_callback| {
        _ = glfwc.glfwSetWindowRefreshCallback(window, valid_refresh_callback);
    }

    while (glfwc.glfwWindowShouldClose(window) == 0) {
        _ = glfwc.glfwPollEvents();
    }
}

/// returns window. needs to be destroyed.
pub fn create(app_name: [:0]const u8, width: usize, height: usize) !*glfwc.GLFWwindow {
    _ = glfwc.glfwInit();
    glfwc.glfwWindowHint(glfwc.GLFW_CLIENT_API, glfwc.GLFW_NO_API);
    glfwc.glfwWindowHint(glfwc.GLFW_RESIZABLE, glfwc.GLFW_TRUE);
    // glfwc.glfwWindowHint(glfwc.GLFW_DECORATED, glfwc.GLFW_FALSE);
    const window = glfwc.glfwCreateWindow(@intCast(width), @intCast(height), app_name.ptr, null, null) orelse return error.CouldNotCreateWindow;

    return window;
}

pub fn destroy(window: *glfwc.GLFWwindow) void {
    glfwc.glfwDestroyWindow(window);
    glfwc.glfwTerminate();
}

pub fn set_icon(window: *glfwc.GLFWwindow, width: usize, height: usize, pixels: []u32) void {
    glfwc.glfwSetWindowIcon(window, 1, &glfwc.GLFWimage{
        .width = @intCast(width),
        .height = @intCast(height),
        .pixels = @ptrCast(pixels),
    });
}

pub fn set_rgba_image_icon(window: *glfwc.GLFWwindow, image: RgbaImage) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var pixels = try gpa.allocator().alloc(u32, image.pixels.len);
    defer gpa.allocator().free(pixels);

    for (image.pixels, 0..) |pixel, i| {
        const a: u32 = @as(u32, @intCast(pixel.alpha)) << 24;
        _ = a; // assuming that full white is transparent since alpha isnt working
        const b: u32 = @as(u32, @intCast(pixel.blue)) << 16;
        const g: u32 = @as(u32, @intCast(pixel.green)) << 8;
        const r: u32 = @as(u32, @intCast(pixel.red));

        if (pixel.red == 255 and pixel.green == 255 and pixel.blue == 255) {
            pixels[i] = 0;
        } else {
            pixels[i] = r | g | b | (255 << 24);
        }
    }

    glfwc.glfwSetWindowIcon(window, 1, &glfwc.GLFWimage{
        .width = @intCast(image.width),
        .height = @intCast(image.height),
        .pixels = @ptrCast(pixels.ptr),
    });
}

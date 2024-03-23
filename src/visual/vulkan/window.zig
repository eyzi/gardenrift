const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;
const state = @import("../state.zig");

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

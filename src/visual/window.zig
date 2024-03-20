const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;

var icon_pixels = [_]u32{
    0b11111111111111111111111111111111,
    0b11111111000000000000000011111111,
    0b11111111000000000000000011111111,
    0b11111111000000000000000011111111,
    0b11111111111111111111111111111111,
    0b11111111000000000000000011111111,
    0b11111111111111111111111111111111,
    0b11111111111111111111111111111111,
    0b11111111111111111111111111111111,
    0b11111111111111111111111111111111,
    0b11111111000000000000000011111111,
    0b11111111111111111111111111111111,
    0b11111111111111111111111111111111,
    0b11111111000000000000000011111111,
    0b11111111000000000000000011111111,
    0b11111111000000000000000011111111,
    0b11111111111111111111111111111111,
    0b11111111111111111111111111111111,
    0b11111111111111111111111111111111,
    0b11111111000000000000000011111111,
    0b11111111111111111111111111111111,
    0b11111111000000000000000011111111,
    0b11111111000000000000000011111111,
    0b11111111000000000000000011111111,
    0b11111111111111111111111111111111,
};

pub fn keep_open(window: *glfwc.GLFWwindow, refresh_callback: ?glfwc.GLFWwindowrefreshfun) void {
    if (refresh_callback) |valid_refresh_callback| {
        _ = glfwc.glfwSetWindowRefreshCallback(window, valid_refresh_callback);
    }

    while (glfwc.glfwWindowShouldClose(window) == 0) {
        _ = glfwc.glfwPollEvents();
    }
}

pub fn init(app_name: [:0]const u8, width: u16, height: u16) !*glfwc.GLFWwindow {
    _ = glfwc.glfwInit();
    glfwc.glfwWindowHint(glfwc.GLFW_CLIENT_API, glfwc.GLFW_NO_API);
    glfwc.glfwWindowHint(glfwc.GLFW_RESIZABLE, glfwc.GLFW_TRUE);
    const window = glfwc.glfwCreateWindow(width, height, app_name.ptr, null, null) orelse return error.CouldNotCreateWindow;

    glfwc.glfwSetWindowIcon(window, 1, &glfwc.GLFWimage{
        .width = 5,
        .height = 5,
        .pixels = @ptrCast(&icon_pixels),
    });

    return window;
}

pub fn deinit(window: *glfwc.GLFWwindow) void {
    glfwc.glfwDestroyWindow(window);
    glfwc.glfwTerminate();
}

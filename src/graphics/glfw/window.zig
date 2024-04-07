const std = @import("std");
const EmberImage = @import("ember").types.EmberImage;
const glfwc = @import("./glfw-c.zig").c;

pub fn create(params: struct {
    app_name: [:0]const u8,
    width: usize,
    height: usize,
    resizable: bool = true,
    decorated: bool = true,
    transparent: bool = false,
    mouse_passthrough: bool = false,
    floating: bool = false,
}) !*glfwc.GLFWwindow {
    glfwc.glfwWindowHint(glfwc.GLFW_CLIENT_API, glfwc.GLFW_NO_API);
    glfwc.glfwWindowHint(glfwc.GLFW_RESIZABLE, if (params.resizable) glfwc.GLFW_TRUE else glfwc.GLFW_FALSE);
    glfwc.glfwWindowHint(glfwc.GLFW_DECORATED, if (params.decorated) glfwc.GLFW_TRUE else glfwc.GLFW_FALSE);
    glfwc.glfwWindowHint(glfwc.GLFW_TRANSPARENT_FRAMEBUFFER, if (params.transparent) glfwc.GLFW_TRUE else glfwc.GLFW_FALSE);
    glfwc.glfwWindowHint(glfwc.GLFW_MOUSE_PASSTHROUGH, if (params.mouse_passthrough) glfwc.GLFW_TRUE else glfwc.GLFW_FALSE);
    glfwc.glfwWindowHint(glfwc.GLFW_FLOATING, if (params.floating) glfwc.GLFW_TRUE else glfwc.GLFW_FALSE);
    return glfwc.glfwCreateWindow(@intCast(params.width), @intCast(params.height), params.app_name.ptr, null, null) orelse return error.CouldNotCreateWindow;
}

pub fn destroy(params: struct {
    window: *glfwc.GLFWwindow,
}) void {
    glfwc.glfwDestroyWindow(params.window);
}

pub fn keep_open(params: struct {
    window: *glfwc.GLFWwindow,
    refresh_callback: ?glfwc.GLFWwindowrefreshfun = null,
}) void {
    if (params.refresh_callback) |valid_refresh_callback| {
        _ = glfwc.glfwSetWindowRefreshCallback(params.window, valid_refresh_callback);
    }

    while (glfwc.glfwWindowShouldClose(params.window) == 0) {
        _ = glfwc.glfwPollEvents();
    }
}

pub fn set_icon(params: struct {
    window: *glfwc.GLFWwindow,
    image: *const glfwc.GLFWimage,
}) void {
    glfwc.glfwSetWindowIcon(params.window, 1, params.image);
}

pub fn set_icon_from_ember_image(params: struct {
    window: *glfwc.GLFWwindow,
    image: EmberImage,
}) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var pixels = try gpa.allocator().alloc(u32, params.image.pixels.len);
    defer gpa.allocator().free(pixels);

    for (params.image.pixels, 0..) |pixel, i| {
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

    set_icon(.{
        .window = params.window,
        .image = &glfwc.GLFWimage{
            .width = @intCast(params.image.width),
            .height = @intCast(params.image.height),
            .pixels = @ptrCast(pixels.ptr),
        },
    });
}

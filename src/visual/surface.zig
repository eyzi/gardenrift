const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;

pub fn create(instance: glfwc.VkInstance, window: *glfwc.GLFWwindow) !glfwc.VkSurfaceKHR {
    var surface: glfwc.VkSurfaceKHR = undefined;
    if (glfwc.glfwCreateWindowSurface(instance, window, null, &surface) != glfwc.VK_SUCCESS) {
        return error.VulkanSurfaceCreateError;
    }
    return surface;
}

pub fn destroy(instance: glfwc.VkInstance, surface: glfwc.VkSurfaceKHR) void {
    glfwc.vkDestroySurfaceKHR(instance, surface, null);
}

const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;

pub fn create(app_name: [:0]const u8, extensions: [][*:0]const u8) !glfwc.VkInstance {
    const app_info = glfwc.VkApplicationInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .pApplicationName = app_name.ptr,
        .applicationVersion = glfwc.VK_MAKE_VERSION(0, 0, 0),
        .pEngineName = app_name.ptr,
        .engineVersion = glfwc.VK_MAKE_VERSION(0, 0, 0),
        .apiVersion = glfwc.VK_MAKE_VERSION(1, 3, 280),
        .pNext = null,
    };

    const instance_create_info = glfwc.VkInstanceCreateInfo{
        .sType = glfwc.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &app_info,
        .enabledExtensionCount = @intCast(extensions.len),
        .ppEnabledExtensionNames = extensions.ptr,
        .enabledLayerCount = 0,
        .ppEnabledLayerNames = null,
        .pNext = null,
        .flags = 0,
    };

    var instance: glfwc.VkInstance = undefined;
    if (glfwc.vkCreateInstance(&instance_create_info, null, &instance) != glfwc.VK_SUCCESS) {
        return error.VulkanInsanceCreateError;
    }

    return instance;
}

pub fn destroy(instance: glfwc.VkInstance) void {
    glfwc.vkDestroyInstance(instance, null);
}

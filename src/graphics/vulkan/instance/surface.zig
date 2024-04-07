const std = @import("std");
const glfwc = @import("../../glfw/glfw-c.zig").c;
const vkc = @import("../vk-c.zig").c;

/// returns surface. needs to be destroyed.
pub fn create(params: struct {
    instance: vkc.VkInstance,
    window: *glfwc.GLFWwindow,
}) !vkc.VkSurfaceKHR {
    var surface: vkc.VkSurfaceKHR = undefined;
    if (glfwc.glfwCreateWindowSurface(@ptrCast(params.instance), params.window, null, @ptrCast(&surface)) != vkc.VK_SUCCESS) {
        return error.VulkanSurfaceCreateError;
    }
    return surface;
}

pub fn destroy(params: struct {
    instance: vkc.VkInstance,
    surface: vkc.VkSurfaceKHR,
}) void {
    vkc.vkDestroySurfaceKHR(params.instance, params.surface, null);
}

pub fn get_capabilities(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    surface: vkc.VkSurfaceKHR,
}) !vkc.VkSurfaceCapabilitiesKHR {
    var capabilities: vkc.VkSurfaceCapabilitiesKHR = undefined;
    if (vkc.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(params.physical_device, params.surface, &capabilities) != vkc.VK_SUCCESS) {
        return error.VulkanSurfaceCapabilitiesError;
    }
    return capabilities;
}

pub fn get_n_formats(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    surface: vkc.VkSurfaceKHR,
}) u32 {
    var n_formats: u32 = 0;
    if (vkc.vkGetPhysicalDeviceSurfaceFormatsKHR(params.physical_device, params.surface, &n_formats, null) != vkc.VK_SUCCESS) {
        return 0;
    }
    return n_formats;
}

/// returns surface formats. needs to be deallocated.
pub fn get_formats(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    surface: vkc.VkSurfaceKHR,
    allocator: std.mem.Allocator,
}) ![]vkc.VkSurfaceFormatKHR {
    var n_formats = get_n_formats(.{
        .physical_device = params.physical_device,
        .surface = params.surface,
    });
    var formats = try params.allocator.alloc(vkc.VkSurfaceFormatKHR, n_formats);
    if (vkc.vkGetPhysicalDeviceSurfaceFormatsKHR(params.physical_device, params.surface, &n_formats, formats.ptr) != vkc.VK_SUCCESS) {
        return error.VulkanSurfaceFormatsError;
    }
    return formats;
}

pub fn get_n_present_modes(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    surface: vkc.VkSurfaceKHR,
}) u32 {
    var n_present_modes: u32 = 0;
    if (vkc.vkGetPhysicalDeviceSurfacePresentModesKHR(params.physical_device, params.surface, &n_present_modes, null) != vkc.VK_SUCCESS) {
        return 0;
    }
    return n_present_modes;
}

/// returns surface present modes. needs to be deallocated.
pub fn get_present_modes(params: struct {
    physical_device: vkc.VkPhysicalDevice,
    surface: vkc.VkSurfaceKHR,
    allocator: std.mem.Allocator,
}) ![]vkc.VkPresentModeKHR {
    var n_present_modes = get_n_present_modes(.{
        .physical_device = params.physical_device,
        .surface = params.surface,
    });
    var present_modes = try params.allocator.alloc(vkc.VkPresentModeKHR, n_present_modes);
    if (vkc.vkGetPhysicalDeviceSurfacePresentModesKHR(params.physical_device, params.surface, &n_present_modes, present_modes.ptr) != vkc.VK_SUCCESS) {
        return error.VulkanSurfaceFormatsError;
    }
    return present_modes;
}

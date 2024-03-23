const std = @import("std");
const glfwc = @import("./glfw-c.zig").c;

/// returns surface. needs to be destroyed.
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

pub fn get_capabilities(physical_device: glfwc.VkPhysicalDevice, surface: glfwc.VkSurfaceKHR) !glfwc.VkSurfaceCapabilitiesKHR {
    var capabilities: glfwc.VkSurfaceCapabilitiesKHR = undefined;
    if (glfwc.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physical_device, surface, &capabilities) != glfwc.VK_SUCCESS) {
        return error.VulkanSurfaceCapabilitiesError;
    }
    return capabilities;
}

pub fn get_n_formats(physical_device: glfwc.VkPhysicalDevice, surface: glfwc.VkSurfaceKHR) u32 {
    var n_formats: u32 = 0;
    if (glfwc.vkGetPhysicalDeviceSurfaceFormatsKHR(physical_device, surface, &n_formats, null) != glfwc.VK_SUCCESS) {
        return 0;
    }
    return n_formats;
}

/// returns surface formats. needs to be deallocated.
pub fn get_formats(physical_device: glfwc.VkPhysicalDevice, surface: glfwc.VkSurfaceKHR, allocator: std.mem.Allocator) ![]glfwc.VkSurfaceFormatKHR {
    var n_formats = get_n_formats(physical_device, surface);
    var formats = try allocator.alloc(glfwc.VkSurfaceFormatKHR, n_formats);
    if (glfwc.vkGetPhysicalDeviceSurfaceFormatsKHR(physical_device, surface, &n_formats, formats.ptr) != glfwc.VK_SUCCESS) {
        return error.VulkanSurfaceFormatsError;
    }
    return formats;
}

pub fn get_n_present_modes(physical_device: glfwc.VkPhysicalDevice, surface: glfwc.VkSurfaceKHR) u32 {
    var n_present_modes: u32 = 0;
    if (glfwc.vkGetPhysicalDeviceSurfacePresentModesKHR(physical_device, surface, &n_present_modes, null) != glfwc.VK_SUCCESS) {
        return 0;
    }
    return n_present_modes;
}

/// returns surface present modes. needs to be deallocated.
pub fn get_present_modes(physical_device: glfwc.VkPhysicalDevice, surface: glfwc.VkSurfaceKHR, allocator: std.mem.Allocator) ![]glfwc.VkPresentModeKHR {
    var n_present_modes = get_n_present_modes(physical_device, surface);
    var present_modes = try allocator.alloc(glfwc.VkPresentModeKHR, n_present_modes);
    if (glfwc.vkGetPhysicalDeviceSurfacePresentModesKHR(physical_device, surface, &n_present_modes, present_modes.ptr) != glfwc.VK_SUCCESS) {
        return error.VulkanSurfaceFormatsError;
    }
    return present_modes;
}

const std = @import("std");
const visual = @import("./main.zig");

pub const RunState = enum {
    Initializing,
    Looping,
    Waiting,
    Failing,
    Sleeping,
    Resizing,
    Deinitializing,
};

pub const State = struct {
    run_state: RunState = RunState.Initializing,
    configs: struct {
        app_name: [:0]const u8,
        initial_window_width: usize,
        initial_window_height: usize,
        icon_file: ?[:0]const u8 = null,
        max_frames: usize = 2,
        allocator: std.mem.Allocator,
    },
    objects: struct {
        window: *visual.vulkan.glfwc.GLFWwindow = undefined,
        window_extensions: [][*:0]const u8 = undefined,
        instance: visual.vulkan.glfwc.VkInstance = undefined,
        surface: visual.vulkan.glfwc.VkSurfaceKHR = undefined,
        surface_format: visual.vulkan.glfwc.VkSurfaceFormatKHR = undefined,
        physical_device: visual.vulkan.glfwc.VkPhysicalDevice = undefined,
        physical_device_properties: visual.vulkan.glfwc.VkPhysicalDeviceProperties = undefined,
        queue_family_indices: visual.vulkan.queue.QueueFamilyIndices = undefined,
        graphics_queue: visual.vulkan.glfwc.VkQueue = undefined,
        present_queue: visual.vulkan.glfwc.VkQueue = undefined,
        device: visual.vulkan.glfwc.VkDevice = undefined,
        layout: visual.vulkan.glfwc.VkPipelineLayout = undefined,
        pipeline: visual.vulkan.glfwc.VkPipeline = undefined,
        render_pass: visual.vulkan.glfwc.VkRenderPass = undefined,
    },
    frames: struct {
        extent: visual.vulkan.glfwc.VkExtent2D = undefined,
        frame_index: usize = 0,
        swapchain: visual.vulkan.glfwc.VkSwapchainKHR = undefined,
        command_pool: visual.vulkan.glfwc.VkCommandPool = undefined,
        command_buffers: []visual.vulkan.glfwc.VkCommandBuffer = undefined,
        image_available_semaphores: []visual.vulkan.glfwc.VkSemaphore = undefined,
        render_finished_semaphores: []visual.vulkan.glfwc.VkSemaphore = undefined,
        in_flight_fences: []visual.vulkan.glfwc.VkFence = undefined,
        frame_buffers: []visual.vulkan.glfwc.VkFramebuffer = undefined,
        image_views: []visual.vulkan.glfwc.VkImageView = undefined,
        images: []visual.vulkan.glfwc.VkImage = undefined,
    },
    vertices: struct {
        list: []visual.vulkan.vertex.Vertex = undefined,
        buffer: visual.vulkan.glfwc.VkBuffer = undefined,
        memory: visual.vulkan.glfwc.VkDeviceMemory = undefined,
    },
};

pub fn create(
    app_name: [:0]const u8,
    initial_window_width: usize,
    initial_window_height: usize,
    icon_file: ?[:0]const u8,
    allocator: std.mem.Allocator,
) State {
    return State{
        .configs = .{
            .app_name = app_name,
            .initial_window_width = initial_window_width,
            .initial_window_height = initial_window_height,
            .icon_file = icon_file,
            .allocator = allocator,
        },
        .objects = .{},
        .frames = .{},
        .vertices = .{},
    };
}

const std = @import("std");
const glfwc = @import("./vulkan/glfw-c.zig").c;
const Image = @import("../library/image/types.zig").Image;
const QueueFamilyIndices = @import("./vulkan/types.zig").QueueFamilyIndices;
const Vertex = @import("./vulkan/types.zig").Vertex;
const UniformBufferObject = @import("./vulkan/types.zig").UniformBufferObject;

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
    configs: struct {
        app_name: [:0]const u8,
        initial_window_width: usize,
        initial_window_height: usize,
        window_resizable: bool,
        validation_layers: []const [:0]const u8,
        required_extension_names: []const [:0]const u8,
        icon_file: ?[:0]const u8 = null,
        max_frames: usize = 2,
        allocator: std.mem.Allocator,
    },
    objects: struct {
        icon: ?Image = null,
    },
    instance: struct {
        instance: glfwc.VkInstance = undefined,
        window: *glfwc.GLFWwindow = undefined,
        window_extensions: [][*:0]const u8 = undefined,
        surface: glfwc.VkSurfaceKHR = undefined,
        surface_format: glfwc.VkSurfaceFormatKHR = undefined,
        physical_device: glfwc.VkPhysicalDevice = undefined,
        physical_device_properties: glfwc.VkPhysicalDeviceProperties = undefined,
        device: glfwc.VkDevice = undefined,
        queue_family_indices: QueueFamilyIndices = undefined,
        graphics_queue: glfwc.VkQueue = undefined,
        present_queue: glfwc.VkQueue = undefined,
        transfer_queue: glfwc.VkQueue = undefined,
    },
    model: struct {
        vertices: []const Vertex = undefined,
        vertex_buffer: glfwc.VkBuffer = undefined,
        vertex_buffer_memory: glfwc.VkDeviceMemory = undefined,
        indices: []const u32 = undefined,
        index_buffer: glfwc.VkBuffer = undefined,
        index_buffer_memory: glfwc.VkDeviceMemory = undefined,
        uniform_buffer: []glfwc.VkBuffer = undefined,
        uniform_buffer_memory: []glfwc.VkDeviceMemory = undefined,
        uniform_buffer_map: [][*]UniformBufferObject = undefined,
        vert_shader_module: glfwc.VkShaderModule = undefined,
        frag_shader_module: glfwc.VkShaderModule = undefined,
    },
    pipeline: struct {
        descriptor_pool: glfwc.VkDescriptorPool = undefined,
        descriptor_sets: []glfwc.VkDescriptorSet = undefined,
        descriptor_set_layout: glfwc.VkDescriptorSetLayout = undefined,
        layout: glfwc.VkPipelineLayout = undefined,
        pipeline: glfwc.VkPipeline = undefined,
        renderpass: glfwc.VkRenderPass = undefined,
    },
    command: struct {
        pool: glfwc.VkCommandPool = undefined,
        buffers: []glfwc.VkCommandBuffer = undefined,
        image_available_semaphores: []glfwc.VkSemaphore = undefined,
        render_finished_semaphores: []glfwc.VkSemaphore = undefined,
        in_flight_fences: []glfwc.VkFence = undefined,
    },
    swapchain: struct {
        extent: glfwc.VkExtent2D = undefined,
        swapchain: glfwc.VkSwapchainKHR = undefined,
        frame_buffers: []glfwc.VkFramebuffer = undefined,
        image_views: []glfwc.VkImageView = undefined,
        images: []glfwc.VkImage = undefined,
        texture_image: glfwc.VkImage = undefined,
        texture_image_view: glfwc.VkImageView = undefined,
        texture_image_memory: glfwc.VkDeviceMemory = undefined,
        texture_sampler: glfwc.VkSampler = undefined,
    },
    loop: struct {
        run_state: RunState = RunState.Initializing,
        frame_index: usize = 0,
        timer: std.time.Timer = undefined,
    },
};

pub fn create(params: struct {
    app_name: [:0]const u8,
    initial_window_width: usize,
    initial_window_height: usize,
    window_resizable: bool = true,
    validation_layers: []const [:0]const u8,
    required_extension_names: []const [:0]const u8,
    allocator: std.mem.Allocator,
    icon_file: ?[:0]const u8 = null,
    max_frames: usize = 2,
}) State {
    return State{
        .configs = .{
            .app_name = params.app_name,
            .initial_window_width = params.initial_window_width,
            .initial_window_height = params.initial_window_height,
            .window_resizable = params.window_resizable,
            .required_extension_names = params.required_extension_names,
            .validation_layers = params.validation_layers,
            .allocator = params.allocator,
            .icon_file = params.icon_file,
            .max_frames = params.max_frames,
        },
        .objects = .{},
        .instance = .{},
        .model = .{},
        .pipeline = .{},
        .command = .{},
        .swapchain = .{},
        .loop = .{},
    };
}

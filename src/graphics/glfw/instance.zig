const glfwc = @import("./glfw-c.zig").c;

pub fn init(params: struct {
    vulkan_proc_addr: glfwc.PFN_vkGetInstanceProcAddr,
}) void {
    if (params.vulkan_proc_addr) |vulkan_proc_addr| {
        glfwc.glfwInitVulkanLoader(vulkan_proc_addr);
    }
    _ = glfwc.glfwInit();
}

pub fn deinit() void {
    glfwc.glfwTerminate();
}

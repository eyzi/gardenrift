const tehuti = @import("tehuti");
const Vector3 = @import("tehuti").types.Vector3;
const Matrix4 = @import("tehuti").types.Matrix4;
const glfwc = @import("./glfw-c.zig").c;

pub const QueueFamilyIndices = struct {
    graphics_family: ?u32 = null,
    present_family: ?u32 = null,
    transfer_family: ?u32 = null,
    compute_family: ?u32 = null,
};

pub const Vertex = struct {
    position: @Vector(3, f32),
    color: @Vector(3, f32),
    texCoord: @Vector(2, f32),
};

pub const UniformBufferObject = struct {
    model: Matrix4 align(16) = tehuti.matrix4.identity(),
    view: Matrix4 align(16) = tehuti.matrix4.identity(),
    proj: Matrix4 align(16) = tehuti.matrix4.identity(),
};

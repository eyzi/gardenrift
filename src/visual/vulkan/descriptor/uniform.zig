const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;
const math = @import("../../../library/math/main.zig");
const new_math = @import("../../../library/math/_.zig");
const UniformBufferObject = @import("../types.zig").UniformBufferObject;

const Axis = struct {
    x: f32,
    y: f32,
    z: f32,
};

pub fn update(params: struct {
    index: u32,
    map: [*]UniformBufferObject,
    time: u64,
}) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const duration_s2: f32 = 30.0;
    const angle_2 = @mod(@as(f32, @floatFromInt(params.time)) / std.time.ns_per_s, duration_s2) / duration_s2;

    var ubo: UniformBufferObject = .{};

    const model_translate = math.create_translate_matrix(0.05, 0.3, 2.0);
    const model_rotate = math.create_rotate_matrix(120, 0, -360 * angle_2);
    const model_scale = math.create_scale_matrix(1.0, 1.0, 1.0);
    ubo.model = math.matrix_multiply(math.matrix_multiply(model_scale, model_rotate), model_translate);

    const eye = @Vector(3, f32){ 0.0, 0.0, -1.0 };
    const target = @Vector(3, f32){ 0.0, 0.0, 0.0 };
    const up = @Vector(3, f32){ 0.0, 1.0, 0.0 };
    ubo.view = math.look_at(target, eye, up);

    // ubo.proj = math.create_short_perspective_matrix(70, 1, 100);
    ubo.proj = math.create_short_orthographic_matrix(100);

    // var ubo: UniformBufferObject = .{};
    // const model_translate2 = new_math.matrix4.translate(0.05, 0.3, 2.0);
    // const model_rotate2 = new_math.matrix4.rotate(120, 0, -360 * angle_2);
    // const model_scale2 = new_math.matrix4.scale(1, 1, 1);
    // ubo.model = new_math.matrix4.multiply(new_math.matrix4.multiply(model_translate2, model_rotate2), model_scale2);

    // const eye2 = new_math.vector3.create(0, 0, -1);
    // const target2 = new_math.vector3.create(0, 0, 0);
    // const up2 = new_math.vector3.create(0, 1, 0);
    // ubo.view = new_math.matrix4.look_at(target2, eye2, up2);

    // ubo.proj = new_math.matrix4.quick_perspective_matrix(70, 1, 100);
    // // ubo.proj = new_math.matrix4.quick_orthographic_matrix(100);

    @memcpy(params.map, &[_]UniformBufferObject{ubo});
}

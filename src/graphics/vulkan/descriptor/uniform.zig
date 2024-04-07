const std = @import("std");
const math = @import("../../../library/math/_.zig");
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
    const model_translate2 = math.matrix4.translate(0.05, -0.3, 2.0);
    const model_rotate2 = math.matrix4.rotate(240, 0, -360 * angle_2);
    const model_scale2 = math.matrix4.scale(1, 1, 1);
    ubo.model = math.matrix4.multiply(math.matrix4.multiply(model_translate2, model_rotate2), model_scale2);

    const eye = math.vector3.new(0, 0, -1);
    const target = math.vector3.new(0, 0, 0);
    const up = math.vector3.new(0, 1, 0);
    ubo.view = math.matrix4.look_at(target, eye, up);

    // ubo.proj = math.matrix4.quick_perspective_matrix(50, 1, 100);
    ubo.proj = math.matrix4.quick_orthographic_matrix(100);

    @memcpy(params.map, &[_]UniformBufferObject{ubo});
}

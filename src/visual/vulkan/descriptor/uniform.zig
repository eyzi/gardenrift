const std = @import("std");
const glfwc = @import("../glfw-c.zig").c;
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
    var ubo: UniformBufferObject = .{};
    const duration_s2: f32 = 30.0;
    const angle_2 = @mod(@as(f32, @floatFromInt(params.time)) / std.time.ns_per_s, duration_s2) / duration_s2;

    const model_translate = create_translate_matrix(-0.1, 0.4, 2.0);
    const model_rotate = create_rotate_matrix(90, 0, angle_2 * 360);
    const model_scale = create_scale_matrix(1.0, 1.0, 1.0);
    ubo.model = dot(dot(model_scale, model_rotate), model_translate);

    const eye = @Vector(3, f32){ 0.0, 0.0, -1.0 };
    const target = @Vector(3, f32){ 0.0, 0.0, 0.0 };
    const up = @Vector(3, f32){ 0.0, 1.0, 0.0 };
    ubo.view = look_at(target, eye, up);

    ubo.proj = create_perspective_matrix(70, 1, 0.1, 100.0);
    @memcpy(params.map, &[_]UniformBufferObject{ubo});
}

fn cross(a: @Vector(3, f32), b: @Vector(3, f32)) @Vector(3, f32) {
    return @Vector(3, f32){
        (a[1] * b[2]) - (a[2] * b[1]),
        (a[2] * b[0]) - (a[0] * b[2]),
        (a[0] * b[1]) - (a[1] * b[0]),
    };
}

fn normalize(vector: @Vector(3, f32)) @Vector(3, f32) {
    const magnitude: f32 = @sqrt(square(vector[0]) + square(vector[1]) + square(vector[2]));
    return @Vector(3, f32){ vector[0] / magnitude, vector[1] / magnitude, vector[2] / magnitude };
}

fn look_at(target: @Vector(3, f32), eye: @Vector(3, f32), up: @Vector(3, f32)) [4]@Vector(4, f32) {
    const f = normalize(.{ target[0] - eye[0], target[1] - eye[1], target[2] - eye[2] });
    const s = normalize(cross(f, up));
    const u = cross(s, f);

    return [4]@Vector(4, f32){
        .{ s[0], s[1], s[2], 0 },
        .{ u[0], u[1], u[2], 0 },
        .{ f[0], f[1], f[2], 0 },
        .{ -target[0], -target[1], target[2], 1.0 },
    };
}

fn create_perspective_matrix(fov: f32, aspect_ratio: f32, near: f32, far: f32) [4]@Vector(4, f32) {
    const tana = @tan(radians(fov) / 2);
    return [4]@Vector(4, f32){
        .{ 1 / (aspect_ratio * tana), 0, 0, 0 },
        .{ 0, 1 / tana, 0, 0 },
        .{ 0, 0, far / (far - near), 1 },
        .{ 0, 0, (-near * far) / (far - near), 0 },
    };
}

fn create_translate_matrix(x: f32, y: f32, z: f32) [4]@Vector(4, f32) {
    return [4]@Vector(4, f32){
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ x, y, z, 1 },
    };
}

fn create_scale_matrix(x: f32, y: f32, z: f32) [4]@Vector(4, f32) {
    return [4]@Vector(4, f32){
        .{ x, 0, 0, 0 },
        .{ 0, y, 0, 0 },
        .{ 0, 0, z, 0 },
        .{ 0, 0, 0, 1 },
    };
}

fn create_rotate_matrix(x: f32, y: f32, z: f32) [4]@Vector(4, f32) {
    const x_radians = radians(x);
    const y_radians = radians(y);
    const z_radians = radians(z);

    const x_rotate = [4]@Vector(4, f32){
        .{ 1.0, 0.0, 0.0, 0.0 },
        .{ 0.0, @cos(x_radians), @sin(x_radians), 0.0 },
        .{ 0.0, -@sin(x_radians), @cos(x_radians), 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    };

    const y_rotate = [4]@Vector(4, f32){
        .{ @cos(y_radians), 0.0, -@sin(y_radians), 0.0 },
        .{ 0.0, 1.0, 0.0, 0.0 },
        .{ @sin(y_radians), 0.0, @cos(y_radians), 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    };

    const z_rotate = [4]@Vector(4, f32){
        .{ @cos(z_radians), @sin(z_radians), 0.0, 0.0 },
        .{ -@sin(z_radians), @cos(z_radians), 0.0, 0.0 },
        .{ 0.0, 0.0, 1.0, 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    };

    return dot(dot(z_rotate, y_rotate), x_rotate);
}

fn radians(degrees: f32) f32 {
    return degrees * (std.math.pi / 180.0);
}

fn square(n: f32) f32 {
    return std.math.pow(f32, n, 2);
}

fn dot(a: [4]@Vector(4, f32), b: [4]@Vector(4, f32)) [4]@Vector(4, f32) {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var product = allocator.alloc(@Vector(4, f32), 4) catch unreachable;
    defer allocator.free(product);

    for (0..4) |row| {
        for (0..4) |col| {
            product[row][col] = @reduce(.Add, @Vector(4, f32){ a[row][0], a[row][1], a[row][2], a[row][3] } * @Vector(4, f32){ b[0][col], b[1][col], b[2][col], b[3][col] });
        }
    }

    return [4]@Vector(4, f32){
        product[0],
        product[1],
        product[2],
        product[3],
    };
}

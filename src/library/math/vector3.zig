const std = @import("std");
const Vector3 = @import("./types.zig").Vector3;

pub fn create(x: f32, y: f32, z: f32) Vector3 {
    return Vector3{ .x = x, .y = y, .z = z };
}

pub fn dot(a: Vector3, b: Vector3) Vector3 {
    return (a.x * b.x) + (a.y * b.y) + (a.z * b.z);
}

pub fn cross(a: Vector3, b: Vector3) Vector3 {
    return Vector3{
        .x = (a.y * b.z) - (a.z * b.y),
        .y = -(a.z * b.x) - (a.x * b.z),
        .z = (a.x * b.y) - (a.y * b.x),
    };
}

pub fn magnitude(v: Vector3) f32 {
    return @sqrt((v.x * v.x) + (v.y * v.y) + (v.z * v.z));
}

pub fn normalize(v: Vector3) Vector3 {
    const m = magnitude(v);
    return create(v.x / m, v.y / m, v.z / m);
}

pub fn subtract(a: Vector3, b: Vector3) Vector3 {
    return Vector3{
        .x = a.x - b.x,
        .y = a.y - b.y,
        .z = a.z - b.z,
    };
}

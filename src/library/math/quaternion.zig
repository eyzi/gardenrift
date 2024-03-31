const std = @import("std");
const Vector3 = @import("./types.zig").Vector3;
const Quaternion = @import("./types.zig").Quaternion;
const Matrix4 = @import("./types.zig").Matrix4;
const matrix4 = @import("./matrix4.zig");

pub fn identity() Quaternion {
    return Quaternion{ .x = 0, .y = 0, .z = 0, .w = 1 };
}

pub fn normal(q: Quaternion) f32 {
    return @sqrt((q.x * q.x) + (q.y * q.y) + (q.z * q.z) + (q.w * q.w));
}

pub fn normalize(q: Quaternion) Quaternion {
    const n = normal(q);
    return Quaternion{
        .x = q.x / n,
        .y = q.y / n,
        .z = q.z / n,
        .w = q.w / n,
    };
}

pub fn conjugate(q: Quaternion) Quaternion {
    return Quaternion{
        .x = -q.x,
        .y = -q.y,
        .z = -q.z,
        .w = q.w,
    };
}

pub fn inverse(q: Quaternion) Quaternion {
    return normalize(conjugate(q));
}

pub fn multiply(q0: Quaternion, q1: Quaternion) Quaternion {
    return Quaternion{
        .x = q0.x * q1.w + q0.y * q1.z - q0.z * q1.y + q0.w * q1.x,
        .y = -q0.x * q1.z + q0.y * q1.w + q0.z * q1.x + q0.w * q1.y,
        .z = q0.x * q1.y - q0.y * q1.x + q0.z * q1.w + q0.w * q1.z,
        .w = -q0.x * q1.x - q0.y * q1.y - q0.z * q1.z + q0.w * q1.w,
    };
}

pub fn dot(q0: Quaternion, q1: Quaternion) f32 {
    return q0.x * q1.x + q0.y * q1.y + q0.z * q1.z + q0.w * q1.w;
}

pub fn to_matrix4(q: Quaternion) Matrix4 {
    var m = matrix4.identity();
    const n = normalize(q);
    m[0] = 1 - (2 * n.y * n.y) - (2 * n.z * n.z);
    m[1] = (2 * n.x * n.y) - (2 * n.z * n.w);
    m[2] = (2 * n.x * n.z) + (2 * n.y * n.w);
    m[4] = (2 * n.x * n.y) + (2 * n.z * n.w);
    m[5] = 1 - (2 * n.x * n.x) - (2 * n.z * n.z);
    m[6] = (2 * n.y * n.z) - (2 * n.x * n.w);
    m[8] = (2 * n.x * n.z) - (2 * n.y * n.w);
    m[9] = (2 * n.y * n.z) + (2 * n.x * n.w);
    m[10] = 1 - (2 * n.x * n.x) - (2 * n.y * n.y);
    return m;
}

pub fn to_rotation_matrix4(q: Quaternion, center: Vector3) Matrix4 {
    var m = matrix4.identity();
    m[0] = (q.x * q.x) - (q.y * q.y) - (q.z * q.z) + (q.w * q.w);
    m[1] = 2 * ((q.x * q.y) + (q.z * q.w));
    m[2] = 2 * ((q.x * q.z) - (q.y * q.w));
    m[3] = center.x - center.x * m[0] - center.y * m[1] - center.z * m[2];
    m[4] = 2 * ((q.x * q.y) - (q.z * q.w));
    m[5] = -(q.x * q.x) + (q.y * q.y) - (q.z * q.z) + (q.w * q.w);
    m[6] = 2 * ((q.y * q.z) + (q.x * q.w));
    m[7] = center.x - center.x * m[4] - center.y * m[5] - center.z * m[6];
    m[8] = 2 * ((q.x * q.z) + (q.y * q.w));
    m[9] = 2 * ((q.y * q.z) - (q.x * q.w));
    m[10] = -(q.x * q.x) - (q.y * q.y) + (q.z * q.z) + (q.w * q.w);
    m[11] = center.x - center.x * m[8] - center.y * m[9] - center.z * m[10];
    return m;
}

pub fn from_axis_angle(axis: Vector3, angle: f32) Quaternion {
    const half_angle = 0.5 * angle;
    const sha = @sin(half_angle);
    const cha = @cos(half_angle);
    return normalize(Quaternion{
        .x = sha * axis.x,
        .y = sha * axis.y,
        .z = sha * axis.z,
        .w = cha,
    });
}

pub fn slerp(q0: Quaternion, q1: Quaternion, percentage: f32) Quaternion {
    var q = identity();

    var v0 = normalize(q0);
    var v1 = normalize(q1);
    var d = dot(v0, v1);

    if (d < 0) {
        v1.x *= -1;
        v1.y *= -1;
        v1.z *= -1;
        d *= -1;
    }

    const DOT_THRESHOLD: f32 = 0.9995;
    if (d > DOT_THRESHOLD) {
        q.x = v0.x + ((v1.x - v0.x) * percentage);
        q.y = v0.y + ((v1.y - v0.y) * percentage);
        q.z = v0.z + ((v1.z - v0.z) * percentage);
        q.w = v0.w + ((v1.w - v0.w) * percentage);
        return normalize(q);
    }

    const theta_0 = std.math.acos(d);
    const theta = theta_0 * percentage;
    const sin_theta = @sin(theta);
    const sin_theta_0 = @sin(theta_0);

    const s0 = @cos(theta) - d * sin_theta / sin_theta_0;
    const s1 = sin_theta / sin_theta_0;

    return Quaternion{
        .x = (v0.x * s0) + (v1.x * s1),
        .y = (v0.y * s0) + (v1.y * s1),
        .z = (v0.z * s0) + (v1.z * s1),
        .w = (v0.w * s0) + (v1.w * s1),
    };
}

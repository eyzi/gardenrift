const std = @import("std");
const angle = @import("./angle.zig");
const Vector3 = @import("./types.zig").Vector3;
const Quaternion = @import("./types.zig").Quaternion;
const Matrix4 = @import("./types.zig").Matrix4;
const vector3 = @import("./vector3.zig");

/// NOTE: column-major
///
pub fn identity() Matrix4 {
    return Matrix4{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    };
}

pub fn transpose(m: Matrix4) Matrix4 {
    var mt = identity();
    for (0..4) |r| {
        for (0..4) |c| {
            const m_index = (c * 4) + r;
            const mt_index = (r * 4) + c;
            mt[mt_index] = m[m_index];
        }
    }
    return mt;
}

pub fn multiply(a: Matrix4, b: Matrix4) Matrix4 {
    const at = transpose(a);
    var p = identity();
    for (0..16) |p_index| {
        const r = @divFloor(p_index, 4) * 4;
        const c = @mod(p_index, 4) * 4;
        const av = @Vector(4, f32){ at[c], at[c + 1], at[c + 2], at[c + 3] };
        const bv = @Vector(4, f32){ b[r], b[r + 1], b[r + 2], b[r + 3] };
        const pv = @reduce(.Add, av * bv);
        p[p_index] = pv;
    }
    return p;
}

pub fn translate(x: f32, y: f32, z: f32) Matrix4 {
    var m = identity();
    m[12] = x;
    m[13] = y;
    m[14] = z;
    return m;
}

pub fn scale(x: f32, y: f32, z: f32) Matrix4 {
    var m = identity();
    m[0] = x;
    m[5] = y;
    m[10] = z;
    return m;
}

pub fn rotate(x: f32, y: f32, z: f32) Matrix4 {
    const x_radians = angle.degrees_to_radians(x);
    const y_radians = angle.degrees_to_radians(y);
    const z_radians = angle.degrees_to_radians(z);

    var x_rotate = identity();
    x_rotate[5] = @cos(x_radians);
    x_rotate[6] = @sin(x_radians);
    x_rotate[9] = -@sin(x_radians);
    x_rotate[10] = @cos(x_radians);

    var y_rotate = identity();
    y_rotate[0] = @cos(y_radians);
    y_rotate[2] = -@sin(y_radians);
    y_rotate[8] = @sin(y_radians);
    y_rotate[10] = @cos(y_radians);

    var z_rotate = identity();
    z_rotate[0] = @cos(z_radians);
    z_rotate[1] = @sin(z_radians);
    z_rotate[4] = -@sin(z_radians);
    z_rotate[5] = @cos(z_radians);

    return multiply(multiply(x_rotate, y_rotate), z_rotate);
}

pub fn orthographic_matrix(left: f32, right: f32, top: f32, bottom: f32, near: f32, far: f32) Matrix4 {
    var m = identity();
    m[0] = 2 / (right - left);
    m[5] = 2 / (bottom - top);
    m[10] = 1 / (far - near);
    m[12] = -(right + left) / (right - left);
    m[13] = -(bottom + top) / (bottom - top);
    m[14] = near / (far - near);
    return m;
}

pub fn quick_orthographic_matrix(far: f32) Matrix4 {
    var m = identity();
    m[10] = 1 / far;
    return m;
}

pub fn perspective_matrix(fov: f32, aspect_ratio: f32, near: f32, far: f32) Matrix4 {
    var m = identity();
    const tan_a = @tan(angle.degrees_to_radians(fov) / 2);
    m[0] = 1 / (aspect_ratio * tan_a);
    m[5] = 1 / tan_a;
    m[10] = far / (far - near);
    m[11] = 1;
    m[14] = -(near * far) / (far - near);
    return m;
}

pub fn quick_perspective_matrix(fov: f32, aspect_ratio: f32, far: f32) Matrix4 {
    var m = identity();
    const tan_a = @tan(angle.degrees_to_radians(fov) / 2);
    m[0] = 1 / (aspect_ratio * tan_a);
    m[5] = 1 / tan_a;
    m[10] = 1;
    m[11] = 1;
    m[14] = -1 / far;
    return m;
}

pub fn forward_vector(m: Matrix4) Vector3 {
    return vector3.normalize(Vector3{ .x = m[2], .y = m[6], .z = m[10] });
}

pub fn backward_vector(m: Matrix4) Vector3 {
    return vector3.normalize(Vector3{ .x = -m[2], .y = -m[6], .z = -m[10] });
}

pub fn up_vector(m: Matrix4) Vector3 {
    return vector3.normalize(Vector3{ .x = -m[1], .y = -m[5], .z = -m[9] });
}

pub fn down_vector(m: Matrix4) Vector3 {
    return vector3.normalize(Vector3{ .x = m[1], .y = m[5], .z = m[9] });
}

pub fn left_vector(m: Matrix4) Vector3 {
    return vector3.normalize(Vector3{ .x = -m[0], .y = -m[4], .z = -m[8] });
}

pub fn right_vector(m: Matrix4) Vector3 {
    return vector3.normalize(Vector3{ .x = m[0], .y = m[4], .z = m[8] });
}

pub fn look_at(target: Vector3, eye: Vector3, up: Vector3) Matrix4 {
    const f = vector3.normalize(vector3.subtract(target, eye));
    const s = vector3.normalize(vector3.cross(f, up));
    const u = vector3.cross(s, f);

    var m = identity();
    m[0] = s.x;
    m[1] = s.y;
    m[2] = s.z;
    m[4] = u.x;
    m[5] = u.x;
    m[6] = u.x;
    m[8] = f.x;
    m[9] = f.x;
    m[10] = f.x;
    m[12] = -target.x;
    m[13] = -target.y;
    m[14] = -target.z;
    return m;
}

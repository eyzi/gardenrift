const std = @import("std");

pub fn degrees_to_radians(degrees: f32) f32 {
    return degrees * (std.math.pi / 180.0);
}

pub fn radians_to_degrees(radians: f32) f32 {
    return radians * (180.0 / std.math.pi);
}

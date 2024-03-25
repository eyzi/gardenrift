const std = @import("std");

pub const KeyValuePair = std.meta.Tuple(&.{ []u8, []u8 });

pub const Format = enum {
    BMP,
};

pub const Pixel = struct {
    red: u8,
    green: u8,
    blue: u8,
    alpha: u8,
};

pub const Image = struct {
    format: Format,
    width: usize,
    height: usize,
    pixels: []Pixel,
    bytes: []u8,
    attributes: ?[]KeyValuePair = null,
};

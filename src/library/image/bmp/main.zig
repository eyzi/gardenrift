const std = @import("std");
const file = @import("../../file/main.zig");
const RgbaImage = @import("../types.zig").RgbaImage;
const Pixel = @import("../types.zig").Pixel;

pub fn has_signature(bytes: []u8) bool {
    return bytes.len >= 2 and std.mem.eql(u8, "BM", bytes[0..2]);
}

pub fn int_bytes(comptime T: type, bytes: anytype) T {
    return std.mem.littleToNative(T, std.mem.bytesToValue(T, bytes));
}

pub fn parse(bytes: []u8, allocator: std.mem.Allocator) !RgbaImage {
    if (!has_signature(bytes)) return error.InvalidType;

    const signature: []u8 = bytes[0..2];
    const file_size = int_bytes(u32, bytes[2..6]);
    const unused = int_bytes(u32, bytes[6..10]);
    const offset = int_bytes(u32, bytes[10..14]);

    const header_size = int_bytes(u32, bytes[14..18]);
    const width = try std.math.absInt(int_bytes(i32, bytes[18..22]));
    const height = try std.math.absInt(int_bytes(i32, bytes[22..26]));
    const planes = int_bytes(u16, bytes[26..28]);
    const bits_per_pixels = int_bytes(u16, bytes[28..30]);
    const compression = int_bytes(u32, bytes[30..34]);
    const image_size = int_bytes(u32, bytes[34..38]);
    const x_pixels_per_meter = int_bytes(u32, bytes[38..42]);
    const y_pixels_per_meter = int_bytes(u32, bytes[42..46]);
    const colors_used = int_bytes(u32, bytes[46..50]);
    const important_colors = int_bytes(u32, bytes[50..54]);
    const r_intensity = bytes[54];
    const g_intensity = bytes[55];
    const b_intensity = bytes[56];
    const reserved = bytes[57];

    _ = signature;
    _ = file_size;
    _ = unused;
    _ = header_size;
    _ = planes;
    _ = bits_per_pixels;
    _ = compression;
    _ = image_size;
    _ = x_pixels_per_meter;
    _ = y_pixels_per_meter;
    _ = colors_used;
    _ = important_colors;
    _ = r_intensity;
    _ = g_intensity;
    _ = b_intensity;
    _ = reserved;

    const data = bytes[offset..];

    // Assuming 32-bit pixels and in ABGR format
    const byte_length = 4;
    var pixels = try allocator.alloc(Pixel, @as(usize, @intCast(width * height * byte_length * 4)));
    var i_pixel: usize = 0;

    while (i_pixel * byte_length < data.len - byte_length) : (i_pixel += 1) {
        const data_offset = i_pixel * byte_length;
        const red = data[data_offset + 3];
        const green = data[data_offset + 2];
        const blue = data[data_offset + 1];
        const alpha = data[data_offset];

        pixels[i_pixel] = Pixel{
            .alpha = alpha,
            .blue = blue,
            .green = green,
            .red = red,
        };
    }

    return RgbaImage{
        .width = @as(usize, @intCast(width)),
        .height = @as(usize, @intCast(height)),
        .pixels = pixels,
    };
}

pub fn parse_file(filename: [:0]const u8, allocator: std.mem.Allocator) !RgbaImage {
    const bytes = try file.get_content(filename, allocator);
    defer allocator.free(bytes);
    return parse(bytes, allocator);
}

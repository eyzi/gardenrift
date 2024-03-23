const std = @import("std");

pub const Icon = struct {
    width: usize,
    height: usize,
    pixels: []u32,
};

fn bytes_to_int(bytes: []u8) usize {
    var value: usize = 0;
    for (bytes) |byte| {
        value = (value << 8) + (byte & 0xFF);
    }
    return value;
}

fn bytes_to_int_little(bytes: []u8) usize {
    var value: usize = 0;
    for (bytes, 0..) |byte, i| {
        const byte2: usize = @intCast(byte);
        const shift: u6 = if (i == 0) 0 else @intCast(8 ^ (i - 1));
        value |= byte2 << shift;
    }
    return value;
}

/// returns icon object containing pixel array. needs to be deallocated.
pub fn parse_icon(filename: [:0]const u8, allocator: std.mem.Allocator) !Icon {
    const icon_file = try std.fs.cwd().openFile(filename, .{});
    defer icon_file.close();

    const content = try icon_file.readToEndAlloc(allocator, (try icon_file.stat()).size);
    defer allocator.free(content);

    const bytelength: usize = 4;
    const width = bytes_to_int_little(content[18..22]);
    const offset = @as(usize, @intCast(content[10]));
    const height = @divFloor(content[offset..].len, width * bytelength);

    var pixels = try allocator.alloc(u32, height * width);
    var i_data: usize = 0;
    var i_pixel: usize = 0;
    while (i_data < content.len - offset - 4) : (i_data += bytelength) {
        const a_raw = content[offset + i_data];
        const b_raw = content[offset + i_data + 1];
        const g_raw = content[offset + i_data + 2];
        const r_raw = content[offset + i_data + 3];

        const a: u32 = @as(u32, @intCast(a_raw)) << 24;
        _ = a; // assuming that full white is transparent since alpha isnt working
        const b: u32 = @as(u32, @intCast(b_raw)) << 16;
        const g: u32 = @as(u32, @intCast(g_raw)) << 8;
        const r: u32 = @as(u32, @intCast(r_raw));
        if (r_raw == 255 and g_raw == 255 and b_raw == 255) {
            pixels[i_pixel] = 0;
        } else {
            pixels[i_pixel] = r | g | b | (255 << 24);
        }
        i_pixel += 1;
    }

    return Icon{
        .width = width,
        .height = height,
        .pixels = pixels,
    };
}

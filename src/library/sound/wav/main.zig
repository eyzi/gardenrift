const std = @import("std");
const file = @import("../../file/main.zig");
const Sound = @import("../types.zig").Sound;

pub fn has_signature(bytes: []u8) bool {
    return bytes.len >= 4 and std.mem.eql(u8, "RIFF", bytes[0..4]);
}

pub fn int_bytes(comptime T: type, bytes: anytype) T {
    return std.mem.littleToNative(T, std.mem.bytesToValue(T, bytes));
}

pub fn parse(bytes: []u8, allocator: std.mem.Allocator) !Sound {
    if (!has_signature(bytes)) return error.InvalidType;

    // RIFF chunk
    const magic: []u8 = bytes[0..4]; // "RIFF"
    const file_size = int_bytes(u32, bytes[4..8]);
    const file_format = bytes[8..12]; // "WAVE"

    // fmt chunk
    const fmt_id = bytes[12..16]; // "fmt "
    const fmt_size = int_bytes(u32, bytes[16..20]);
    const audio_format = int_bytes(u16, bytes[20..22]); // PCM = 1
    const n_channels = int_bytes(u16, bytes[22..24]);
    const sample_rate = int_bytes(u32, bytes[24..28]);
    const byte_rate = int_bytes(u32, bytes[28..32]);
    const block_align = int_bytes(u16, bytes[32..34]);
    const bit_depth = int_bytes(u16, bytes[34..36]);

    // data chunk
    const data_id = bytes[36..40]; // "data"
    const data_size = int_bytes(u32, bytes[40..44]); // == n_samples * n_channels * bit_depth / 8
    const data = bytes[44..];

    _ = magic;
    _ = file_size;
    _ = file_format;
    _ = fmt_id;
    _ = fmt_size;
    _ = audio_format;
    _ = block_align;
    _ = data_id;
    _ = allocator;

    return Sound{
        .format = .WAV,
        .sample_rate = sample_rate,
        .bit_depth = @as(u32, bit_depth),
        .bit_rate = byte_rate * 8,
        .n_channels = @as(u32, n_channels),
        .bytes = bytes,
        .data_size = data_size,
        .data = data,
    };
}

pub fn parse_file(filename: [:0]const u8, allocator: std.mem.Allocator) !Sound {
    const bytes = try file.get_content(filename, allocator);
    return parse(bytes, allocator);
}

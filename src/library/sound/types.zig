const std = @import("std");

pub const Format = enum {
    WAV,
};

pub const Sound = struct {
    format: Format,
    sample_rate: u32,
    bit_depth: u32,
    bit_rate: u32,
    n_channels: u32,
    data: []u8,
    data_size: u32,
    bytes: []u8,

    pub fn deallocate(self: Sound, allocator: std.mem.Allocator) void {
        allocator.free(self.bytes);
    }
};

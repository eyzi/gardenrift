const std = @import("std");

pub const c = @cImport({
    @cInclude("vulkan/vulkan.h");
    @cInclude("GLFW/glfw3.h");
});

/// since vulkan's strings always have 256 character count,
/// this helper function is to properly evaluate equality.
/// use `b` for the vulkan string.
pub fn string_eql(a: []const u8, b: []const u8) bool {
    return a.len <= b.len and std.mem.eql(u8, a, b[0..a.len]);
}

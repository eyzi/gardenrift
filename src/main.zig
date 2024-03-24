const std = @import("std");
const setup = @import("./setup.zig");

pub fn main() !void {
    const app_name = "Gardenrift";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    std.debug.print("\r===== {s} =====                           \n", .{app_name});
    try setup.graphics(app_name, gpa.allocator());
}

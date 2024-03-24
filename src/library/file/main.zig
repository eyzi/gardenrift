const std = @import("std");

pub fn get_content(filename: [:0]const u8, allocator: std.mem.Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const content = try file.readToEndAlloc(allocator, (try file.stat()).size);
    defer allocator.free(content);

    return try allocator.dupe(u8, content);
}

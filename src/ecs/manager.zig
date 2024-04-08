const std = @import("std");

const Health = struct { value: u8 };
const Location = struct { x: usize, y: usize };
const Size = struct { value: usize };

const ComponentList = &[_]type{
    Health,
    Location,
    Size,
};

const ComponentEnum = enum {
    Health,
    Location,
    Size,
};

const Archetypes = [_]component_mask_type(){
    create_component_mask(&[_]ComponentEnum{ .Health, .Location, .Size }),
};

var entities: std.ArrayList(component_mask_type()) = undefined;

fn component_mask_type() type {
    return @Type(.{ .Int = .{ .bits = ComponentList.len, .signedness = .unsigned } });
}

pub fn create_component_mask(requested_components: []const ComponentEnum) component_mask_type() {
    var mask: component_mask_type() = 0;

    for (requested_components) |requested_component| {
        const component_index = @intFromEnum(requested_component);
        mask += (@as(component_mask_type(), 1) << component_index);
    }

    return mask;
}

pub fn has_component(mask: component_mask_type(), component: ComponentEnum) bool {
    const component_mask = (@as(component_mask_type(), 1) << @intFromEnum(component));
    return mask & component_mask == component_mask;
}

pub fn setup(params: struct {
    allocator: std.mem.Allocator,
}) !void {
    entities = std.ArrayList(component_mask_type()).init(params.allocator);
    defer entities.deinit();

    try entities.append(create_component_mask(&[_]ComponentEnum{ .Location, .Size }));

    std.debug.print("{b} has health: {}\n", .{ entities.items, has_component(entities.items[0], .Health) });
    std.debug.print("{b}\n", .{Archetypes});
}

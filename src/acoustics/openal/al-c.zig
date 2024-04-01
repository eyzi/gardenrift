const std = @import("std");

pub const c = @cImport({
    @cInclude("al.h");
    @cInclude("alc.h");
});

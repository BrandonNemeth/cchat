const std = @import("std");

pub const net = @import("net.zig");
pub const protocol = @import("protocol.zig");

test {
    std.testing.refAllDecls(@This());
}

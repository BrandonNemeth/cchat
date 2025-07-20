const std = @import("std");
const net = std.net;

pub fn connect(host: []const u8, port: u16) !net.Stream {
    const address = try net.Address.resolveIp(host, port);
    return try net.tcpConnectToAddress(address);
}

pub fn bind_and_listen(port: u16) !net.Server {
    const address = try net.Address.parseIp("0.0.0.0", port);
    return try address.listen(.{ .reuse_address = true });
}

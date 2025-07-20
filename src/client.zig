const std = @import("std");
const net = std.net;
const thread = std.Thread;
const allocator = std.heap.page_allocator;

fn recv_thread(stream: *net.Stream) void {
    var reader = stream.reader();
    var buf: [1024]u8 = undefined;

    while (true) {
        const msg = reader.readUntilDelimiterOrEof(&buf, '\n') catch break;
        if (msg == null) break;
        std.debug.print("{s}\n", .{msg.?});
    }

    std.debug.print("Disconnected from server.\n", .{});
    std.process.exit(0);
}

pub fn main() !void {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: {s} <host> <port>\n", .{args[0]});
        return;
    }

    const host = args[1];
    const port = try std.fmt.parseInt(u16, args[2], 10);

    const address = try net.Address.resolveIp(host, port);
    var stream = try net.tcpConnectToAddress(address);
    defer stream.close();

    std.debug.print("Connected to {s}:{d}\n", .{ host, port });

    _ = try thread.spawn(.{}, recv_thread, .{&stream});

    const stdin = std.io.getStdIn().reader();
    const writer = stream.writer();
    var buf: [1024]u8 = undefined;

    while (true) {
        const input = stdin.readUntilDelimiterOrEof(&buf, '\n') catch break;
        if (input == null) break;
        try writer.writeAll(input.?);
        try writer.writeAll("\n");
    }
}

const std = @import("std");
const net = std.net;
const thread = std.Thread;
const allocator = std.heap.page_allocator;

fn recv_thread(stream: *net.Stream) void {
    var buf: [1024]u8 = undefined;

    while (true) {
        const n = stream.read(&buf) catch break;
        if (n == 0) break;
        std.debug.print("{s}", .{buf[0..n]});
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

    var stdin_buf: [1024]u8 = undefined;

    while (true) {
        const input_len = std.posix.read(std.posix.STDIN_FILENO, &stdin_buf) catch break;
        if (input_len == 0) break;

        _ = stream.write(stdin_buf[0..input_len]) catch break;
    }
}

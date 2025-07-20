const std = @import("std");
const netmod = @import("net.zig");
const proto = @import("protocol.zig");

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);

    if (args.len < 2) {
        std.debug.print("Usage: {s} server|client\n", .{args[0]});
        return;
    }

    if (std.mem.eql(u8, args[1], "server")) {
        var server = try netmod.bind_and_listen(9000);
        std.debug.print("Listening on 0.0.0.0:9000\n", .{});
        while (true) {
            var conn = try server.accept();
            std.debug.print("Accepted client\n", .{});

            var buf: [289]u8 = undefined;

            while (true) {
                const n = try conn.stream.read(&buf);
                if (n == 0) break;

                const msg = proto.Message.deserialize(buf[0..n]);
                std.debug.print("User {s}: {s}\n", .{ msg.username, msg.content });
            }
        }
    } else if (std.mem.eql(u8, args[1], "client")) {
        if (args.len < 4) {
            std.debug.print("Usage: {s} client <host> <username>\n", .{args[0]});
            return;
        }

        const stream = try netmod.connect(args[2], 9000);
        var writer = stream.writer();
        const username = args[3];

        const stdin = std.io.getStdIn().reader();
        var input_buf: [256]u8 = undefined;

        while (true) {
            std.debug.print("> ", .{});
            const line = try stdin.readUntilDelimiterOrEof(&input_buf, '\n');
            if (line == null) break;

            const msg = proto.Message.init(proto.MessageType.Chat, username, line.?);
            var buf: [289]u8 = undefined;
            msg.serialize(&buf);
            try writer.writeAll(&buf);
        }
    }
}

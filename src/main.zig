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
        const username = args[3];

        var input_buf: [256]u8 = undefined;

        while (true) {
            std.debug.print("> ", .{});

            const input_len = try std.posix.read(std.posix.STDIN_FILENO, &input_buf);
            if (input_len == 0) break;

            // Remove trailing newline if present
            const line = if (input_buf[input_len - 1] == '\n')
                input_buf[0 .. input_len - 1]
            else
                input_buf[0..input_len];

            const msg = proto.Message.init(proto.MessageType.Chat, username, line);
            var buf: [289]u8 = undefined;
            msg.serialize(&buf);
            _ = try stream.write(&buf);
        }
    }
}

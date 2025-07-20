const std = @import("std");
const net = std.net;
const thread = std.Thread;
const allocator = std.mem.allocator;
const print = std.debug.print;

const MAX_CLIENTS = 10;

var clients: [MAX_CLIENTS]?*net.Stream = [_]?*net.Stream{null} ** MAX_CLIENTS;
var clients_mutex = std.Thread.Mutex{};

fn broadcast(msg: []const u8, exclude: ?*net.Stream) void {
    clients_mutex.lock();
    defer clients_mutex.unlock();

    for (clients) |client_opt| {
        if (client_opt) |client| {
            if (client != exclude) {
                _ = client.writer().writeAll(msg) catch {};
            }
        }
    }
}

fn handle_client(stream: *net.Stream) void {
    var reader = stream.reader();
    const welcome = "Welcome to Zig Chat Server!\n";
    _ = stream.writer().writeAll(welcome) catch {};

    var buffer: [1024]u8 = undefined;

    while (true) {
        const msg = reader.readUntilDelimiterOrEof(&buffer, '\n') catch break;
        if (msg == null) break; // EOF
        broadcast(msg.?, stream);
    }

    // Remove client on disconnect
    clients_mutex.lock();
    defer clients_mutex.unlock();

    for (clients) |*slot| {
        if (slot.* == stream) {
            slot.* = null;
            break;
        }
    }
    stream.close();
}
pub fn main() !void {
    var address = try net.Address.parseIp("0.0.0.0", 9000);
    var listener = try address.listen(.{
        .reuse_address = true,
    });

    print("Chat server listening on 0.0.0.0:9000\n", .{});

    while (true) {
        var conn = try listener.accept();
        print("Client connected!\n", .{});
        var stream = &conn.stream;

        // Store client
        clients_mutex.lock();
        var stored = false;
        for (clients) |*slot| {
            if (slot.* == null) {
                slot.* = stream;
                stored = true;
                break;
            }
        }
        clients_mutex.unlock();

        if (!stored) {
            _ = stream.writer().writeAll("Server full!\n") catch {};
            stream.close();
            continue;
        }

        _ = try thread.spawn(.{}, handle_client, .{stream});
    }
}

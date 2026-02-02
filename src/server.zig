const std = @import("std");
const net = std.net;
const thread = std.Thread;
const print = std.debug.print;

const MAX_CLIENTS = 10;

const ClientConnection = struct {
    stream: net.Stream,
    address: net.Address,
    active: bool,
};

var clients: [MAX_CLIENTS]?*ClientConnection = [_]?*ClientConnection{null} ** MAX_CLIENTS;
var clients_mutex = std.Thread.Mutex{};
var allocator = std.heap.page_allocator;

fn broadcast(msg: []const u8, exclude: ?*ClientConnection) void {
    clients_mutex.lock();
    defer clients_mutex.unlock();

    for (clients) |client_opt| {
        if (client_opt) |client| {
            if (client != exclude and client.active) {
                _ = client.stream.write(msg) catch |err| {
                    print("Error broadcasting to client: {any}\n", .{err});
                };
            }
        }
    }
}

fn handle_client(conn: *ClientConnection) void {
    const welcome = "Welcome to Zig Chat Server!\n";
    _ = conn.stream.write(welcome) catch {
        cleanup_client(conn);
        return;
    };

    var buffer: [1024]u8 = undefined;

    while (conn.active) {
        const n = conn.stream.read(&buffer) catch |err| {
            print("Client read error: {any}\n", .{err});
            break;
        };

        if (n == 0) {
            print("Client disconnected\n", .{});
            break;
        }

        // Print received message to server console
        print("Received ({} bytes): {s}", .{ n, buffer[0..n] });

        // Broadcast to all other clients
        broadcast(buffer[0..n], conn);
    }

    cleanup_client(conn);
}

fn cleanup_client(conn: *ClientConnection) void {
    conn.active = false;

    // Remove client from list
    clients_mutex.lock();
    for (&clients) |*slot| {
        if (slot.*) |client| {
            if (client == conn) {
                slot.* = null;
                break;
            }
        }
    }
    clients_mutex.unlock();

    // Close the stream and free memory
    conn.stream.close();
    allocator.destroy(conn);
    print("Client cleaned up\n", .{});
}

pub fn main() !void {
    const address = try net.Address.parseIp("0.0.0.0", 9000);
    var listener = try address.listen(.{
        .reuse_address = true,
    });
    defer listener.deinit();

    print("Chat server listening on 0.0.0.0:9000\n", .{});

    while (true) {
        var conn_result = listener.accept() catch |err| {
            print("Accept error: {any}\n", .{err});
            continue;
        };

        print("Client connected from {any}\n", .{conn_result.address});

        // Allocate connection on heap so it persists beyond this scope
        var client_conn = allocator.create(ClientConnection) catch |err| {
            print("Failed to allocate client connection: {any}\n", .{err});
            conn_result.stream.close();
            continue;
        };

        client_conn.* = ClientConnection{
            .stream = conn_result.stream,
            .address = conn_result.address,
            .active = true,
        };

        // Store client
        clients_mutex.lock();
        var stored = false;
        for (&clients) |*slot| {
            if (slot.* == null) {
                slot.* = client_conn;
                stored = true;
                break;
            }
        }
        clients_mutex.unlock();

        if (!stored) {
            _ = client_conn.stream.write("Server full!\n") catch {};
            client_conn.stream.close();
            allocator.destroy(client_conn);
            print("Server full, rejected client\n", .{});
            continue;
        }

        // Spawn handler thread
        _ = thread.spawn(.{}, handle_client, .{client_conn}) catch |err| {
            print("Failed to spawn thread: {any}\n", .{err});
            cleanup_client(client_conn);
            continue;
        };
    }
}

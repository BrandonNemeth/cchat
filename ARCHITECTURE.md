# Architecture Documentation

## Overview

Zig TCP Chat is a minimal, local-first IRC-style chat application built with Zig. It uses a simple client-server architecture with TCP sockets for real-time message broadcasting.

## System Architecture

```
┌─────────────┐         ┌─────────────────────┐         ┌─────────────┐
│  Client 1   │         │                     │         │  Client 2   │
│             │◄───────►│   Chat Server       │◄───────►│             │
│  (Thread)   │   TCP   │   (Port 9000)       │   TCP   │  (Thread)   │
└─────────────┘         │                     │         └─────────────┘
                        │  ┌───────────────┐  │
                        │  │ Client List   │  │
      ┌─────────────┐   │  │ (Mutex)       │  │   ┌─────────────┐
      │  Client 3   │   │  └───────────────┘  │   │  Client N   │
      │             │◄──┤                     ├──►│             │
      │  (Thread)   │   │  Thread Pool:       │   │  (Thread)   │
      └─────────────┘   │  - Thread 1         │   └─────────────┘
                        │  - Thread 2         │
                        │  - Thread 3         │
                        │  - ...              │
                        └─────────────────────┘
```

## Components

### 1. Server (`src/server.zig`)

**Responsibilities:**
- Listen for incoming TCP connections on port 9000
- Accept and spawn handler threads for each client
- Maintain a thread-safe list of connected clients
- Broadcast messages from one client to all others

**Key Data Structures:**
```zig
var clients: [MAX_CLIENTS]?*net.Stream = [_]?*net.Stream{null} ** MAX_CLIENTS;
var clients_mutex = std.Thread.Mutex{};
```

**Flow:**
1. Bind to `0.0.0.0:9000`
2. Accept incoming connections in a loop
3. For each connection:
   - Store client stream in the array (mutex protected)
   - Spawn a handler thread
   - Send welcome message
4. Handler thread reads messages and broadcasts to other clients
5. On disconnect, remove client from list and close stream

**Thread Safety:**
- Uses `std.Thread.Mutex` to protect the shared client list
- Lock acquired during:
  - Adding new clients
  - Broadcasting messages
  - Removing disconnected clients

### 2. Client (`src/client.zig`)

**Responsibilities:**
- Connect to the chat server via TCP
- Spawn a receive thread for incoming messages
- Read from stdin and send to server

**Architecture:**
```
Main Thread              Receive Thread
    │                         │
    ├─ Connect to server      │
    ├─ Spawn receive thread ──┤
    │                         ├─ Read from socket
    ├─ Read from stdin        ├─ Print to stdout
    ├─ Write to socket        ├─ Loop...
    └─ Loop...                └─ On disconnect, exit
```

**Key Features:**
- Non-blocking receive using dedicated thread
- Simple stdin reading using `std.posix.read()`
- Direct socket I/O for minimal latency

### 3. Network Layer (`src/net.zig`)

**Utilities:**
- `connect(host, port)` - Create TCP client connection
- `bind_and_listen(port)` - Create TCP server listener

**Simple wrappers around `std.net`:**
```zig
pub fn connect(host: []const u8, port: u16) !net.Stream
pub fn bind_and_listen(port: u16) !net.Server
```

### 4. Protocol (`src/protocol.zig`)

**Message Format (289 bytes):**
```
┌──────────┬────────────────────┬─────────────────────────┐
│  Type    │     Username       │        Content          │
│  (1 B)   │     (32 B)         │        (256 B)          │
└──────────┴────────────────────┴─────────────────────────┘
```

**Message Types:**
- `Join = 1` - User joined the chat
- `Chat = 2` - Regular chat message
- `Leave = 3` - User left the chat

**Functions:**
- `init()` - Create a new message
- `serialize()` - Convert to binary format
- `deserialize()` - Parse from binary format

### 5. Library Entry Point (`src/root.zig`)

**Exports:**
- Public `net` module
- Public `protocol` module
- Test runner

## Data Flow

### Sending a Message

```
User types "Hello"
    │
    ▼
┌─────────────────────┐
│ stdin (STDIN_FILENO)│
└──────────┬──────────┘
           │ std.posix.read()
           ▼
    ┌─────────────┐
    │ Client Main │
    │   Thread    │
    └──────┬──────┘
           │ stream.write()
           ▼
    ╔══════════════╗
    ║ TCP Socket   ║
    ╚══════╤═══════╝
           │
           ▼
    ┌─────────────────┐
    │ Server Handler  │
    │    Thread       │
    └──────┬──────────┘
           │ broadcast()
           ▼
    ┌──────────────────────┐
    │ For each client:     │
    │  if client != sender │
    │    stream.write()    │
    └──────┬───────────────┘
           │
           ▼
    ╔══════════════╗
    ║ TCP Sockets  ║  (to other clients)
    ╚══════╤═══════╝
           │
           ▼
    ┌─────────────────┐
    │ Client Receive  │
    │    Thread       │
    └──────┬──────────┘
           │ stream.read()
           ▼
    ┌─────────────┐
    │   stdout    │
    │  (print)    │
    └─────────────┘
```

### Connection Lifecycle

```
Client                          Server
  │                               │
  ├─ Connect ──────────────────►  │
  │                               ├─ Accept
  │                               ├─ Add to client list
  │                               ├─ Spawn handler thread
  │  ◄───────── Welcome msg ──────┤
  │                               │
  ├─ Send msg ──────────────────► │
  │                               ├─ Broadcast to all
  │  ◄────── Msg from others ─────┤
  │                               │
  ├─ Disconnect ─────────────────►│
  │                               ├─ Remove from list
  │                               └─ Close stream
  └─ Exit
```

## Concurrency Model

### Server Threads

**Main Thread:**
- Accepts incoming connections
- Adds clients to the list
- Spawns handler threads

**Handler Threads (one per client):**
- Read from client socket
- Broadcast to other clients
- Handle disconnections

**Synchronization:**
- Shared state: `clients` array
- Protection: `clients_mutex`
- Lock duration: Minimal (only during list operations)

### Client Threads

**Main Thread:**
- Reads from stdin
- Writes to socket

**Receive Thread:**
- Reads from socket
- Prints to stdout
- Exits process on disconnect

## Build System

```
build.zig
    │
    ├─ Creates module: zchat (net.zig, protocol.zig)
    │
    ├─ Executable: zchat-server
    │   └─ Imports: zchat
    │
    ├─ Executable: zchat-client
    │   └─ Imports: zchat
    │
    └─ Executable: zchat (legacy)
        └─ Imports: zchat
```

## Memory Management

- **No dynamic allocation** in hot paths
- **Stack-allocated buffers** for I/O operations
- **Fixed-size client array** (MAX_CLIENTS = 10)
- **No memory leaks** - all resources cleaned up on exit

## Error Handling

**Philosophy:** Fail fast, log errors, clean up

**Server:**
- Connection errors: Log and continue accepting
- Client errors: Close connection, remove from list
- Broadcast errors: Silently ignore (client may have disconnected)

**Client:**
- Connection errors: Fatal, exit immediately
- Read errors: Disconnect and exit
- Write errors: Disconnect and exit

## Performance Characteristics

**Latency:**
- Minimal buffering (direct socket I/O)
- Message size: 289 bytes (protocol) or variable (raw)
- No message queuing

**Throughput:**
- Limited by TCP socket performance
- No artificial rate limiting
- Broadcasts to N-1 clients per message

**Scalability:**
- Max clients: 10 (configurable via MAX_CLIENTS)
- One thread per client + main thread
- Mutex contention minimal (only during list operations)

## Security Considerations

**This is a learning project - NOT production ready!**

**Current Vulnerabilities:**
- No authentication
- No encryption (plain TCP)
- No input validation
- No rate limiting
- Buffer overflow potential with malformed data
- No protection against malicious clients

**Future Improvements:**
- Add TLS support
- Implement authentication
- Add message size limits
- Rate limiting per client
- Input sanitization

## Design Decisions

### Why Direct Socket I/O?

**Pros:**
- Simplicity - easier to understand
- Lower latency - no buffering overhead
- Zig 0.15 compatibility - reader/writer API changed

**Cons:**
- Less idiomatic for high-level I/O
- Manual buffer management

### Why Thread-per-Client?

**Pros:**
- Simple concurrency model
- Easy to understand and debug
- Good for learning

**Cons:**
- Doesn't scale to thousands of clients
- Thread creation overhead

**Future:** Could migrate to async I/O or event loop

### Why Fixed Client Array?

**Pros:**
- No dynamic allocation
- Predictable memory usage
- Simple implementation

**Cons:**
- Hard limit on clients
- Wasted memory if slots unused

**Future:** Could use ArrayList or custom pool

## Testing Strategy

**Unit Tests:**
- Protocol serialization/deserialization
- Network utility functions

**Integration Tests:**
- Server accepts connections
- Messages broadcast correctly
- Client cleanup on disconnect

**Manual Tests:**
- Use `demo.sh` for live testing
- Multiple terminals for multi-client scenarios

## Deployment

**Development:**
```bash
zig build
./zig-out/bin/zchat-server
```

**Production:**
```bash
zig build -Doptimize=ReleaseFast
sudo make install  # Installs to /usr/local/bin
```

**Cross-compilation:**
```bash
zig build -Dtarget=aarch64-linux  # For Raspberry Pi
zig build -Dtarget=x86_64-windows
```

## Future Architecture Considerations

### Async I/O Migration

```
Current: Thread-per-client
Future:  Event loop with io_uring/epoll

Benefits:
- Scale to 1000+ clients
- Lower memory overhead
- Better CPU utilization
```

### Message Queue

```
Current: Direct broadcast
Future:  Message queue per client

Benefits:
- Decouple send/receive
- Handle slow clients better
- Enable message history
```

### Database Integration

```
Future: SQLite for persistence
- Message history
- User accounts
- Channel support
```

## Conclusion

This architecture prioritizes **simplicity** and **learning** over production-readiness. It demonstrates core networking concepts, threading, and Zig's standard library while maintaining readable, maintainable code.

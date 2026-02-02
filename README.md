# [WARNING VIBE CODING SLOP] 


##  Zig TCP Chat

A minimal multiclient chat application written in [Zig](https://ziglang.org/), designed for simplicity, speed, and learning network fundamentals.

##  Features

- **CLI-based chat** using TCP sockets
- **Server supports multiple clients** via threads
- **Broadcast messages** to all connected clients
- **Custom binary message protocol** (in legacy mode)
- **Clean modular structure** (`server.zig`, `client.zig`, `net.zig`, `protocol.zig`)
- **Cross-platform**: Linux, Raspberry Pi, macOS

##  Requirements

- Zig v0.15.0 or newer

##  Build

Build all executables (server, client, and legacy):
```sh
zig build
```

The compiled binaries will be in `zig-out/bin/`:
- `zchat-server` - The chat server
- `zchat-client` - The chat client
- `zchat` - Legacy combined server/client

##  Usage

### Start the Server

In one terminal:
```sh
zig build server
# Or run the compiled binary directly:
./zig-out/bin/zchat-server
```

The server will listen on `0.0.0.0:9000`

### Connect Clients

In other terminals:
```sh
zig build client -- 127.0.0.1 9000
# Or run the compiled binary directly:
./zig-out/bin/zchat-client 127.0.0.1 9000
```

Now type messages and they'll be broadcast to all connected clients!

### Quick Test

Run the automated test to see the chat in action:
```sh
./test_chat.sh
```

This will start a server and two clients (Alice and Bob) that exchange messages, demonstrating the broadcast functionality.

### Legacy Mode

The legacy `zchat` binary supports the old protocol-based mode:

**Server:**
```shA minimal multiclient chat application written in Zig, designed for simplicity, speed, and learning network fundamentals.
./zig-out/bin/zchat server
```

**Client:**
```sh
./zig-out/bin/zchat client <host> <username>
```



##  Testing
## 🧪 Testing

### Unit Tests

Run the unit test suite:
```sh
zig build test
```

### Integration Test

Run the automated chat test to verify message broadcasting works:
```sh
./test_chat.sh
```

This script will:
1. Start a server
2. Connect two clients (Alice and Bob)
3. Have them exchange messages
4. Verify that messages are broadcast correctly
5. Show you what each client sees

**Expected output:** ✅ Both clients should see each other's messages!

##  TODO / Future Enhancements

- [x] Broadcast messages to all connected clients
- [x] Split into modules: `client.zig`, `server.zig`, etc.
- [ ] Add `/exit` command for clean disconnection
- [ ] Add support for usernames and `/name <newname>` change
- [ ] Support private messages (e.g., `/msg bob hi`)
- [ ] Timestamp messages
- [ ] Add colored terminal output (username, prompt, etc.)
- [ ] Log messages server-side to a file
- [ ] Configurable port and address via CLI args
- [ ] Kick or mute users via server commands
- [ ] Graceful shutdown with signal handling (e.g., Ctrl+C)
- [ ] Switch to async I/O using Zig's event loop or polling model
- [ ] Better error handling and connection recovery
- [ ] Message history/scrollback
- [ ] TLS/SSL encryption support


## 🎓 Learning Goals

- Understand how TCP sockets work using Zig's standard library
- Design and implement a simple binary protocol for messaging
- Explore multithreading and shared state management (with `Mutex`)
- Practice safe memory management using Zig's allocator model
- Build CLI-first applications for learning systems programming
- Experiment with Raspberry Pi deployment and cross-compilation
- Learn Zig's build system and module structure

## 🏗️ Project Structure

```
cchat/
├── build.zig          # Build configuration
├── src/
│   ├── root.zig       # Library entry point
│   ├── server.zig     # Multi-client chat server
│   ├── client.zig     # Chat client with receive thread
│   ├── main.zig       # Legacy combined binary
│   ├── net.zig        # Network utilities
│   └── protocol.zig   # Message protocol definitions
└── zig-out/bin/       # Compiled binaries
```

## 🐛 Troubleshooting

**Port already in use:**
```sh
# Find and kill the process using port 9000
lsof -ti:9000 | xargs kill -9
```

**Connection refused:**
- Make sure the server is running first
- Check firewall settings
- Verify you're connecting to the correct host/port

##  License

This is a learning project. Feel free to use, modify, and distribute as you see fit!

#  Zig TCP Chat

A minimal multiclient chat application written in [Zig](https://ziglang.org/), designed for simplicity, speed, and learning network fundamentals.

##  Features

- CLI-based chat using TCP sockets
- Server supports multiple clients via threads
- Custom binary message protocol
- Clean modular structure (`main.zig`, `protocol.zig`, `net.zig`)
- Cross-platform: Linux, Raspberry Pi, macOS



##  Build

You must have Zig installed (v0.11.0 or newer recommended). Then:
```sh
zig build-exe main.zig -I . --name chat -O Debug
```



## TODO / Future Enhancements

- [ ] Broadcast messages to all connected clients
- [ ] Add `/exit` command for clean disconnection
- [ ] Add support for dynamic `/name <newname>` change
- [ ] Support private messages (e.g., `/msg bob hi`)
- [ ] Timestamp messages
- [ ] Add colored terminal output (username, prompt, etc.)
- [ ] Log messages server-side to a file
- [ ] Configurable port and address via CLI args
- [ ] Kick or mute users via server commands
- [ ] Graceful shutdown with signal handling (e.g., Ctrl+C)
- [ ] Switch to async I/O using Zig’s `AsyncFrame` or polling model
- [ ] Split into modules: `client.zig`, `server.zig`, `config.zig`, etc.


## Learning Goals

- Understand how TCP sockets work using Zig’s standard library
- Design and implement a simple binary protocol for messaging
- Explore multithreading and shared state management (with `Mutex`)
- Practice safe memory management using Zig’s allocator model
- Build CLI-first applications for learning systems programming
- Experiment with Raspberry Pi deployment and cross-compilation

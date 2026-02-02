.PHONY: all build server client run-server run-client clean test help demo

# Default target
all: build

# Build all targets
build:
	@echo "🔨 Building Zig TCP Chat..."
	zig build

# Build and run the server
server:
	@echo "🚀 Starting chat server..."
	zig build server

# Build and run the client (use: make client HOST=127.0.0.1 PORT=9000)
client:
	@echo "💬 Starting chat client..."
	@if [ -z "$(HOST)" ]; then \
		echo "Usage: make client HOST=<host> PORT=<port>"; \
		echo "Example: make client HOST=127.0.0.1 PORT=9000"; \
		exit 1; \
	fi
	zig build client -- $(HOST) $(PORT)

# Run the server directly from binary
run-server: build
	@echo "🚀 Running chat server..."
	./zig-out/bin/zchat-server

# Run the client directly from binary (use: make run-client HOST=127.0.0.1 PORT=9000)
run-client: build
	@echo "💬 Running chat client..."
	@if [ -z "$(HOST)" ]; then \
		echo "Usage: make run-client HOST=<host> PORT=<port>"; \
		echo "Example: make run-client HOST=127.0.0.1 PORT=9000"; \
		exit 1; \
	fi
	./zig-out/bin/zchat-client $(HOST) $(PORT)

# Run tests
test:
	@echo "🧪 Running tests..."
	zig build test

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -rf zig-out .zig-cache
	@echo "✨ Clean complete!"

# Run the demo script
demo: build
	@./demo.sh

# Install binaries to /usr/local/bin (requires sudo)
install: build
	@echo "📦 Installing binaries to /usr/local/bin..."
	@sudo cp zig-out/bin/zchat-server /usr/local/bin/
	@sudo cp zig-out/bin/zchat-client /usr/local/bin/
	@sudo cp zig-out/bin/zchat /usr/local/bin/
	@echo "✅ Installation complete!"

# Uninstall binaries
uninstall:
	@echo "🗑️  Uninstalling binaries..."
	@sudo rm -f /usr/local/bin/zchat-server
	@sudo rm -f /usr/local/bin/zchat-client
	@sudo rm -f /usr/local/bin/zchat
	@echo "✅ Uninstallation complete!"

# Show help
help:
	@echo "Zig TCP Chat - Makefile Commands"
	@echo "=================================="
	@echo ""
	@echo "Build commands:"
	@echo "  make build        - Build all executables"
	@echo "  make clean        - Remove build artifacts"
	@echo ""
	@echo "Run commands:"
	@echo "  make server       - Build and run server"
	@echo "  make client HOST=<host> PORT=<port>"
	@echo "                    - Build and run client"
	@echo "  make run-server   - Run pre-built server"
	@echo "  make run-client HOST=<host> PORT=<port>"
	@echo "                    - Run pre-built client"
	@echo ""
	@echo "Test & Demo:"
	@echo "  make test         - Run test suite"
	@echo "  make demo         - Run demo script"
	@echo ""
	@echo "Install:"
	@echo "  make install      - Install to /usr/local/bin (requires sudo)"
	@echo "  make uninstall    - Remove from /usr/local/bin (requires sudo)"
	@echo ""
	@echo "Examples:"
	@echo "  make server"
	@echo "  make client HOST=127.0.0.1 PORT=9000"
	@echo "  make demo"

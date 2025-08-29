# Network Server Example

A multi-client TCP chat server demonstrating socket programming on RISC-V hardware.

## Overview

This example demonstrates:
- TCP socket programming on RISC-V
- Multi-client chat server architecture
- Concurrent connection handling
- Command processing and messaging
- Graceful server shutdown
- Cross-compilation for embedded systems

## Features

- **Multi-client support**: Handle multiple simultaneous connections
- **Chat functionality**: Real-time messaging between clients
- **Command system**: Built-in commands (help, time, clients, quit)
- **Connection management**: Automatic client registration/disconnection
- **Broadcast messaging**: Send messages to all connected clients
- **System information**: Display board and architecture details

## Building

### Method 1: Using the main Makefile
```bash
cd /path/to/riscv-dev-standalone
make build-example-network-server
```

### Method 2: Direct compilation
```bash
cd examples/network-server
GOOS=linux GOARCH=riscv64 CGO_ENABLED=0 go build -o ../../bin/network-server/app ./cmd/app
```

## Running

### On RISC-V Hardware
```bash
# Copy to your RISC-V board
scp bin/network-server/app user@riscv-board:/tmp/

# Run on the board
ssh user@riscv-board
sudo /tmp/network-server/app
```

### Using QEMU User-Mode Emulation
```bash
# From the development environment
qemu-riscv64 bin/network-server/app
```

## Connecting to the Server

### Using Telnet
```bash
telnet localhost 8080
```

### Using Netcat
```bash
nc localhost 8080
```

### Using SSH (remote access)
```bash
ssh user@riscv-board
telnet localhost 8080
```

## Expected Output

### Server Startup
```
🌐 RISC-V Network Server Example
Go version: Go 1.21+ (cross-compiled for RISC-V)
Architecture: RISC-V 64-bit (RV64GC)
Server will listen on port 8080

🚀 Starting RISC-V Network Server
Board: Milk-V Duo
Listening on: 0.0.0.0:8080
Server type: tcp
✅ Server started successfully!
💡 Try connecting with: telnet localhost 8080
💡 Or use: nc localhost 8080
```

### Client Connection
```
📡 New connection from: 127.0.0.1:45678
👤 Client 'Alice' (127.0.0.1:45678) joined
📢 Alice joined the chat
```

### Chat Session Example
```
Welcome to RISC-V Network Server!
Server time: 2024-01-15T10:30:45Z
Type 'help' for commands.

Enter your name: Alice

[10:30:47] Alice: Hello everyone!
[10:30:52] Bob: Hi Alice! Welcome to the RISC-V chat server.
[10:31:01] Alice: This is running on RISC-V hardware!
```

## Available Commands

| Command | Description |
|---------|-------------|
| `help` | Show available commands |
| `time` | Get current server time |
| `clients` | List all connected clients |
| `quit` | Disconnect from server |
| `<text>` | Send message to all clients |

## Configuration

### Changing the Port

Edit the constants in `main.go`:

```go
const (
    SERVER_HOST = "0.0.0.0"  // Listen on all interfaces
    SERVER_PORT = "8080"     // Change this to your desired port
    SERVER_TYPE = "tcp"
)
```

### Network Interface

- `0.0.0.0`: Listen on all network interfaces
- `127.0.0.1`: Listen only on localhost
- Specific IP: Listen only on that interface

## Architecture

The server uses a concurrent design with goroutines:

1. **Main goroutine**: Accepts new connections
2. **Connection handlers**: One per client connection
3. **Message broadcaster**: Handles message distribution
4. **Signal handler**: Manages graceful shutdown

## Troubleshooting

### Connection Refused
- Ensure the server is running
- Check firewall settings
- Verify the correct port number

### Permission Denied
```bash
# For ports below 1024, you may need root privileges
sudo ./network-server/app
```

### Network Interface Issues
```bash
# Check available network interfaces
ip addr show

# Test connectivity
ping <server-ip>
```

## Performance Considerations

- **Memory usage**: ~8KB per client connection
- **CPU usage**: Minimal for typical chat workloads
- **Network latency**: Depends on hardware and network conditions
- **Concurrent connections**: Tested with up to 100 simultaneous clients

## Security Notes

This is a demonstration server with minimal security:
- No authentication required
- Plain text communication
- No encryption
- For production use, consider adding TLS and authentication

## Dependencies

- **Standard library only**: No external dependencies
- Uses `net`, `bufio`, `os`, `strings`, `time`, `log` packages

## Next Steps

- Add TLS encryption
- Implement user authentication
- Add private messaging
- Create web-based client interface
- Add message persistence

## Related Examples

- [GPIO LED](../gpio-led/) - Hardware GPIO control
- [Sensor Reading](../sensor-reading/) - ADC interface
- [Buildroot App](../buildroot-app/) - Buildroot integration

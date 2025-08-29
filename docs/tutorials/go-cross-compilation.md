# Go Cross-Compilation for RISC-V

This tutorial covers cross-compiling Go applications for RISC-V embedded systems, including build optimization, debugging, and deployment strategies.

## Table of Contents

- [Cross-Compilation Basics](#cross-compilation-basics)
- [Environment Setup](#environment-setup)
- [Build Configuration](#build-configuration)
- [Optimization Techniques](#optimization-techniques)
- [Debugging Cross-Compiled Binaries](#debugging-cross-compiled-binaries)
- [Deployment and Testing](#deployment-and-testing)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Cross-Compilation Basics

### What is Cross-Compilation?

Cross-compilation is building software on one platform (host) to run on a different platform (target). For RISC-V:

- **Host**: Your development machine (x86_64, ARM64, etc.)
- **Target**: RISC-V 64-bit Linux systems
- **Result**: Executable that runs on RISC-V hardware

### Why Cross-Compile for RISC-V?

- **Performance**: RISC-V devices often have limited resources
- **Compatibility**: Native compilation on target devices may be impractical
- **Development Speed**: Faster builds on powerful development machines

## Environment Setup

### Required Tools

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install golang-go  # Go 1.19+ required for riscv64

# Verify Go version
go version  # Should be 1.19 or later
```

### Environment Variables

Set these for RISC-V cross-compilation:

```bash
export GOOS=linux        # Target operating system
export GOARCH=riscv64    # Target architecture
export CGO_ENABLED=0     # Disable CGO for static binaries
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
```

### Persistent Configuration

Add to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
# RISC-V Go Cross-Compilation
export GOOS=linux
export GOARCH=riscv64
export CGO_ENABLED=0
```

## Build Configuration

### Basic Cross-Compilation

```bash
# Simple build
go build -o myapp main.go

# With explicit variables
GOOS=linux GOARCH=riscv64 go build -o myapp main.go

# Build all packages
go build ./...
```

### Build Flags and Optimization

```bash
# Optimized build for embedded systems
go build \
  -ldflags="-s -w" \
  -gcflags="all=-l -B" \
  -trimpath \
  -o myapp \
  main.go

# Explanation of flags:
# -s: Omit symbol table
# -w: Omit DWARF debug info
# -l: Disable inlining
# -B: Disable bounds checking
# -trimpath: Remove file system paths from binary
```

### Multi-Platform Builds

```bash
# Build for multiple architectures
architectures=("amd64" "arm64" "riscv64")
for arch in "${architectures[@]}"; do
    echo "Building for $arch..."
    GOOS=linux GOARCH=$arch go build \
      -ldflags="-s -w" \
      -o "myapp-$arch" \
      main.go
done
```

### Module-Aware Builds

```bash
# With Go modules
go mod tidy
go build -o bin/riscv-app ./cmd/app

# Cross-compile with modules
GOOS=linux GOARCH=riscv64 go build -o bin/riscv-app ./cmd/app
```

## Optimization Techniques

### Binary Size Optimization

```bash
# Minimal binary size
go build \
  -ldflags="-s -w -buildid=" \
  -gcflags="all=-l -B" \
  -asmflags="all=-l" \
  -trimpath \
  -o minimal-app \
  main.go

# Typical size reduction: 2-3x smaller
```

### Performance Optimization

```bash
# Performance-optimized build
go build \
  -ldflags="-s" \
  -gcflags="all=-l=4" \
  -o fast-app \
  main.go

# Flags explanation:
# -l=4: Aggressive inlining
# Keep debug symbols (-s not -w) for profiling
```

### Memory Optimization

```go
// main.go - Memory-efficient patterns
package main

import (
    "runtime"
    "time"
)

func main() {
    // Set GOMAXPROCS for single-core RISC-V
    runtime.GOMAXPROCS(1)

    // Force garbage collection periodically
    go func() {
        for {
            time.Sleep(30 * time.Second)
            runtime.GC()
        }
    }()

    // Your application code here
}
```

### Static Linking

```bash
# Ensure static linking (no dynamic dependencies)
GOOS=linux GOARCH=riscv64 CGO_ENABLED=0 go build \
  -ldflags="-extldflags=-static" \
  -o static-app \
  main.go

# Verify static linking
file static-app
# Should show: "statically linked"
```

## Debugging Cross-Compiled Binaries

### Remote Debugging Setup

```bash
# 1. Build with debug symbols
go build \
  -ldflags="-X main.version=debug" \
  -gcflags="all=-N -l" \
  -o debug-app \
  main.go

# 2. Copy to target and run
scp debug-app user@riscv-board:/tmp/
ssh user@riscv-board gdbserver :2345 /tmp/debug-app

# 3. Debug from host
gdb-multiarch debug-app
(gdb) target remote riscv-board:2345
(gdb) break main.main
(gdb) continue
```

### Delve Debugger Setup

```bash
# Install Delve
go install github.com/go-delve/delve/cmd/dlv@latest

# Remote debugging
dlv connect riscv-board:2345
```

### Logging and Debugging

```go
// debug.go - Debug utilities
package main

import (
    "fmt"
    "os"
    "runtime"
    "strconv"
)

func init() {
    // Enable debug mode
    if os.Getenv("DEBUG") == "1" {
        fmt.Printf("Debug: RISC-V App v%s\n", getVersion())
        fmt.Printf("Debug: CPU Cores: %d\n", runtime.NumCPU())
        fmt.Printf("Debug: Architecture: %s\n", runtime.GOARCH)
    }
}

func getVersion() string {
    if v := os.Getenv("APP_VERSION"); v != "" {
        return v
    }
    return "dev"
}
```

## Deployment and Testing

### Local Testing with QEMU

```bash
# User-mode emulation (fast)
qemu-riscv64 ./myapp

# System emulation (full environment)
qemu-system-riscv64 \
  -M virt \
  -m 512M \
  -kernel ./myapp \
  -nographic \
  -append "console=ttyS0"
```

### Remote Deployment

```bash
# Build and deploy
GOOS=linux GOARCH=riscv64 go build -o riscv-app main.go
scp riscv-app user@riscv-board:/usr/local/bin/
ssh user@riscv-board chmod +x /usr/local/bin/riscv-app

# Test on target
ssh user@riscv-board /usr/local/bin/riscv-app
```

### Buildroot Integration

```bash
# Copy to Buildroot overlay
cp riscv-app /path/to/buildroot/overlay/usr/bin/

# Buildroot will include it in the final image
cd /path/to/buildroot
make
```

## Advanced Topics

### Conditional Compilation

```go
// +build riscv64

package main

import "fmt"

func init() {
    fmt.Println("Running on RISC-V 64-bit")
}
```

### Build Tags

```go
//go:build riscv64 && linux

package riscv

// RISC-V specific code
func getArchInfo() string {
    return "RISC-V 64-bit Linux"
}
```

### Assembly Integration

```go
// Use Go assembly for performance-critical sections
// File: asm_riscv64.s
TEXT ·Add(SB),NOSPLIT,$0
    MOVD a+0(FP), R8
    MOVD b+8(FP), R9
    ADD R8, R9, R10
    MOVD R10, ret+16(FP)
    RET
```

### CGO Integration (Advanced)

```go
// +build cgo

package main

/*
#include <stdio.h>
void hello() {
    printf("Hello from C!\n");
}
*/
import "C"

func main() {
    C.hello()
}
```

**Note**: CGO requires native compilation on RISC-V target.

### Plugin System

```go
// plugin.go - Runtime plugin loading
package main

import (
    "plugin"
)

func loadPlugin(path string) {
    p, err := plugin.Open(path)
    if err != nil {
        panic(err)
    }

    sym, err := p.Lookup("Init")
    if err != nil {
        panic(err)
    }

    initFunc := sym.(func())
    initFunc()
}
```

## Troubleshooting

### Common Issues

#### 1. "unknown architecture riscv64"

**Problem**: Go version too old

**Solution**:
```bash
go version  # Must be 1.19+
# Update Go if needed
```

#### 2. "undefined reference to `__stack_chk_fail`"

**Problem**: Stack protection issues

**Solution**:
```bash
# Disable stack protection
go build -ldflags="-extldflags=-z noexecstack" main.go
```

#### 3. "relocation truncated to fit"

**Problem**: Binary too large

**Solution**:
```bash
# Use position-independent code
go build -ldflags="-extldflags=-fPIC" main.go
```

#### 4. "illegal instruction" on target

**Problem**: Architecture mismatch

**Solution**:
```bash
# Verify target architecture
uname -m  # Should show riscv64
file ./myapp  # Should show RISC-V
```

### Performance Issues

#### Slow Startup
```go
# Pre-compile regular expressions
var emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)

# Use sync.Pool for object reuse
var bufferPool = sync.Pool{
    New: func() interface{} {
        return make([]byte, 4096)
    },
}
```

#### Memory Usage
```go
# Force garbage collection
runtime.GC()

# Set memory limits
debug.SetMemoryLimit(50 * 1024 * 1024) // 50MB
```

### Debugging Tips

#### Print Debugging
```go
import (
    "fmt"
    "os"
    "runtime"
)

func debugPrint(msg string) {
    if os.Getenv("DEBUG") == "1" {
        _, file, line, ok := runtime.Caller(1)
        if ok {
            fmt.Printf("[DEBUG] %s:%d: %s\n", file, line, msg)
        }
    }
}
```

#### Performance Profiling
```bash
# Build with profiling
go build -ldflags="-X main.profile=1" main.go

# Run with profiling
./myapp &
go tool pprof http://localhost:8080/debug/pprof/profile
```

## Best Practices

### Code Organization

```go
// Recommended structure
myapp/
├── cmd/
│   └── app/
│       └── main.go          # Application entry point
├── internal/
│   ├── config/             # Configuration
│   ├── hardware/           # Hardware interfaces
│   └── services/           # Business logic
├── pkg/                    # Reusable packages
├── go.mod
└── Makefile
```

### Build Automation

```makefile
# Makefile for cross-compilation
.PHONY: build clean deploy

build:
    GOOS=linux GOARCH=riscv64 CGO_ENABLED=0 go build \
      -ldflags="-s -w" \
      -o bin/riscv-app \
      ./cmd/app

clean:
    rm -rf bin/

deploy: build
    scp bin/riscv-app user@riscv-board:/usr/local/bin/
```

### Version Management

```go
// version.go
package main

var (
    Version   = "dev"
    BuildTime = "unknown"
    GitCommit = "unknown"
)

func getBuildInfo() string {
    return fmt.Sprintf("Version: %s, Built: %s, Commit: %s",
        Version, BuildTime, GitCommit)
}
```

## Resources

- [Go Cross-Compilation Guide](https://golang.org/doc/install/source#environment)
- [RISC-V Go Port](https://github.com/golang/go/wiki/RISC-V)
- [Go Build Constraints](https://golang.org/pkg/go/build/#hdr-Build_Constraints)
- [Delve Debugger](https://github.com/go-delve/delve)

## Next Steps

1. **Experiment**: Try building the examples in this repository
2. **Profile**: Use `go tool pprof` to optimize performance
3. **Test**: Deploy to real RISC-V hardware
4. **Extend**: Add your own hardware interfaces

For more examples, see the [examples](../examples/) directory in this repository.

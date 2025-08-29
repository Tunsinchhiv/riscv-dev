# QEMU Emulation Workflows for RISC-V

This guide covers using QEMU for RISC-V development, including emulation modes, debugging, networking, and performance optimization for embedded systems development.

## Table of Contents

- [QEMU Overview](#qemu-overview)
- [Installation and Setup](#installation-and-setup)
- [Emulation Modes](#emulation-modes)
- [Basic Usage](#basic-usage)
- [Debugging with QEMU](#debugging-with-qemu)
- [Networking](#networking)
- [Performance Optimization](#performance-optimization)
- [Advanced Workflows](#advanced-workflows)
- [Troubleshooting](#troubleshooting)

## QEMU Overview

### What is QEMU?

QEMU is a generic machine emulator and virtualizer that can emulate RISC-V processors and peripherals, making it ideal for:

- **Cross-platform development** without physical hardware
- **Rapid testing** of applications and kernels
- **Debugging** with full system visibility
- **CI/CD integration** for automated testing
- **Learning RISC-V** architecture and programming

### QEMU for RISC-V

QEMU supports multiple RISC-V configurations:

- **User-mode emulation**: `qemu-riscv64` - Fast application testing
- **System emulation**: `qemu-system-riscv64` - Full system simulation
- **Architectures**: RV32, RV64 with various extensions (GC, etc.)
- **Machines**: `virt` (generic), `spike` (SiFive), custom boards

### When to Use QEMU

**Best for:**
- ✅ Application development and testing
- ✅ Kernel and driver development
- ✅ CI/CD pipelines
- ✅ Learning and experimentation
- ✅ Multi-platform compatibility testing

**Not ideal for:**
- ❌ Real-time performance measurement
- ❌ Hardware-specific peripheral testing
- ❌ Power consumption analysis
- ❌ Production deployment

## Installation and Setup

### Ubuntu/Debian

```bash
# Install QEMU
sudo apt-get update
sudo apt-get install qemu-system-riscv64 qemu-user

# Install additional tools
sudo apt-get install qemu-system-gui qemu-utils

# Verify installation
qemu-system-riscv64 --version
qemu-riscv64 --version
```

### Fedora/RHEL

```bash
# Install QEMU
sudo dnf install qemu-system-riscv qemu-user-riscv
sudo dnf install qemu-system-gui qemu-img

# Verify
qemu-system-riscv64 --version
```

### macOS (Homebrew)

```bash
# Install QEMU
brew install qemu

# Verify
qemu-system-riscv64 --version
```

### Windows (WSL2)

```bash
# Inside WSL2 Ubuntu
sudo apt-get install qemu-system-riscv64 qemu-user
```

### Dev Container (Recommended)

The repository includes a dev container with QEMU pre-configured:

```bash
# In VS Code
# Ctrl+Shift+P → "Dev Containers: Reopen in Container"
# QEMU is ready to use
```

## Emulation Modes

### User-Mode Emulation

Fastest mode for testing individual applications:

```bash
# Basic usage
qemu-riscv64 ./my-riscv-app

# With arguments
qemu-riscv64 ./my-app arg1 arg2

# With environment variables
qemu-riscv64 -E MY_VAR=value ./my-app
```

**Use cases:**
- Unit testing of applications
- Performance benchmarking
- Quick iteration during development
- CI/CD pipelines

### System-Mode Emulation

Full system simulation with kernel and peripherals:

```bash
# Basic system emulation
qemu-system-riscv64 \
  -M virt \                    # Machine type
  -m 512M \                    # Memory
  -kernel ./my-kernel \        # Kernel image
  -initrd ./rootfs.cpio \      # Initial ramdisk
  -append "console=ttyS0" \    # Kernel arguments
  -nographic                   # No GUI

# With disk image
qemu-system-riscv64 \
  -M virt \
  -m 1G \
  -drive file=./disk.img,format=raw,if=virtio \
  -nographic
```

**Use cases:**
- Full system testing
- Kernel development
- Bootloader testing
- Device driver development

### SMP (Multi-core) Emulation

```bash
# Multi-core RISC-V system
qemu-system-riscv64 \
  -M virt \
  -m 2G \
  -smp 4 \                     # 4 CPU cores
  -kernel ./linux \
  -append "console=ttyS0 root=/dev/vda" \
  -drive file=./rootfs.ext4,format=raw,id=hd0,if=virtio \
  -nographic
```

## Basic Usage

### Testing Repository Examples

```bash
# Build examples
make build-examples

# Test GPIO example (fastest)
make run-example-gpio-led

# Or manually
qemu-riscv64 bin/examples/gpio-led/app
```

### Custom Application Testing

```bash
# Build your application
GOOS=linux GOARCH=riscv64 go build -o my-app main.go

# Test with QEMU
qemu-riscv64 ./my-app

# With arguments
qemu-riscv64 ./my-app --config=config.yaml
```

### Bootable System Images

```bash
# Using Buildroot-generated image
qemu-system-riscv64 \
  -M virt \
  -m 512M \
  -kernel output/images/Image \
  -drive file=output/images/rootfs.ext4,format=raw,if=virtio \
  -append "console=ttyS0 root=/dev/vda rw" \
  -nographic
```

## Debugging with QEMU

### Remote GDB Debugging

```bash
# Start QEMU with GDB server
qemu-system-riscv64 \
  -M virt \
  -m 512M \
  -kernel ./my-app \
  -s \                          # GDB server on port 1234
  -S                            # Wait for GDB connection

# Connect with GDB
gdb-multiarch ./my-app
(gdb) target remote localhost:1234
(gdb) break main.main
(gdb) continue
```

### Application Debugging

```bash
# Debug user-space application
qemu-riscv64 -g 2345 ./my-app &
gdb-multiarch ./my-app
(gdb) target remote localhost:2345
```

### Kernel Debugging

```bash
# Debug kernel with symbols
qemu-system-riscv64 \
  -M virt \
  -m 512M \
  -kernel vmlinux \            # Kernel with symbols
  -s \                         # GDB server
  -S                           # Wait for debugger

# Attach debugger
gdb-multiarch vmlinux
(gdb) target remote localhost:1234
(gdb) break start_kernel
(gdb) continue
```

### VS Code Integration

Add to `.vscode/launch.json`:

```json
{
    "name": "Debug RISC-V App",
    "type": "go",
    "request": "launch",
    "mode": "remote",
    "remotePath": "",
    "port": 2345,
    "host": "localhost",
    "program": "${workspaceFolder}/bin/my-app",
    "preLaunchTask": "Start QEMU Debug"
}
```

## Networking

### Host-Only Networking

```bash
# Default networking (user mode)
qemu-system-riscv64 \
  -M virt \
  -m 512M \
  -kernel ./linux \
  -net nic,model=virtio \
  -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80
```

### Bridge Networking

```bash
# Bridge to host network
sudo qemu-system-riscv64 \
  -M virt \
  -m 512M \
  -kernel ./linux \
  -net nic,model=virtio \
  -net bridge,br=br0
```

### Network Testing

```bash
# Test network connectivity
qemu-system-riscv64 \
  -M virt \
  -m 512M \
  -kernel ./linux \
  -net nic,model=virtio \
  -net user \
  -nographic

# Inside QEMU:
ping 10.0.2.2                    # Host IP
curl http://10.0.2.2:8080        # Host service
```

### Port Forwarding

```bash
# Forward ports for development
qemu-system-riscv64 \
  -M virt \
  -m 512M \
  -net user,\
hostfwd=tcp::2222-:22,\
hostfwd=tcp::8080-:80,\
hostfwd=tcp::2345-:2345
```

## Performance Optimization

### User-Mode Optimization

```bash
# Fast user-mode execution
qemu-riscv64 \
  -cpu max \                     # Maximum CPU features
  -one-insn-per-tb \            # Optimize translation blocks
  ./my-app
```

### System-Mode Optimization

```bash
# Optimized system emulation
qemu-system-riscv64 \
  -M virt \
  -m 1G \
  -smp 2 \                      # Multiple cores
  -cpu rv64,v=true,vlen=128 \   # Vector extensions
  -accel tcg,thread=multi \     # Multi-threaded TCG
  -kernel ./linux \
  -nographic
```

### KVM Acceleration (Linux)

```bash
# Use KVM for better performance
qemu-system-riscv64 \
  -M virt \
  -accel kvm \                  # KVM acceleration
  -cpu host \                   # Host CPU features
  -kernel ./linux
```

### Memory Optimization

```bash
# Optimize memory usage
qemu-system-riscv64 \
  -M virt,acpi=off \           # Disable ACPI
  -m 512M,size=1G,slots=2 \    # Memory configuration
  -kernel ./linux
```

### Disk I/O Optimization

```bash
# Fast disk I/O
qemu-system-riscv64 \
  -M virt \
  -drive file=./disk.img,if=virtio,cache=writeback,aio=threads \
  -kernel ./linux
```

## Advanced Workflows

### Automated Testing

```bash
# Test script
#!/bin/bash
echo "Building application..."
GOOS=linux GOARCH=riscv64 go build -o test-app main.go

echo "Testing with QEMU..."
timeout 30 qemu-riscv64 ./test-app > test_output.log 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Test passed"
else
    echo "❌ Test failed"
    cat test_output.log
    exit 1
fi
```

### CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Test with QEMU
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup QEMU
        run: |
          sudo apt-get update
          sudo apt-get install qemu-user
      - name: Build
        run: GOOS=linux GOARCH=riscv64 go build -o app main.go
      - name: Test
        run: qemu-riscv64 ./app --test
```

### Development Workflow

```bash
# Development cycle
while true; do
    # Build
    GOOS=linux GOARCH=riscv64 go build -o app main.go

    # Test
    qemu-riscv64 ./app

    # Wait for changes
    inotifywait -e modify *.go
done
```

### Multi-Architecture Testing

```bash
# Test on different architectures
architectures=("riscv64" "amd64" "arm64")

for arch in "${architectures[@]}"; do
    echo "Testing on $arch..."
    GOOS=linux GOARCH=$arch go build -o app-$arch main.go

    if [ "$arch" = "riscv64" ]; then
        qemu-riscv64 ./app-$arch
    else
        ./app-$arch
    fi
done
```

### Custom Machine Configuration

```bash
# Custom RISC-V machine
qemu-system-riscv64 \
  -M virt \
  -m 2G \
  -smp 4 \
  -device virtio-gpu-pci \
  -device virtio-keyboard-pci \
  -device virtio-mouse-pci \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -kernel ./linux \
  -initrd ./initrd \
  -append "console=ttyS0 root=/dev/vda" \
  -drive file=./rootfs.ext4,if=virtio,format=raw
```

## Troubleshooting

### Common Issues

#### 1. "qemu-system-riscv64: command not found"

**Problem**: QEMU not installed or not in PATH

**Solution**:
```bash
# Check installation
which qemu-system-riscv64

# Ubuntu/Debian
sudo apt-get install qemu-system-riscv64

# Add to PATH if needed
export PATH=/usr/local/bin:$PATH
```

#### 2. "Invalid ELF image for this architecture"

**Problem**: Binary not compiled for RISC-V

**Solution**:
```bash
# Check binary architecture
file ./my-app
# Should show: ELF 64-bit LSB executable, RISC-V

# Rebuild correctly
GOOS=linux GOARCH=riscv64 go build -o my-app main.go
```

#### 3. "Could not initialize SDL"

**Problem**: Graphics display issues

**Solution**:
```bash
# Use nographic mode
qemu-system-riscv64 -M virt -nographic -kernel ./linux

# Or set display
export DISPLAY=:0
qemu-system-riscv64 -M virt -kernel ./linux
```

#### 4. "Network unreachable"

**Problem**: Networking not configured

**Solution**:
```bash
# Add network configuration
qemu-system-riscv64 \
  -M virt \
  -net nic,model=virtio \
  -net user \
  -kernel ./linux
```

#### 5. Slow Performance

**Problem**: QEMU running slowly

**Solutions**:
```bash
# Use KVM (Linux only)
qemu-system-riscv64 -accel kvm -M virt -kernel ./linux

# Optimize TCG
qemu-system-riscv64 -accel tcg,thread=multi -M virt -kernel ./linux

# Reduce memory
qemu-system-riscv64 -m 256M -M virt -kernel ./linux
```

### Debug Output

```bash
# Enable verbose output
qemu-system-riscv64 -D qemu.log -d cpu,in_asm -M virt -kernel ./linux

# View logs
tail -f qemu.log
```

### Performance Monitoring

```bash
# Monitor QEMU performance
qemu-system-riscv64 \
  -M virt \
  -kernel ./linux \
  -monitor telnet:127.0.0.1:5555,server,nowait

# Connect to monitor
telnet 127.0.0.1 5555
(qemu) info registers
(qemu) info cpus
```

## Best Practices

### Development Workflow

1. **Test frequently** with QEMU during development
2. **Use user-mode** for application testing (faster)
3. **Use system-mode** for kernel/driver development
4. **Automate testing** in CI/CD pipelines
5. **Profile performance** with QEMU tools

### Optimization Tips

1. **Choose right mode**: User-mode for apps, system-mode for kernels
2. **Use appropriate memory**: 256MB-1GB for most applications
3. **Enable KVM**: On Linux for significant performance boost
4. **Optimize disk I/O**: Use virtio drivers with writeback cache
5. **Network configuration**: Use user-mode networking for development

### Security Considerations

1. **Isolate networks**: Use user-mode networking for development
2. **Limit resources**: Set appropriate memory and CPU limits
3. **Monitor access**: Be aware of host network access from guest
4. **Clean shutdown**: Always properly shut down QEMU instances

## Resources

- [QEMU RISC-V Documentation](https://www.qemu.org/docs/master/system/riscv/)
- [RISC-V QEMU](https://github.com/qemu/qemu/tree/master/target/riscv)
- [QEMU Networking](https://wiki.qemu.org/Documentation/Networking)
- [GDB Debugging](https://sourceware.org/gdb/current/onlinedocs/gdb.html/)

## Examples in this Repository

This repository includes QEMU-ready examples:

- **GPIO LED**: `make run-example-gpio-led`
- **Network Server**: `make run-example-network-server`
- **Sensor Reading**: `make run-example-sensor-reading`
- **Buildroot App**: `make run-example-buildroot-app`

All examples are tested and verified to work with QEMU RISC-V emulation.

For more examples and detailed usage, see the [examples](../examples/) directory.

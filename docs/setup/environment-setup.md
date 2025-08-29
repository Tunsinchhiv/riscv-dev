# Environment Setup Guide

This guide provides comprehensive instructions for setting up a RISC-V development environment for embedded systems development with Go.

## Table of Contents

- [Quick Start](#quick-start)
- [Dev Container Setup (Recommended)](#dev-container-setup-recommended)
- [Manual Installation](#manual-installation)
- [Toolchain Verification](#toolchain-verification)
- [Buildroot SDK Setup](#buildroot-sdk-setup)
- [VS Code Configuration](#vs-code-configuration)
- [Troubleshooting](#troubleshooting)

## Quick Start

### Option 1: Dev Container (Fastest)
```bash
# 1. Prerequisites: Docker + VS Code
# 2. Clone repository
git clone <repository-url> riscv-dev-standalone
cd riscv-dev-standalone

# 3. Open in VS Code
code .

# 4. Use Command Palette: "Dev Containers: Reopen in Container"
# 5. Build examples
make build-examples
```

### Option 2: Manual Setup
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install gcc-riscv64-linux-gnu g++-riscv64-linux-gnu
sudo apt-get install qemu-system-riscv64 qemu-user
sudo apt-get install gdb-multiarch

# Build examples
make build-examples
```

## Dev Container Setup (Recommended)

The dev container provides a pre-configured, isolated development environment.

### Prerequisites

- **Docker** (or Docker Desktop)
- **VS Code** with Dev Containers extension
- At least **4GB RAM** available for Docker
- **2GB disk space** for container images

### Installation Steps

1. **Install Docker**
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install docker.io docker-compose-v2
   sudo systemctl enable docker
   sudo systemctl start docker

   # Add user to docker group
   sudo usermod -aG docker $USER
   # Logout and login again
   ```

2. **Install VS Code Dev Containers Extension**
   - Open VS Code
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "Dev Containers"
   - Install "Dev Containers" by Microsoft

3. **Clone and Open Repository**
   ```bash
   git clone <repository-url> riscv-dev-standalone
   cd riscv-dev-standalone
   code .
   ```

4. **Reopen in Dev Container**
   - Press `Ctrl+Shift+P` (Command Palette)
   - Type "Dev Containers: Reopen in Container"
   - Select "RISC-V Development Environment"
   - Wait for container to build (first time: ~5-10 minutes)

5. **Verify Setup**
   ```bash
   # Inside container
   riscv64-linux-gnu-gcc --version
   go version
   qemu-system-riscv64 --version
   ```

### Dev Container Features

The container includes:

- **Ubuntu 22.04** base system
- **RISC-V GCC Toolchain** (12.x series)
- **Go 1.21+** with cross-compilation support
- **QEMU 7.x** with RISC-V emulation
- **GDB Multi-arch** debugger
- **Buildroot build tools**
- **VS Code extensions** for development

### Container Configuration

The dev container is configured in `.devcontainer/`:

```json
{
    "name": "RISC-V Development Environment",
    "image": "riscv64/ubuntu:22.04",
    "features": {
        "ghcr.io/devcontainers/features/go:1": {
            "version": "1.21"
        }
    },
    "customizations": {
        "vscode": {
            "extensions": [
                "ms-vscode.cpptools",
                "golang.Go",
                "ms-vscode.cmake-tools"
            ]
        }
    }
}
```

## Manual Installation

For systems without Docker or when you prefer system-wide installation.

### Ubuntu/Debian Setup

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade

# Install RISC-V toolchain
sudo apt-get install gcc-riscv64-linux-gnu g++-riscv64-linux-gnu
sudo apt-get install binutils-riscv64-linux-gnu
sudo apt-get install gdb-multiarch

# Install QEMU
sudo apt-get install qemu-system-riscv64 qemu-user

# Install additional tools
sudo apt-get install build-essential git cmake
sudo apt-get install libncurses-dev libssl-dev bison flex
```

### Fedora/CentOS/RHEL Setup

```bash
# Install RISC-V toolchain
sudo dnf install gcc-riscv64-linux-gnu gcc-c++-riscv64-linux-gnu
sudo dnf install binutils-riscv64-linux-gnu gdb

# Install QEMU
sudo dnf install qemu-system-riscv qemu-user

# Install build tools
sudo dnf groupinstall "Development Tools"
sudo dnf install cmake ncurses-devel openssl-devel bison flex
```

### macOS Setup (using Homebrew)

```bash
# Install QEMU
brew install qemu

# Install RISC-V toolchain (via riscv-gnu-toolchain)
brew tap riscv/riscv
brew install riscv-gnu-toolchain

# Install additional tools
brew install go cmake
```

### Windows Setup (using WSL2)

```powershell
# Enable WSL2
wsl --install -d Ubuntu

# Inside WSL2 Ubuntu:
sudo apt-get update
sudo apt-get install gcc-riscv64-linux-gnu g++-riscv64-linux-gnu
sudo apt-get install qemu-system-riscv64 qemu-user
sudo apt-get install build-essential
```

## Toolchain Verification

After installation, verify all tools are working:

```bash
# Test RISC-V GCC
riscv64-linux-gnu-gcc --version
# Should show: riscv64-linux-gnu-gcc (Ubuntu X.X.X-XXXX) X.X.X

# Test Go cross-compilation
go version
GOOS=linux GOARCH=riscv64 go version
# Should show Go version and RISC-V target support

# Test QEMU
qemu-system-riscv64 --version
qemu-riscv64 --version
# Should show QEMU version with RISC-V support

# Test GDB
gdb-multiarch --version
# Should show GNU gdb with multi-architecture support
```

### Build Test

```bash
# Clone repository
git clone <repository-url> riscv-dev-standalone
cd riscv-dev-standalone

# Test cross-compilation
make build-example-gpio-led
ls -la bin/examples/gpio-led/
# Should show app binary (~1.5MB)

# Test QEMU execution
make run-example-gpio-led
# Should show LED blinking output
```

## Buildroot SDK Setup

For full embedded Linux development:

### Download Buildroot SDK

```bash
# Example for Milk-V Duo
wget https://github.com/milkv-duo/milkv-duo-buildroot-sdk/releases/download/v1.0.0/duo-buildroot-sdk-v1.0.0.tar.gz
tar -xzf duo-buildroot-sdk-v1.0.0.tar.gz
cd duo-buildroot-sdk

# Or use v2 SDK
wget https://github.com/milkv-duo/milkv-duo-buildroot-sdk/releases/download/v2.0.0/duo-buildroot-sdk-v2.0.0.tar.gz
tar -xzf duo-buildroot-sdk-v2.0.0.tar.gz
cd duo-buildroot-sdk-v2
```

### SDK Integration

```bash
# Create SDK directory in project
sudo mkdir -p /opt/duo-buildroot-sdk
sudo mv duo-buildroot-sdk/* /opt/duo-buildroot-sdk/

# Set permissions
sudo chown -R $USER:$USER /opt/duo-buildroot-sdk
```

### Test Buildroot Build

```bash
# Navigate to SDK
cd /opt/duo-buildroot-sdk

# Configure for Milk-V Duo
export BR2_DEFCONFIG=../configs/milkv_duo_sd
make milkv_duo_sd_defconfig

# Build (takes ~30-60 minutes first time)
make
```

## VS Code Configuration

### Recommended Extensions

```json
{
    "recommendations": [
        "ms-vscode.cpptools",
        "ms-vscode.cmake-tools",
        "golang.Go",
        "ms-vscode.vscode-json",
        "ms-vscode.makefile-tools",
        "ms-vscode.hexeditor",
        "ms-vscode.vscode-docker"
    ]
}
```

### Settings Configuration

Add to `.vscode/settings.json`:

```json
{
    "go.gopath": "/go",
    "go.goroot": "/usr/local/go",
    "go.formatTool": "gofmt",
    "go.useLanguageServer": true,
    "go.lintTool": "golangci-lint",
    "C_Cpp.default.compilerPath": "riscv64-linux-gnu-gcc",
    "C_Cpp.default.cStandard": "c17",
    "C_Cpp.default.cppStandard": "c++17"
}
```

### Launch Configuration

Add to `.vscode/launch.json`:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug RISC-V Example",
            "type": "go",
            "request": "launch",
            "mode": "debug",
            "program": "${workspaceFolder}/examples/gpio-led/cmd/app/main.go",
            "cwd": "${workspaceFolder}",
            "env": {
                "GOOS": "linux",
                "GOARCH": "riscv64",
                "CGO_ENABLED": "0"
            }
        }
    ]
}
```

## Troubleshooting

### Common Issues

#### 1. "riscv64-linux-gnu-gcc: command not found"

**Problem**: RISC-V toolchain not installed or not in PATH

**Solution**:
```bash
# Ubuntu/Debian
sudo apt-get install gcc-riscv64-linux-gnu

# Check PATH
which riscv64-linux-gnu-gcc
echo $PATH
```

#### 2. "qemu-system-riscv64: command not found"

**Problem**: QEMU not installed

**Solution**:
```bash
# Ubuntu/Debian
sudo apt-get install qemu-system-riscv64

# Verify
qemu-system-riscv64 --version
```

#### 3. "go: unknown architecture riscv64"

**Problem**: Go version too old or cross-compilation not supported

**Solution**:
```bash
# Check Go version
go version
# Should be 1.19+ for riscv64 support

# Update Go if needed
# Download from https://golang.org/dl/
```

#### 4. "Permission denied" with GPIO/Serial

**Problem**: Hardware access permissions

**Solution**:
```bash
# Add user to groups
sudo usermod -a -G dialout,gpio $USER
# Logout and login again
```

#### 5. Dev Container Build Fails

**Problem**: Docker issues or network problems

**Solution**:
```bash
# Check Docker
docker --version
docker run hello-world

# Clean up containers
docker system prune -a

# Rebuild dev container
# In VS Code: Ctrl+Shift+P → "Dev Containers: Rebuild Container"
```

### Performance Issues

#### Slow Compilation
```bash
# Use parallel builds
make -j$(nproc) build-examples

# Or limit parallelism
make -j4 build-examples
```

#### QEMU Slow Emulation
```bash
# Use KVM acceleration (Linux hosts)
qemu-system-riscv64 -accel kvm ...

# Use user-mode emulation for faster testing
qemu-riscv64 ./binary
```

### Getting Help

1. **Check Documentation**: See `docs/` directory
2. **GitHub Issues**: Search existing issues
3. **Community**: RISC-V forums and mailing lists
4. **Logs**: Check container logs with `docker logs`

## Advanced Setup

### Custom Toolchain

```bash
# Build custom RISC-V toolchain
git clone https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
./configure --prefix=/opt/riscv --with-arch=rv64gc --with-abi=lp64d
make -j$(nproc)
sudo make install
```

### Multiple Architectures

```bash
# Add 32-bit RISC-V support
sudo apt-get install gcc-riscv64-linux-gnu gcc-riscv64-linux-gnu

# Set environment
export GOARCH=riscv64  # or riscv (32-bit)
export GOOS=linux
```

### CI/CD Integration

```yaml
# .github/workflows/build.yml
name: Build and Test
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup RISC-V
        run: |
          sudo apt-get update
          sudo apt-get install gcc-riscv64-linux-gnu qemu-user
      - name: Build Examples
        run: make build-examples
      - name: Test Examples
        run: make test
```

## Next Steps

After setup, you can:

1. **Build examples**: `make build-examples`
2. **Run tests**: `make test`
3. **Try QEMU**: `make run-example-gpio-led`
4. **Explore Buildroot**: See Buildroot integration docs
5. **Develop your own**: Use examples as templates

For detailed tutorials, see:
- [Go Cross-Compilation Tutorial](tutorials/go-cross-compilation.md)
- [QEMU Emulation Guide](tutorials/qemu-emulation.md)
- [Buildroot Integration](tutorials/buildroot-integration.md)

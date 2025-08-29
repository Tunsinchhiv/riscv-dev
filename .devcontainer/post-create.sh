#!/bin/bash
set -e

echo "🚀 Setting up RISC-V Development Environment..."

# Update package list
apt-get update

# Install RISC-V toolchain and related tools
echo "📦 Installing RISC-V GNU Toolchain..."
apt-get install -y \
    gcc-riscv64-linux-gnu \
    g++-riscv64-linux-gnu \
    binutils-riscv64-linux-gnu \
    gdb-multiarch \
    qemu-system-riscv64 \
    qemu-user \
    device-tree-compiler \
    u-boot-tools \
    libncurses-dev \
    libssl-dev \
    bc \
    bison \
    flex \
    libelf-dev \
    dwarves \
    cpio \
    rsync \
    wget \
    curl \
    git \
    build-essential \
    pkg-config \
    libglib2.0-dev \
    libpixman-1-dev \
    ninja-build \
    python3-dev \
    python3-pip \
    cmake \
    make \
    autoconf \
    automake \
    libtool

# Install Go tools for RISC-V cross-compilation
echo "🔧 Setting up Go for RISC-V..."
export GOOS=linux
export GOARCH=riscv64
export CGO_ENABLED=0

# Install additional Go tools
go install github.com/cosmtrek/air@latest
go install github.com/go-delve/delve/cmd/dlv@latest

# Set up QEMU for RISC-V
echo "🐛 Configuring QEMU for RISC-V debugging..."
cat > /usr/local/bin/qemu-riscv64-gdb << 'EOF'
#!/bin/bash
exec qemu-riscv64 -g 1234 "$@"
EOF
chmod +x /usr/local/bin/qemu-riscv64-gdb

# Create RISC-V development directories
mkdir -p /workspaces/riscv-dev-standalone/bin
mkdir -p /workspaces/riscv-dev-standalone/build

# Set up environment variables
cat >> ~/.bashrc << 'EOF'

# RISC-V Development Environment
export RISCV_ROOT=/opt/riscv
export PATH=$RISCV_ROOT/bin:$PATH
export GOOS=linux
export GOARCH=riscv64
export CGO_ENABLED=0

# QEMU settings
export QEMU_AUDIO_DRV=none

# Development shortcuts
alias riscv-gcc='riscv64-linux-gnu-gcc'
alias riscv-g++='riscv64-linux-gnu-g++'
alias riscv-gdb='gdb-multiarch'
alias riscv-qemu='qemu-riscv64'
alias riscv-qemu-system='qemu-system-riscv64'

EOF

# Verify installation
echo "✅ Verifying RISC-V toolchain installation..."
riscv64-linux-gnu-gcc --version | head -1
echo "✅ RISC-V GCC installed successfully"

qemu-system-riscv64 --version | head -1
echo "✅ QEMU RISC-V installed successfully"

go version
echo "✅ Go installed successfully"

echo "🎉 RISC-V Development Environment setup complete!"
echo ""
echo "Available commands:"
echo "  riscv-gcc        - RISC-V GCC compiler"
echo "  riscv-g++        - RISC-V G++ compiler"
echo "  riscv-gdb        - Multi-arch GDB debugger"
echo "  riscv-qemu       - QEMU user-mode emulator"
echo "  riscv-qemu-system - QEMU system emulator"
echo ""
echo "Environment variables:"
echo "  GOOS=linux"
echo "  GOARCH=riscv64"
echo "  CGO_ENABLED=0"
echo ""
echo "Next steps:"
echo "1. Run 'make' to build example projects"
echo "2. Use 'make run-qemu-system' to test in QEMU"
echo "3. See docs/ for detailed tutorials"

# Contributing to RISC-V Development Environment

Thank you for your interest in contributing to the RISC-V Development Environment! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Contributing Guidelines](#contributing-guidelines)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

This project follows a code of conduct to ensure a welcoming environment for all contributors. By participating, you agree to:

- Be respectful and inclusive
- Focus on constructive feedback
- Accept responsibility for mistakes
- Show empathy towards other contributors
- Help create a positive community

## Getting Started

### Prerequisites

Before you begin, ensure you have:

- **Docker** and **Docker Compose** installed
- **VS Code** with the Dev Containers extension
- **Git** for version control
- Basic knowledge of **Go programming**
- Familiarity with **RISC-V architecture** (helpful but not required)

### Quick Start

1. **Fork the repository** on GitHub
2. **Clone your fork**:
   ```bash
   git clone https://github.com/your-username/riscv-dev-standalone.git
   cd riscv-dev-standalone
   ```
3. **Open in VS Code** and use "Dev Containers: Reopen in Container"
4. **Build and test**:
   ```bash
   make build-examples
   make test
   ```

## Development Setup

### Using Dev Container (Recommended)

The repository includes a complete dev container configuration:

1. Open the repository in VS Code
2. When prompted, click "Reopen in Container"
3. The environment will automatically set up:
   - RISC-V toolchain (GCC, binutils, GDB)
   - Go 1.21+ with cross-compilation support
   - QEMU for RISC-V emulation
   - All necessary development tools

### Manual Setup

If you prefer manual setup:

```bash
# Install RISC-V toolchain
sudo apt-get update
sudo apt-get install gcc-riscv64-linux-gnu g++-riscv64-linux-gnu
sudo apt-get install qemu-system-riscv64 qemu-user
sudo apt-get install gdb-multiarch

# Install Go (if not already installed)
# Follow instructions at https://golang.org/dl/

# Clone and setup
git clone <repository-url>
cd riscv-dev-standalone
export GOOS=linux
export GOARCH=riscv64
export CGO_ENABLED=0
```

## Project Structure

```
riscv-dev-standalone/
├── .devcontainer/         # Dev container configuration
├── examples/             # Example projects
│   ├── gpio-led/        # GPIO control example
│   ├── network-server/  # TCP server example
│   ├── sensor-reading/  # ADC interface example
│   └── buildroot-app/   # Buildroot integration
├── docs/                # Documentation
├── scripts/            # Utility scripts
├── bin/                # Build outputs (generated)
├── Makefile           # Build automation
├── go.work           # Go workspace (generated)
├── CONTRIBUTING.md   # This file
├── LICENSE          # MIT license
└── README.md        # Main documentation
```

### Key Directories

- **`examples/`**: Individual example projects, each with:
  - `cmd/app/main.go`: Main application
  - `go.mod`: Go module definition
  - `README.md`: Example-specific documentation
- **`docs/`**: Comprehensive documentation
- **`scripts/`**: Utility scripts for development
- **`.devcontainer/`**: Dev container configuration

## Contributing Guidelines

### Types of Contributions

We welcome various types of contributions:

- **Bug fixes**: Fix issues in existing code
- **New examples**: Add new RISC-V development examples
- **Documentation**: Improve existing documentation
- **Tools and scripts**: Enhance development workflow
- **Testing**: Add or improve tests

### Choosing What to Work On

1. **Check existing issues** on GitHub
2. **Look for "good first issue"** labels
3. **Propose new examples** that demonstrate useful RISC-V concepts
4. **Improve documentation** for unclear areas

### Development Workflow

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the coding standards

3. **Test your changes**:
   ```bash
   make build-examples
   make test
   ```

4. **Update documentation** if needed

5. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

6. **Push and create pull request**:
   ```bash
   git push origin feature/your-feature-name
   ```

## Coding Standards

### Go Code

- Follow standard Go formatting (`go fmt`)
- Use `go vet` and `golint` for code quality
- Follow Go naming conventions
- Write comprehensive documentation comments
- Use meaningful variable and function names
- Handle errors appropriately
- Write table-driven tests where applicable

### Example Structure

Each example should follow this structure:

```
examples/your-example/
├── cmd/app/
│   └── main.go          # Main application
├── go.mod              # Go module definition
└── README.md           # Documentation
```

### Code Quality

- **Readability**: Code should be self-documenting
- **Performance**: Optimize for embedded systems
- **Reliability**: Include proper error handling
- **Maintainability**: Keep functions focused and modular

### Commit Messages

Follow conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Testing
- `chore`: Maintenance

Examples:
```
feat(gpio-led): add PWM support for LED brightness control
fix(network-server): handle client disconnection gracefully
docs(setup): add troubleshooting section for common issues
```

## Testing

### Running Tests

```bash
# Run all tests
make test

# Test specific example
cd examples/gpio-led
go test ./...
```

### Writing Tests

- Use table-driven tests for multiple test cases
- Test both success and error paths
- Include edge cases and boundary conditions
- Use meaningful test names and documentation

Example test structure:

```go
func TestLEDControl(t *testing.T) {
    tests := []struct {
        name     string
        pin      int
        state    bool
        expected bool
    }{
        {"turn LED on", 17, true, true},
        {"turn LED off", 17, false, false},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Test implementation
        })
    }
}
```

### Cross-Compilation Testing

Test your code compiles for RISC-V:

```bash
# Test cross-compilation
GOOS=linux GOARCH=riscv64 go build ./cmd/app

# Test with QEMU
qemu-riscv64 ./app
```

## Documentation

### Documentation Standards

- Use Markdown for all documentation
- Include code examples with syntax highlighting
- Provide step-by-step instructions
- Include troubleshooting sections
- Keep documentation up-to-date with code changes

### Documentation Structure

Each example should have:

1. **Overview**: What the example demonstrates
2. **Features**: Key capabilities
3. **Building**: How to compile and run
4. **Usage**: How to use the example
5. **Configuration**: Available options
6. **Troubleshooting**: Common issues and solutions

## Pull Request Process

### Before Submitting

1. **Update your branch** with the latest main:
   ```bash
   git fetch origin
   git rebase origin/main
   ```

2. **Run full test suite**:
   ```bash
   make clean
   make build-examples
   make test
   ```

3. **Update documentation** if needed

4. **Ensure commit messages** follow conventional format

### Pull Request Template

When creating a PR, include:

- **Title**: Clear, descriptive title
- **Description**: What changes were made and why
- **Testing**: How the changes were tested
- **Breaking Changes**: If any breaking changes
- **Related Issues**: Link to related issues

### Review Process

1. **Automated checks** will run (build, test, lint)
2. **Code review** by maintainers
3. **Feedback and iteration** as needed
4. **Approval and merge** when ready

## Reporting Issues

### Bug Reports

When reporting bugs, include:

1. **Clear title** describing the issue
2. **Steps to reproduce** the problem
3. **Expected vs actual behavior**
4. **Environment information**:
   - OS and version
   - Go version
   - RISC-V toolchain version
   - Hardware (if applicable)
5. **Error messages** and stack traces
6. **Screenshots** if applicable

### Feature Requests

For new features, include:

1. **Clear description** of the proposed feature
2. **Use case** and benefits
3. **Implementation ideas** if you have them
4. **Alternatives considered**

### Questions and Discussion

- Use **GitHub Discussions** for questions
- Check existing issues and discussions first
- Provide context about your use case

## Getting Help

If you need help:

1. **Check the documentation** first
2. **Search existing issues** and discussions
3. **Ask in GitHub Discussions**
4. **Create an issue** if you find a bug

## Recognition

Contributors will be recognized:
- In release notes
- On the project's contributor list
- Through GitHub's contributor insights

Thank you for contributing to the RISC-V Development Environment! 🎉

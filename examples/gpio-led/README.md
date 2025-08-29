# GPIO LED Example

A simple RISC-V GPIO LED blink example demonstrating basic hardware interaction with Go.

## Overview

This example demonstrates:
- GPIO pin control on RISC-V hardware
- Basic LED blinking pattern
- Graceful shutdown handling
- Board identification
- Cross-compilation for RISC-V

## Hardware Requirements

- RISC-V development board (e.g., Milk-V Duo, HiFive Unmatched)
- LED connected to GPIO pin 17 (configurable in code)
- Proper GPIO access permissions

## Building

### Method 1: Using the main Makefile
```bash
cd /path/to/riscv-dev-standalone
make build-example-gpio-led
```

### Method 2: Direct compilation
```bash
cd examples/gpio-led
GOOS=linux GOARCH=riscv64 CGO_ENABLED=0 go build -o ../../bin/gpio-led/app ./cmd/app
```

## Running

### On RISC-V Hardware
```bash
# Copy to your RISC-V board
scp bin/gpio-led/app user@riscv-board:/tmp/

# Run on the board
ssh user@riscv-board
sudo /tmp/gpio-led/app
```

### Using QEMU User-Mode Emulation
```bash
# From the development environment
qemu-riscv64 bin/gpio-led/app
```

## Expected Output

```
🚀 RISC-V GPIO LED Example
Board: Milk-V Duo
LED Pin: GPIO17
✅ GPIO initialized successfully
🎯 Starting LED blink pattern (interval: 500ms)
💡 LED ON (blink #1)
💡 LED OFF (blink #2)
💡 LED ON (blink #3)
...
```

## Configuration

### Changing the GPIO Pin

Edit the `LED_PIN` constant in `main.go`:

```go
const LED_PIN = 17  // Change this to your desired GPIO pin
```

### Adjusting Blink Speed

Modify the `BLINK_INTERVAL` constant:

```go
const BLINK_INTERVAL = 500 * time.Millisecond  // Change blink speed
```

## Troubleshooting

### Permission Denied
If you get GPIO permission errors:
```bash
# Add your user to the gpio group (if available)
sudo usermod -a -G gpio $USER

# Or run with sudo (less secure)
sudo ./gpio-led/app
```

### GPIO Pin Not Working
- Verify the physical pin mapping for your board
- Check if the pin is already in use by another process
- Ensure proper voltage levels for your LED

### Board Detection Issues
The example attempts to read board information from:
- `/proc/device-tree/model`
- `/sys/firmware/devicetree/base/model`
- `/etc/hostname`

If detection fails, it will show "Unknown RISC-V Board".

## Dependencies

- `github.com/stianeikeland/go-rpio/v4` - GPIO library for Linux

## Next Steps

- Try modifying the blink pattern
- Add multiple LEDs
- Integrate with sensor input
- Explore PWM for LED brightness control

## Related Examples

- [Network Server](../network-server/) - TCP socket programming
- [Sensor Reading](../sensor-reading/) - ADC interface
- [Buildroot App](../buildroot-app/) - Buildroot integration

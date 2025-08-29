# Sensor Reading Example

An ADC interface demonstration showing sensor data acquisition and processing on RISC-V hardware.

## Overview

This example demonstrates:
- Analog-to-Digital Converter (ADC) interface simulation
- Multi-sensor data acquisition (temperature, light, pressure)
- Real-time sensor monitoring
- Data conversion and calibration
- Environmental assessment
- Cross-compilation for embedded systems

## Features

- **Multi-sensor support**: Temperature, light, and pressure sensors
- **ADC simulation**: Realistic 12-bit ADC with configurable reference voltage
- **Real-time monitoring**: Continuous sensor data acquisition
- **Data conversion**: ADC values to physical units (°C, lux, kPa)
- **Environmental assessment**: Automated analysis of sensor readings
- **Calibration support**: Configurable sensor calibration parameters

## Sensor Configuration

### Temperature Sensor
- **Range**: -50°C to +150°C
- **Resolution**: 0.1°C
- **ADC Channel**: 0

### Light Sensor
- **Range**: 0 to 1000 lux
- **ADC Channel**: 1

### Pressure Sensor
- **Range**: 90 to 110 kPa (atmospheric pressure)
- **Resolution**: 0.02 kPa
- **ADC Channel**: 2

## Building

### Method 1: Using the main Makefile
```bash
cd /path/to/riscv-dev-standalone
make build-example-sensor-reading
```

### Method 2: Direct compilation
```bash
cd examples/sensor-reading
GOOS=linux GOARCH=riscv64 CGO_ENABLED=0 go build -o ../../bin/sensor-reading/app ./cmd/app
```

## Running

### On RISC-V Hardware
```bash
# Copy to your RISC-V board
scp bin/sensor-reading/app user@riscv-board:/tmp/

# Run on the board
ssh user@riscv-board
sudo /tmp/sensor-reading/app
```

### Using QEMU User-Mode Emulation
```bash
# From the development environment
qemu-riscv64 bin/sensor-reading/app
```

## Expected Output

```
📊 RISC-V Sensor Reading Example
Board: Milk-V Duo
ADC Configuration: 12-bit, 3.3V reference
Sample Interval: 100ms

🔧 CONFIGURED SENSORS:
  Channel 0: Temperature
  Channel 1: Light Sensor
  Channel 2: Pressure

📈 Starting sensor monitoring...
Press Ctrl+C to stop

🌡️  SENSOR READINGS (14:30:25)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌡️  Temperature:  22.50 °C
💡 Light Level:   650 lux
📊 Pressure:     101.25 kPa

🔧 RAW ADC VALUES:
  Temperature (Ch0): 2250 ADC (1.820V)
  Light Sensor (Ch1): 1987 ADC (1.608V)
  Pressure (Ch2): 2562 ADC (2.074V)

🏠 ENVIRONMENTAL ASSESSMENT:
  ✅ Comfortable temperature (22.5°C)
  ☀️  Bright environment (650 lux)
  ✅ Normal atmospheric pressure (101.2 kPa)

📊 Sample #1 completed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Configuration

### ADC Settings

Edit the constants in `main.go`:

```go
const (
    ADC_MAX_VALUE   = 4095  // 12-bit ADC (change for different resolutions)
    ADC_REFERENCE_V = 3.3   // Reference voltage (3.3V, 5V, etc.)
    SAMPLE_INTERVAL = 100 * time.Millisecond // Sampling rate
)
```

### Sensor Calibration

Adjust calibration values for your specific sensors:

```go
const (
    TEMP_OFFSET   = 500   // ADC offset for 0°C
    TEMP_SCALE    = 10.0  // ADC counts per °C
    LIGHT_MAX_LUX = 1000  // Maximum lux value
    PRESSURE_OFFSET = 1000  // ADC offset for 0 kPa
    PRESSURE_SCALE = 50.0   // ADC counts per kPa
)
```

## Hardware Integration

### Real ADC Interface

To interface with real ADC hardware, replace the `readADCChannel` method:

```go
// Example for I2C ADC (MCP3421)
func (sm *SensorManager) readADCChannel(channel int) int {
    // I2C communication code here
    // Return actual ADC reading
    return actualADCValue
}
```

### SPI ADC Example

```go
// Example for SPI ADC (ADS1256)
func (sm *SensorManager) readADCChannel(channel int) int {
    // SPI communication code here
    // Return actual ADC reading
    return actualADCValue
}
```

## Data Processing

### Sensor Data Structure

```go
type SensorData struct {
    Timestamp   time.Time
    Temperature float64 // °C
    LightLevel  float64 // lux
    Pressure    float64 // kPa
    RawADC      map[int]int // Raw ADC values
}
```

### Conversion Functions

- `convertADCToVoltage()`: ADC counts to voltage
- `convertADCToTemperature()`: ADC to temperature (°C)
- `convertADCToLightLevel()`: ADC to light level (lux)
- `convertADCToPressure()`: ADC to pressure (kPa)

## Troubleshooting

### ADC Reading Issues
- Verify ADC channel connections
- Check reference voltage settings
- Ensure proper power supply to sensors

### Sensor Calibration
```bash
# Test individual sensor readings
./sensor-reading/app | grep "RAW ADC"

# Compare with multimeter readings
# Adjust calibration constants as needed
```

### Performance Issues
- Reduce `SAMPLE_INTERVAL` for faster sampling
- Increase interval for lower power consumption
- Consider using goroutines for parallel sensor reading

## Performance Characteristics

- **Sample Rate**: Configurable (default 100ms intervals)
- **Memory Usage**: ~4KB per sample
- **CPU Usage**: Minimal (< 5% on typical RISC-V cores)
- **Power Consumption**: Low (suitable for battery-powered applications)

## Dependencies

- **Standard library only**: No external dependencies
- Uses `fmt`, `log`, `math`, `math/rand`, `os`, `os/signal`, `syscall`, `time` packages

## Next Steps

- Add sensor data logging to files
- Implement sensor data averaging
- Add threshold-based alerts
- Create web interface for sensor monitoring
- Integrate with databases for data storage

## Real Hardware Considerations

### Supported ADC Interfaces
- **I2C**: MCP3421, ADS1115, etc.
- **SPI**: ADS1256, MCP3008, etc.
- **Built-in ADC**: Many RISC-V SoCs have built-in ADCs

### Power Management
- Duty cycling for battery-powered applications
- Sleep modes between samples
- Wake-on-sensor interrupts

## Related Examples

- [GPIO LED](../gpio-led/) - Basic hardware control
- [Network Server](../network-server/) - Data transmission
- [Buildroot App](../buildroot-app/) - System integration

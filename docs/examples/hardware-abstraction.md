# Hardware Abstraction Examples for RISC-V

This guide demonstrates hardware abstraction patterns and interfaces commonly used in RISC-V embedded systems, with practical Go implementations and cross-compilation examples.

## Table of Contents

- [Hardware Abstraction Overview](#hardware-abstraction-overview)
- [GPIO Interface](#gpio-interface)
- [I2C Communication](#i2c-communication)
- [SPI Interface](#spi-interface)
- [UART/Serial Communication](#uartserial-communication)
- [ADC (Analog-to-Digital Conversion)](#adc-analog-to-digital-conversion)
- [PWM (Pulse Width Modulation)](#pwm-pulse-width-modulation)
- [Timer and Interrupt Handling](#timer-and-interrupt-handling)
- [Hardware Abstraction Layer](#hardware-abstraction-layer)
- [Real Hardware Examples](#real-hardware-examples)

## Hardware Abstraction Overview

### Why Hardware Abstraction?

Hardware abstraction layers (HAL) provide:

- **Portability** across different RISC-V boards
- **Maintainability** through standardized interfaces
- **Testability** with mock implementations
- **Performance** optimization opportunities
- **Safety** through proper resource management

### Design Principles

```go
// Interface-based design
type GPIOController interface {
    SetMode(pin int, mode PinMode) error
    Write(pin int, value bool) error
    Read(pin int) (bool, error)
    Close() error
}

// Factory pattern for different implementations
func NewGPIOController(driver string) (GPIOController, error) {
    switch driver {
    case "sysfs":
        return NewSysfsGPIO()
    case "memory":
        return NewMemoryGPIO()
    case "mock":
        return NewMockGPIO()
    default:
        return nil, fmt.Errorf("unsupported driver: %s", driver)
    }
}
```

## GPIO Interface

### Basic GPIO Operations

```go
// gpio.go - GPIO abstraction
package gpio

import (
    "fmt"
    "os"
    "strconv"
    "strings"
)

type PinMode int

const (
    Input PinMode = iota
    Output
    PWM
    Analog
)

type GPIOController interface {
    Export(pin int) error
    Unexport(pin int) error
    SetDirection(pin int, direction string) error
    Write(pin int, value bool) error
    Read(pin int) (bool, error)
    Close() error
}

// SysfsGPIO implements GPIO using Linux sysfs
type SysfsGPIO struct{}

func NewSysfsGPIO() *SysfsGPIO {
    return &SysfsGPIO{}
}

func (gpio *SysfsGPIO) Export(pin int) error {
    return writeToFile("/sys/class/gpio/export", strconv.Itoa(pin))
}

func (gpio *SysfsGPIO) Unexport(pin int) error {
    return writeToFile("/sys/class/gpio/unexport", strconv.Itoa(pin))
}

func (gpio *SysfsGPIO) SetDirection(pin int, direction string) error {
    path := fmt.Sprintf("/sys/class/gpio/gpio%d/direction", pin)
    return writeToFile(path, direction)
}

func (gpio *SysfsGPIO) Write(pin int, value bool) error {
    path := fmt.Sprintf("/sys/class/gpio/gpio%d/value", pin)
    val := "0"
    if value {
        val = "1"
    }
    return writeToFile(path, val)
}

func (gpio *SysfsGPIO) Read(pin int) (bool, error) {
    path := fmt.Sprintf("/sys/class/gpio/gpio%d/value", pin)
    data, err := os.ReadFile(path)
    if err != nil {
        return false, err
    }
    return strings.TrimSpace(string(data)) == "1", nil
}

func (gpio *SysfsGPIO) Close() error {
    // Cleanup if needed
    return nil
}

// Helper function
func writeToFile(path, data string) error {
    return os.WriteFile(path, []byte(data), 0644)
}
```

### GPIO Example Usage

```go
// main.go - GPIO LED control
package main

import (
    "log"
    "time"
)

func main() {
    // Create GPIO controller
    gpio, err := gpio.NewGPIOController("sysfs")
    if err != nil {
        log.Fatalf("Failed to create GPIO controller: %v", err)
    }
    defer gpio.Close()

    const LED_PIN = 17

    // Setup LED pin
    if err := gpio.Export(LED_PIN); err != nil {
        log.Fatalf("Failed to export pin: %v", err)
    }
    defer gpio.Unexport(LED_PIN)

    if err := gpio.SetDirection(LED_PIN, "out"); err != nil {
        log.Fatalf("Failed to set direction: %v", err)
    }

    // Blink LED
    for i := 0; i < 10; i++ {
        gpio.Write(LED_PIN, true)
        time.Sleep(500 * time.Millisecond)
        gpio.Write(LED_PIN, false)
        time.Sleep(500 * time.Millisecond)
        log.Printf("Blink #%d", i+1)
    }
}
```

## I2C Communication

### I2C Abstraction Layer

```go
// i2c.go - I2C abstraction
package i2c

import (
    "fmt"
    "os"
    "syscall"
)

type I2CController interface {
    Write(deviceAddr byte, data []byte) error
    Read(deviceAddr byte, length int) ([]byte, error)
    WriteRead(deviceAddr byte, writeData []byte, readLength int) ([]byte, error)
    Close() error
}

// LinuxI2C implements I2C using Linux i2c-dev
type LinuxI2C struct {
    bus     int
    file    *os.File
    device  string
}

func NewLinuxI2C(bus int) (*LinuxI2C, error) {
    device := fmt.Sprintf("/dev/i2c-%d", bus)

    file, err := os.OpenFile(device, os.O_RDWR, 0600)
    if err != nil {
        return nil, fmt.Errorf("failed to open I2C device: %w", err)
    }

    return &LinuxI2C{
        bus:    bus,
        file:   file,
        device: device,
    }, nil
}

func (i2c *LinuxI2C) Write(deviceAddr byte, data []byte) error {
    // Set slave address
    if err := i2c.setSlaveAddress(deviceAddr); err != nil {
        return err
    }

    // Write data
    _, err := i2c.file.Write(data)
    return err
}

func (i2c *LinuxI2C) Read(deviceAddr byte, length int) ([]byte, error) {
    if err := i2c.setSlaveAddress(deviceAddr); err != nil {
        return nil, err
    }

    data := make([]byte, length)
    _, err := i2c.file.Read(data)
    return data, err
}

func (i2c *LinuxI2C) WriteRead(deviceAddr byte, writeData []byte, readLength int) ([]byte, error) {
    if err := i2c.Write(deviceAddr, writeData); err != nil {
        return nil, err
    }
    return i2c.Read(deviceAddr, readLength)
}

func (i2c *LinuxI2C) Close() error {
    return i2c.file.Close()
}

func (i2c *LinuxI2C) setSlaveAddress(addr byte) error {
    return ioctl(i2c.file.Fd(), I2C_SLAVE, uintptr(addr))
}

// ioctl helper
func ioctl(fd uintptr, cmd uintptr, arg uintptr) error {
    _, _, errno := syscall.Syscall(syscall.SYS_IOCTL, fd, cmd, arg)
    if errno != 0 {
        return errno
    }
    return nil
}

// I2C ioctl constants
const (
    I2C_SLAVE = 0x0703
)
```

### I2C Sensor Example

```go
// sensor.go - I2C temperature sensor
package main

import (
    "fmt"
    "log"
    "time"
)

type TemperatureSensor struct {
    i2c        *i2c.LinuxI2C
    deviceAddr byte
}

func NewTemperatureSensor(bus int, addr byte) (*TemperatureSensor, error) {
    i2c, err := i2c.NewLinuxI2C(bus)
    if err != nil {
        return nil, err
    }

    return &TemperatureSensor{
        i2c:        i2c,
        deviceAddr: addr,
    }, nil
}

func (ts *TemperatureSensor) ReadTemperature() (float64, error) {
    // Read 2 bytes from temperature register (example)
    data, err := ts.i2c.Read(ts.deviceAddr, 2)
    if err != nil {
        return 0, err
    }

    // Convert to temperature (sensor-specific calculation)
    raw := int16(data[0])<<8 | int16(data[1])
    temperature := float64(raw) * 0.0625 // Example conversion

    return temperature, nil
}

func (ts *TemperatureSensor) Close() error {
    return ts.i2c.Close()
}

func main() {
    // Create temperature sensor on I2C bus 1, address 0x48
    sensor, err := NewTemperatureSensor(1, 0x48)
    if err != nil {
        log.Fatalf("Failed to create sensor: %v", err)
    }
    defer sensor.Close()

    // Read temperature every second
    for i := 0; i < 10; i++ {
        temp, err := sensor.ReadTemperature()
        if err != nil {
            log.Printf("Error reading temperature: %v", err)
            continue
        }

        fmt.Printf("Temperature: %.2f°C\n", temp)
        time.Sleep(time.Second)
    }
}
```

## SPI Interface

### SPI Abstraction Layer

```go
// spi.go - SPI abstraction
package spi

import (
    "fmt"
    "os"
    "syscall"
)

type SPIMode uint8

const (
    Mode0 SPIMode = iota // CPOL=0, CPHA=0
    Mode1                // CPOL=0, CPHA=1
    Mode2                // CPOL=1, CPHA=0
    Mode3                // CPOL=1, CPHA=1
)

type SPIController interface {
    Transfer(data []byte) ([]byte, error)
    SetMode(mode SPIMode) error
    SetSpeed(speed uint32) error
    Close() error
}

// LinuxSPI implements SPI using Linux spidev
type LinuxSPI struct {
    file   *os.File
    device string
}

func NewLinuxSPI(bus, device int) (*LinuxSPI, error) {
    devicePath := fmt.Sprintf("/dev/spidev%d.%d", bus, device)

    file, err := os.OpenFile(devicePath, os.O_RDWR, 0600)
    if err != nil {
        return nil, fmt.Errorf("failed to open SPI device: %w", err)
    }

    return &LinuxSPI{
        file:   file,
        device: devicePath,
    }, nil
}

func (spi *LinuxSPI) Transfer(data []byte) ([]byte, error) {
    // SPI transfer (full-duplex)
    rxData := make([]byte, len(data))

    transfer := &spiIocTransfer{
        txBuf:  uint64(uintptr(unsafe.Pointer(&data[0]))),
        rxBuf:  uint64(uintptr(unsafe.Pointer(&rxData[0]))),
        length: uint32(len(data)),
        speed:  1000000, // 1MHz
        delay:  0,
        bits:   8,
    }

    err := spi.ioctl(SPI_IOC_MESSAGE(1), uintptr(unsafe.Pointer(transfer)))
    return rxData, err
}

func (spi *LinuxSPI) SetMode(mode SPIMode) error {
    return spi.ioctl(SPI_IOC_WR_MODE, uintptr(mode))
}

func (spi *LinuxSPI) SetSpeed(speed uint32) error {
    return spi.ioctl(SPI_IOC_WR_MAX_SPEED_HZ, uintptr(speed))
}

func (spi *LinuxSPI) Close() error {
    return spi.file.Close()
}

func (spi *LinuxSPI) ioctl(cmd uintptr, arg uintptr) error {
    _, _, errno := syscall.Syscall(syscall.SYS_IOCTL, spi.file.Fd(), cmd, arg)
    if errno != 0 {
        return errno
    }
    return nil
}
```

## UART/Serial Communication

### UART Abstraction Layer

```go
// uart.go - UART abstraction
package uart

import (
    "bufio"
    "fmt"
    "os"
    "syscall"
    "unsafe"
)

type UARTConfig struct {
    Device   string
    BaudRate uint32
    DataBits uint8
    StopBits uint8
    Parity   string
}

type UARTController interface {
    Write(data []byte) (int, error)
    Read(p []byte) (int, error)
    ReadLine() (string, error)
    Close() error
}

// LinuxUART implements UART using Linux serial ports
type LinuxUART struct {
    file   *os.File
    reader *bufio.Reader
    config UARTConfig
}

func NewLinuxUART(config UARTConfig) (*LinuxUART, error) {
    file, err := os.OpenFile(config.Device, os.O_RDWR|os.O_NOCTTY|os.O_NONBLOCK, 0600)
    if err != nil {
        return nil, fmt.Errorf("failed to open UART device: %w", err)
    }

    if err := configureUART(file.Fd(), config); err != nil {
        file.Close()
        return nil, fmt.Errorf("failed to configure UART: %w", err)
    }

    return &LinuxUART{
        file:   file,
        reader: bufio.NewReader(file),
        config: config,
    }, nil
}

func (uart *LinuxUART) Write(data []byte) (int, error) {
    return uart.file.Write(data)
}

func (uart *LinuxUART) Read(p []byte) (int, error) {
    return uart.file.Read(p)
}

func (uart *LinuxUART) ReadLine() (string, error) {
    return uart.reader.ReadString('\n')
}

func (uart *LinuxUART) Close() error {
    return uart.file.Close()
}

func configureUART(fd uintptr, config UARTConfig) error {
    // Get current settings
    var settings syscall.Termios
    if err := ioctl(fd, syscall.TCGETS, uintptr(unsafe.Pointer(&settings))); err != nil {
        return err
    }

    // Configure baud rate
    settings.Ispeed = syscall.Speed_t(config.BaudRate)
    settings.Ospeed = syscall.Speed_t(config.BaudRate)

    // Configure data bits, stop bits, parity
    settings.Cflag &^= syscall.CSIZE
    switch config.DataBits {
    case 5:
        settings.Cflag |= syscall.CS5
    case 6:
        settings.Cflag |= syscall.CS6
    case 7:
        settings.Cflag |= syscall.CS7
    case 8:
        settings.Cflag |= syscall.CS8
    }

    // Set local mode and enable receiver
    settings.Cflag |= syscall.CLOCAL | syscall.CREAD

    // Configure stop bits
    if config.StopBits == 2 {
        settings.Cflag |= syscall.CSTOPB
    } else {
        settings.Cflag &^= syscall.CSTOPB
    }

    // Configure parity
    switch config.Parity {
    case "even":
        settings.Cflag |= syscall.PARENB
        settings.Cflag &^= syscall.PARODD
    case "odd":
        settings.Cflag |= syscall.PARENB | syscall.PARODD
    default:
        settings.Cflag &^= syscall.PARENB | syscall.PARODD
    }

    // Apply settings
    return ioctl(fd, syscall.TCSETS, uintptr(unsafe.Pointer(&settings)))
}

func ioctl(fd uintptr, cmd uintptr, arg uintptr) error {
    _, _, errno := syscall.Syscall(syscall.SYS_IOCTL, fd, cmd, arg)
    if errno != 0 {
        return errno
    }
    return nil
}
```

### UART Communication Example

```go
// main.go - UART communication
package main

import (
    "fmt"
    "log"
    "time"
)

func main() {
    // Configure UART
    config := uart.UARTConfig{
        Device:   "/dev/ttyS0",
        BaudRate: 115200,
        DataBits: 8,
        StopBits: 1,
        Parity:   "none",
    }

    // Create UART controller
    uart, err := uart.NewLinuxUART(config)
    if err != nil {
        log.Fatalf("Failed to open UART: %v", err)
    }
    defer uart.Close()

    fmt.Printf("UART opened: %s at %d baud\n", config.Device, config.BaudRate)

    // Send hello message
    message := "Hello from RISC-V!\n"
    n, err := uart.Write([]byte(message))
    if err != nil {
        log.Printf("Write error: %v", err)
    } else {
        fmt.Printf("Sent %d bytes: %s", n, message)
    }

    // Read response (with timeout)
    go func() {
        time.Sleep(5 * time.Second)
        uart.Close() // Timeout
    }()

    for {
        line, err := uart.ReadLine()
        if err != nil {
            break
        }
        fmt.Printf("Received: %s", line)
    }
}
```

## ADC (Analog-to-Digital Conversion)

### ADC Abstraction Layer

```go
// adc.go - ADC abstraction
package adc

import (
    "fmt"
    "os"
    "strconv"
    "strings"
)

type ADCController interface {
    ReadChannel(channel int) (int, error)
    GetVoltage(channel int) (float64, error)
    SetReferenceVoltage(voltage float64)
    GetResolution() int
    Close() error
}

// SysfsADC implements ADC using Linux sysfs (for simple ADCs)
type SysfsADC struct {
    basePath        string
    referenceVoltage float64
    resolution      int
}

func NewSysfsADC(device string, refVoltage float64, resolution int) (*SysfsADC, error) {
    basePath := fmt.Sprintf("/sys/bus/iio/devices/%s", device)

    // Check if device exists
    if _, err := os.Stat(basePath); os.IsNotExist(err) {
        return nil, fmt.Errorf("ADC device not found: %s", device)
    }

    return &SysfsADC{
        basePath:        basePath,
        referenceVoltage: refVoltage,
        resolution:      resolution,
    }, nil
}

func (adc *SysfsADC) ReadChannel(channel int) (int, error) {
    path := fmt.Sprintf("%s/in_voltage%d_raw", adc.basePath, channel)

    data, err := os.ReadFile(path)
    if err != nil {
        return 0, fmt.Errorf("failed to read ADC channel %d: %w", channel, err)
    }

    value, err := strconv.Atoi(strings.TrimSpace(string(data)))
    if err != nil {
        return 0, fmt.Errorf("invalid ADC value: %w", err)
    }

    return value, nil
}

func (adc *SysfsADC) GetVoltage(channel int) (float64, error) {
    raw, err := adc.ReadChannel(channel)
    if err != nil {
        return 0, err
    }

    // Convert to voltage
    voltage := float64(raw) * adc.referenceVoltage / float64(adc.resolution)
    return voltage, nil
}

func (adc *SysfsADC) SetReferenceVoltage(voltage float64) {
    adc.referenceVoltage = voltage
}

func (adc *SysfsADC) GetResolution() int {
    return adc.resolution
}

func (adc *SysfsADC) Close() error {
    // No cleanup needed for sysfs
    return nil
}
```

## PWM (Pulse Width Modulation)

### PWM Abstraction Layer

```go
// pwm.go - PWM abstraction
package pwm

import (
    "fmt"
    "os"
    "strconv"
    "strings"
)

type PWMController interface {
    Export(channel int) error
    Unexport(channel int) error
    Enable(channel int) error
    Disable(channel int) error
    SetPeriod(channel int, periodNs uint32) error
    SetDutyCycle(channel int, dutyNs uint32) error
    SetFrequency(channel int, frequencyHz float64) error
    SetDutyCyclePercent(channel int, percent float64) error
    Close() error
}

// SysfsPWM implements PWM using Linux sysfs
type SysfsPWM struct {
    chip   int
    basePath string
}

func NewSysfsPWM(chip int) (*SysfsPWM, error) {
    basePath := fmt.Sprintf("/sys/class/pwm/pwmchip%d", chip)

    if _, err := os.Stat(basePath); os.IsNotExist(err) {
        return nil, fmt.Errorf("PWM chip %d not found", chip)
    }

    return &SysfsPWM{
        chip:     chip,
        basePath: basePath,
    }, nil
}

func (pwm *SysfsPWM) Export(channel int) error {
    exportPath := fmt.Sprintf("%s/export", pwm.basePath)
    return os.WriteFile(exportPath, []byte(strconv.Itoa(channel)), 0644)
}

func (pwm *SysfsPWM) Unexport(channel int) error {
    unexportPath := fmt.Sprintf("%s/unexport", pwm.basePath)
    return os.WriteFile(unexportPath, []byte(strconv.Itoa(channel)), 0644)
}

func (pwm *SysfsPWM) Enable(channel int) error {
    enablePath := fmt.Sprintf("%s/pwm%d/enable", pwm.basePath, channel)
    return os.WriteFile(enablePath, []byte("1"), 0644)
}

func (pwm *SysfsPWM) Disable(channel int) error {
    enablePath := fmt.Sprintf("%s/pwm%d/enable", pwm.basePath, channel)
    return os.WriteFile(enablePath, []byte("0"), 0644)
}

func (pwm *SysfsPWM) SetPeriod(channel int, periodNs uint32) error {
    periodPath := fmt.Sprintf("%s/pwm%d/period", pwm.basePath, channel)
    return os.WriteFile(periodPath, []byte(strconv.Itoa(int(periodNs))), 0644)
}

func (pwm *SysfsPWM) SetDutyCycle(channel int, dutyNs uint32) error {
    dutyPath := fmt.Sprintf("%s/pwm%d/duty_cycle", pwm.basePath, channel)
    return os.WriteFile(dutyPath, []byte(strconv.Itoa(int(dutyNs))), 0644)
}

func (pwm *SysfsPWM) SetFrequency(channel int, frequencyHz float64) error {
    periodNs := uint32(1e9 / frequencyHz)
    return pwm.SetPeriod(channel, periodNs)
}

func (pwm *SysfsPWM) SetDutyCyclePercent(channel int, percent float64) error {
    // Read current period
    periodPath := fmt.Sprintf("%s/pwm%d/period", pwm.basePath, channel)
    periodData, err := os.ReadFile(periodPath)
    if err != nil {
        return fmt.Errorf("failed to read period: %w", err)
    }

    period, err := strconv.Atoi(strings.TrimSpace(string(periodData)))
    if err != nil {
        return fmt.Errorf("invalid period value: %w", err)
    }

    dutyNs := uint32(float64(period) * percent / 100.0)
    return pwm.SetDutyCycle(channel, dutyNs)
}

func (pwm *SysfsPWM) Close() error {
    // Cleanup PWM channels (optional)
    return nil
}
```

## Timer and Interrupt Handling

### Timer Abstraction

```go
// timer.go - Timer abstraction
package timer

import (
    "sync"
    "time"
)

type TimerCallback func()

type TimerController interface {
    Start(interval time.Duration, callback TimerCallback) error
    Stop() error
    IsRunning() bool
    Reset() error
}

type GoTimer struct {
    timer   *time.Ticker
    running bool
    mu      sync.Mutex
    callback TimerCallback
}

func NewGoTimer() *GoTimer {
    return &GoTimer{}
}

func (t *GoTimer) Start(interval time.Duration, callback TimerCallback) error {
    t.mu.Lock()
    defer t.mu.Unlock()

    if t.running {
        return fmt.Errorf("timer already running")
    }

    t.callback = callback
    t.timer = time.NewTicker(interval)
    t.running = true

    go func() {
        for range t.timer.C {
            t.mu.Lock()
            running := t.running
            callback := t.callback
            t.mu.Unlock()

            if running && callback != nil {
                callback()
            }
        }
    }()

    return nil
}

func (t *GoTimer) Stop() error {
    t.mu.Lock()
    defer t.mu.Unlock()

    if !t.running {
        return nil
    }

    t.running = false
    if t.timer != nil {
        t.timer.Stop()
    }

    return nil
}

func (t *GoTimer) IsRunning() bool {
    t.mu.Lock()
    defer t.mu.Unlock()
    return t.running
}

func (t *GoTimer) Reset() error {
    // Implementation for resetting timer
    return nil
}
```

## Hardware Abstraction Layer

### Unified HAL Design

```go
// hal.go - Hardware Abstraction Layer
package hal

import (
    "fmt"
    "sync"
)

type HardwareManager struct {
    gpioControllers map[string]gpio.GPIOController
    i2cControllers  map[string]i2c.I2CController
    spiControllers  map[string]spi.SPIController
    adcControllers  map[string]adc.ADCController
    pwmControllers  map[string]pwm.PWMController
    timers          map[string]timer.TimerController
    mu              sync.RWMutex
}

func NewHardwareManager() *HardwareManager {
    return &HardwareManager{
        gpioControllers: make(map[string]gpio.GPIOController),
        i2cControllers:  make(map[string]i2c.I2CController),
        spiControllers:  make(map[string]spi.SPIController),
        adcControllers:  make(map[string]adc.ADCController),
        pwmControllers:  make(map[string]pwm.PWMController),
        timers:          make(map[string]timer.TimerController),
    }
}

// GPIO management
func (hm *HardwareManager) AddGPIOController(name string, controller gpio.GPIOController) {
    hm.mu.Lock()
    defer hm.mu.Unlock()
    hm.gpioControllers[name] = controller
}

func (hm *HardwareManager) GetGPIOController(name string) (gpio.GPIOController, error) {
    hm.mu.RLock()
    defer hm.mu.RUnlock()

    controller, exists := hm.gpioControllers[name]
    if !exists {
        return nil, fmt.Errorf("GPIO controller '%s' not found", name)
    }

    return controller, nil
}

// Similar methods for other interfaces...

func (hm *HardwareManager) Close() error {
    hm.mu.Lock()
    defer hm.mu.Unlock()

    var errors []error

    // Close all controllers
    for name, controller := range hm.gpioControllers {
        if err := controller.Close(); err != nil {
            errors = append(errors, fmt.Errorf("failed to close GPIO controller '%s': %w", name, err))
        }
    }

    for name, controller := range hm.i2cControllers {
        if err := controller.Close(); err != nil {
            errors = append(errors, fmt.Errorf("failed to close I2C controller '%s': %w", name, err))
        }
    }

    // Add similar cleanup for other controllers...

    if len(errors) > 0 {
        return fmt.Errorf("hardware cleanup errors: %v", errors)
    }

    return nil
}
```

## Real Hardware Examples

### Raspberry Pi Pico (RP2040) with RISC-V

```go
// pico.go - RP2040-specific hardware
package pico

import (
    "machine"
)

func initLED() {
    led := machine.LED
    led.Configure(machine.PinConfig{Mode: machine.PinOutput})
}

func blinkLED() {
    led := machine.LED
    for {
        led.High()
        time.Sleep(500 * time.Millisecond)
        led.Low()
        time.Sleep(500 * time.Millisecond)
    }
}
```

### Milk-V Duo (CV1800B)

```go
// milkv.go - Milk-V Duo specific hardware
package milkv

import (
    "os"
    "syscall"
)

func initGPIO() error {
    // Export GPIO pins
    for _, pin := range []int{17, 18, 27} {
        if err := exportGPIO(pin); err != nil {
            return err
        }
    }
    return nil
}

func exportGPIO(pin int) error {
    file, err := os.OpenFile("/sys/class/gpio/export", os.O_WRONLY, 0644)
    if err != nil {
        return err
    }
    defer file.Close()

    _, err = file.WriteString(fmt.Sprintf("%d", pin))
    return err
}
```

### HiFive Unmatched (SiFive U740)

```go
// hifive.go - HiFive Unmatched specific hardware
package hifive

import (
    "os/exec"
    "strconv"
    "strings"
)

func getCPUTemperature() (float64, error) {
    cmd := exec.Command("cat", "/sys/class/thermal/thermal_zone0/temp")
    output, err := cmd.Output()
    if err != nil {
        return 0, err
    }

    tempStr := strings.TrimSpace(string(output))
    tempMilliC, err := strconv.Atoi(tempStr)
    if err != nil {
        return 0, err
    }

    return float64(tempMilliC) / 1000.0, nil
}
```

## Best Practices

### Error Handling

```go
func safeHardwareOperation() error {
    controller, err := hal.GetGPIOController("main")
    if err != nil {
        return fmt.Errorf("GPIO initialization failed: %w", err)
    }
    defer controller.Close()

    // Use controller safely
    return controller.Write(17, true)
}
```

### Resource Management

```go
func withHardwareResource[T any](resource T, cleanup func(T) error) func(func(T) error) error {
    return func(operation func(T) error) error {
        defer func() {
            if err := cleanup(resource); err != nil {
                log.Printf("Cleanup error: %v", err)
            }
        }()
        return operation(resource)
    }
}
```

### Testing with Mocks

```go
// mock_gpio.go - Mock GPIO for testing
type MockGPIO struct {
    pins map[int]bool
}

func (m *MockGPIO) Write(pin int, value bool) error {
    m.pins[pin] = value
    return nil
}

func (m *MockGPIO) Read(pin int) (bool, error) {
    return m.pins[pin], nil
}

func (m *MockGPIO) Close() error {
    return nil
}
```

## Performance Considerations

### Memory Usage

- **Static allocation** for embedded systems
- **Object pooling** for frequently used objects
- **Memory-mapped I/O** for direct hardware access
- **Avoid garbage collection** pressure

### CPU Usage

- **Interrupt-driven I/O** instead of polling
- **DMA** for bulk data transfers
- **Hardware acceleration** when available
- **Efficient algorithms** for data processing

### Power Management

- **Sleep modes** when idle
- **Clock gating** for unused peripherals
- **Dynamic frequency scaling**
- **Power-aware scheduling**

## Resources

- [RISC-V Hardware Specifications](https://riscv.org/specifications/)
- [Linux Device Drivers](https://www.kernel.org/doc/html/latest/driver-api/)
- [Embedded Linux Systems](https://www.embeddedlinux.org/)
- [Go Embedded Programming](https://golang.org/doc/effective_go.html)

For practical examples, see the [examples](../examples/) directory in this repository.

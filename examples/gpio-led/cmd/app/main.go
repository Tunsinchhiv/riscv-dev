package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"
)

const (
	// GPIO pin number for LED (adjust based on your board)
	LED_PIN = 17

	// Blink interval
	BLINK_INTERVAL = 500 * time.Millisecond
)

// SimulatedGPIO simulates GPIO operations for demonstration
type SimulatedGPIO struct {
	pins map[int]bool // pin number -> state
}

func NewSimulatedGPIO() *SimulatedGPIO {
	return &SimulatedGPIO{
		pins: make(map[int]bool),
	}
}

func (gpio *SimulatedGPIO) Output(pin int) {
	// In simulation, just initialize the pin
	gpio.pins[pin] = false
}

func (gpio *SimulatedGPIO) Toggle(pin int) {
	if state, exists := gpio.pins[pin]; exists {
		gpio.pins[pin] = !state
	} else {
		gpio.pins[pin] = true
	}
}

func (gpio *SimulatedGPIO) Low(pin int) {
	gpio.pins[pin] = false
}

func (gpio *SimulatedGPIO) Read(pin int) bool {
	return gpio.pins[pin]
}

func (gpio *SimulatedGPIO) GetState(pin int) string {
	if gpio.pins[pin] {
		return "HIGH"
	}
	return "LOW"
}

func main() {
	fmt.Println("🚀 RISC-V GPIO LED Example")
	fmt.Printf("Board: %s\n", getBoardInfo())
	fmt.Printf("LED Pin: GPIO%d\n", LED_PIN)
	fmt.Println("⚠️  Running in simulation mode (no physical GPIO access)")

	// Initialize simulated GPIO
	gpio := NewSimulatedGPIO()
	gpio.Output(LED_PIN)

	fmt.Println("✅ GPIO simulation initialized successfully")
	fmt.Printf("🎯 Starting LED blink pattern (interval: %v)\n", BLINK_INTERVAL)

	// Handle graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	blinkCount := 0
	ticker := time.NewTicker(BLINK_INTERVAL)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			// Toggle LED state
			gpio.Toggle(LED_PIN)
			blinkCount++

			state := gpio.GetState(LED_PIN)

			fmt.Printf("💡 LED %s (blink #%d)\n", state, blinkCount)

		case <-sigChan:
			fmt.Println("\n🛑 Shutting down gracefully...")
			// Ensure LED is off when exiting
			gpio.Low(LED_PIN)
			fmt.Printf("✅ LED turned off (final state: %s)\n", gpio.GetState(LED_PIN))
			return
		}
	}
}

// getBoardInfo attempts to identify the RISC-V board
func getBoardInfo() string {
	// Read board information from common locations
	boardFiles := []string{
		"/proc/device-tree/model",
		"/sys/firmware/devicetree/base/model",
		"/etc/hostname",
	}

	for _, file := range boardFiles {
		if data, err := os.ReadFile(file); err == nil {
			return string(data)
		}
	}

	return "Unknown RISC-V Board"
}

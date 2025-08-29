package main

import (
	"fmt"
	"math"
	"math/rand"
	"os"
	"os/signal"
	"syscall"
	"time"
)

const (
	// ADC configuration
	ADC_MAX_VALUE   = 4095 // 12-bit ADC
	ADC_REFERENCE_V = 3.3  // 3.3V reference voltage
	SAMPLE_INTERVAL = 100 * time.Millisecond

	// Sensor configuration
	TEMPERATURE_PIN = 0 // ADC channel for temperature sensor
	LIGHT_PIN       = 1 // ADC channel for light sensor
	PRESSURE_PIN    = 2 // ADC channel for pressure sensor

	// Sensor calibration values (example)
	TEMP_OFFSET     = 500  // ADC offset for 0°C
	TEMP_SCALE      = 10.0 // ADC counts per °C
	LIGHT_MAX_LUX   = 1000 // Maximum lux value
	PRESSURE_OFFSET = 1000 // ADC offset for 0 kPa
	PRESSURE_SCALE  = 50.0 // ADC counts per kPa
)

// SensorData represents readings from all sensors
type SensorData struct {
	Timestamp   time.Time
	Temperature float64     // °C
	LightLevel  float64     // lux
	Pressure    float64     // kPa
	RawADC      map[int]int // Raw ADC values
}

// SensorManager handles sensor reading and processing
type SensorManager struct {
	adcChannels []int
	lastReading SensorData
}

// NewSensorManager creates a new sensor manager
func NewSensorManager() *SensorManager {
	return &SensorManager{
		adcChannels: []int{TEMPERATURE_PIN, LIGHT_PIN, PRESSURE_PIN},
		lastReading: SensorData{
			RawADC: make(map[int]int),
		},
	}
}

// readADCChannel simulates reading from an ADC channel
// In a real implementation, this would interface with actual ADC hardware
func (sm *SensorManager) readADCChannel(channel int) int {
	// Simulate realistic ADC noise and variation
	baseValue := sm.getBaseValueForChannel(channel)
	noise := rand.Intn(21) - 10 // ±10 ADC counts noise
	value := baseValue + noise

	// Clamp to valid ADC range
	if value < 0 {
		value = 0
	}
	if value > ADC_MAX_VALUE {
		value = ADC_MAX_VALUE
	}

	return value
}

// getBaseValueForChannel returns a realistic base value for each sensor type
func (sm *SensorManager) getBaseValueForChannel(channel int) int {
	switch channel {
	case TEMPERATURE_PIN:
		// Room temperature around 20-25°C
		tempC := 20.0 + 5.0*math.Sin(float64(time.Now().Unix())/3600.0) // Daily temperature variation
		return int(tempC*TEMP_SCALE) + TEMP_OFFSET

	case LIGHT_PIN:
		// Light level varies based on time of day
		hour := time.Now().Hour()
		var lightLevel float64
		if hour >= 6 && hour <= 18 {
			// Daylight hours
			lightLevel = 500 + 300*math.Sin(math.Pi*float64(hour-6)/12.0)
		} else {
			// Night time
			lightLevel = 10 + rand.Float64()*20
		}
		return int((lightLevel / LIGHT_MAX_LUX) * ADC_MAX_VALUE)

	case PRESSURE_PIN:
		// Atmospheric pressure around 101.3 kPa with small variations
		pressure := 101.3 + 2.0*math.Sin(float64(time.Now().Unix())/1800.0)
		return int(pressure*PRESSURE_SCALE) + PRESSURE_OFFSET

	default:
		return ADC_MAX_VALUE / 2 // Mid-range value
	}
}

// convertADCToVoltage converts ADC reading to voltage
func (sm *SensorManager) convertADCToVoltage(adcValue int) float64 {
	return float64(adcValue) * ADC_REFERENCE_V / ADC_MAX_VALUE
}

// convertADCToTemperature converts ADC reading to temperature in °C
func (sm *SensorManager) convertADCToTemperature(adcValue int) float64 {
	return float64(adcValue-TEMP_OFFSET) / TEMP_SCALE
}

// convertADCToLightLevel converts ADC reading to light level in lux
func (sm *SensorManager) convertADCToLightLevel(adcValue int) float64 {
	voltage := sm.convertADCToVoltage(adcValue)
	// Simplified light sensor conversion (would be calibrated for specific sensor)
	return voltage * (LIGHT_MAX_LUX / ADC_REFERENCE_V)
}

// convertADCToPressure converts ADC reading to pressure in kPa
func (sm *SensorManager) convertADCToPressure(adcValue int) float64 {
	return float64(adcValue-PRESSURE_OFFSET) / PRESSURE_SCALE
}

// readAllSensors reads data from all configured sensors
func (sm *SensorManager) readAllSensors() SensorData {
	data := SensorData{
		Timestamp: time.Now(),
		RawADC:    make(map[int]int),
	}

	// Read raw ADC values
	for _, channel := range sm.adcChannels {
		rawValue := sm.readADCChannel(channel)
		data.RawADC[channel] = rawValue
	}

	// Convert to physical units
	data.Temperature = sm.convertADCToTemperature(data.RawADC[TEMPERATURE_PIN])
	data.LightLevel = sm.convertADCToLightLevel(data.RawADC[LIGHT_PIN])
	data.Pressure = sm.convertADCToPressure(data.RawADC[PRESSURE_PIN])

	sm.lastReading = data
	return data
}

// displaySensorData formats and displays sensor readings
func (sm *SensorManager) displaySensorData(data SensorData) {
	fmt.Printf("\n🌡️  SENSOR READINGS (%s)\n", data.Timestamp.Format("15:04:05"))
	fmt.Printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

	fmt.Printf("🌡️  Temperature: %6.2f °C\n", data.Temperature)
	fmt.Printf("💡 Light Level:  %6.0f lux\n", data.LightLevel)
	fmt.Printf("📊 Pressure:     %6.2f kPa\n", data.Pressure)

	fmt.Printf("\n🔧 RAW ADC VALUES:\n")
	for channel, value := range data.RawADC {
		voltage := sm.convertADCToVoltage(value)
		sensorName := sm.getSensorName(channel)
		fmt.Printf("  %s (Ch%d): %4d ADC (%5.3fV)\n", sensorName, channel, value, voltage)
	}

	// Environmental assessment
	sm.displayEnvironmentalAssessment(data)
}

// getSensorName returns human-readable sensor name
func (sm *SensorManager) getSensorName(channel int) string {
	switch channel {
	case TEMPERATURE_PIN:
		return "Temperature"
	case LIGHT_PIN:
		return "Light Sensor"
	case PRESSURE_PIN:
		return "Pressure"
	default:
		return fmt.Sprintf("Sensor Ch%d", channel)
	}
}

// displayEnvironmentalAssessment provides environmental insights
func (sm *SensorManager) displayEnvironmentalAssessment(data SensorData) {
	fmt.Printf("\n🏠 ENVIRONMENTAL ASSESSMENT:\n")

	// Temperature assessment
	switch {
	case data.Temperature < 15:
		fmt.Printf("  ❄️  Cool environment (%.1f°C)\n", data.Temperature)
	case data.Temperature > 25:
		fmt.Printf("  ☀️  Warm environment (%.1f°C)\n", data.Temperature)
	default:
		fmt.Printf("  ✅ Comfortable temperature (%.1f°C)\n", data.Temperature)
	}

	// Light level assessment
	switch {
	case data.LightLevel < 50:
		fmt.Printf("  🌙 Low light conditions (%.0f lux)\n", data.LightLevel)
	case data.LightLevel > 500:
		fmt.Printf("  ☀️  Bright environment (%.0f lux)\n", data.LightLevel)
	default:
		fmt.Printf("  💡 Moderate lighting (%.0f lux)\n", data.LightLevel)
	}

	// Pressure assessment
	switch {
	case data.Pressure < 100:
		fmt.Printf("  📉 Low pressure (%.1f kPa)\n", data.Pressure)
	case data.Pressure > 102:
		fmt.Printf("  📈 High pressure (%.1f kPa)\n", data.Pressure)
	default:
		fmt.Printf("  ✅ Normal atmospheric pressure (%.1f kPa)\n", data.Pressure)
	}
}

func main() {
	fmt.Println("📊 RISC-V Sensor Reading Example")
	fmt.Printf("Board: %s\n", getBoardInfo())
	fmt.Printf("ADC Configuration: %d-bit, %.1fV reference\n", 12, ADC_REFERENCE_V)
	fmt.Printf("Sample Interval: %v\n", SAMPLE_INTERVAL)

	// Initialize sensor manager
	sensorMgr := NewSensorManager()

	// Display sensor configuration
	fmt.Printf("\n🔧 CONFIGURED SENSORS:\n")
	for _, channel := range sensorMgr.adcChannels {
		sensorName := sensorMgr.getSensorName(channel)
		fmt.Printf("  Channel %d: %s\n", channel, sensorName)
	}

	fmt.Printf("\n📈 Starting sensor monitoring...\n")
	fmt.Printf("Press Ctrl+C to stop\n\n")

	// Handle graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Main sensor reading loop
	ticker := time.NewTicker(SAMPLE_INTERVAL)
	defer ticker.Stop()

	sampleCount := 0

	for {
		select {
		case <-ticker.C:
			sampleCount++
			data := sensorMgr.readAllSensors()
			sensorMgr.displaySensorData(data)

			// Show sample counter
			fmt.Printf("\n📊 Sample #%d completed\n", sampleCount)
			fmt.Printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

		case <-sigChan:
			fmt.Println("\n🛑 Shutting down sensor monitoring...")
			fmt.Printf("Total samples collected: %d\n", sampleCount)
			fmt.Println("✅ Sensor monitoring stopped")
			return
		}
	}
}

// getBoardInfo attempts to identify the RISC-V board
func getBoardInfo() string {
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

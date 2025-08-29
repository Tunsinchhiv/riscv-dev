package main

import (
	"bufio"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"
)

const (
	SERVER_HOST = "0.0.0.0" // Listen on all interfaces
	SERVER_PORT = "8080"
	SERVER_TYPE = "tcp"
)

type Server struct {
	clients     map[net.Conn]string
	messages    chan string
	newClients  chan net.Conn
	doneClients chan net.Conn
}

func NewServer() *Server {
	return &Server{
		clients:     make(map[net.Conn]string),
		messages:    make(chan string, 100),
		newClients:  make(chan net.Conn),
		doneClients: make(chan net.Conn),
	}
}

func (s *Server) handleConnection(conn net.Conn) {
	defer conn.Close()

	// Get client info
	clientAddr := conn.RemoteAddr().String()
	fmt.Printf("📡 New connection from: %s\n", clientAddr)

	// Send welcome message
	conn.Write([]byte(fmt.Sprintf("Welcome to RISC-V Network Server!\nServer time: %s\nType 'help' for commands.\n\n", time.Now().Format(time.RFC3339))))

	// Read client name
	conn.Write([]byte("Enter your name: "))
	scanner := bufio.NewScanner(conn)
	if !scanner.Scan() {
		return
	}
	clientName := strings.TrimSpace(scanner.Text())
	if clientName == "" {
		clientName = clientAddr
	}

	// Register client
	s.newClients <- conn
	s.clients[conn] = clientName

	fmt.Printf("👤 Client '%s' (%s) joined\n", clientName, clientAddr)

	// Handle client messages
	for scanner.Scan() {
		message := strings.TrimSpace(scanner.Text())
		if message == "" {
			continue
		}

		// Handle commands
		switch strings.ToLower(message) {
		case "help":
			conn.Write([]byte("Available commands:\n"))
			conn.Write([]byte("  help    - Show this help\n"))
			conn.Write([]byte("  time    - Get current server time\n"))
			conn.Write([]byte("  clients - List connected clients\n"))
			conn.Write([]byte("  quit    - Disconnect from server\n"))
			conn.Write([]byte("  <text>  - Send message to all clients\n\n"))
		case "time":
			conn.Write([]byte(fmt.Sprintf("Current server time: %s\n\n", time.Now().Format(time.RFC3339))))
		case "clients":
			conn.Write([]byte(fmt.Sprintf("Connected clients (%d):\n", len(s.clients))))
			for _, name := range s.clients {
				conn.Write([]byte(fmt.Sprintf("  - %s\n", name)))
			}
			conn.Write([]byte("\n"))
		case "quit":
			conn.Write([]byte("Goodbye!\n"))
			return
		default:
			// Broadcast message to all clients
			s.messages <- fmt.Sprintf("[%s] %s: %s", time.Now().Format("15:04:05"), clientName, message)
		}
	}

	// Client disconnected
	s.doneClients <- conn
	fmt.Printf("👋 Client '%s' (%s) disconnected\n", clientName, clientAddr)
}

func (s *Server) broadcastMessages() {
	for {
		select {
		case conn := <-s.newClients:
			clientName := s.clients[conn]
			broadcastMsg := fmt.Sprintf("📢 %s joined the chat\n", clientName)
			s.broadcastToAll(broadcastMsg, conn)
		case conn := <-s.doneClients:
			if clientName, exists := s.clients[conn]; exists {
				delete(s.clients, conn)
				broadcastMsg := fmt.Sprintf("📢 %s left the chat\n", clientName)
				s.broadcastToAll(broadcastMsg, nil)
			}
		case message := <-s.messages:
			s.broadcastToAll(message+"\n", nil)
		}
	}
}

func (s *Server) broadcastToAll(message string, excludeConn net.Conn) {
	for conn := range s.clients {
		if conn != excludeConn {
			conn.Write([]byte(message))
		}
	}
	// Also print to server console
	fmt.Print(message)
}

func (s *Server) startServer() error {
	fmt.Printf("🚀 Starting RISC-V Network Server\n")
	fmt.Printf("Board: %s\n", getBoardInfo())
	fmt.Printf("Listening on: %s:%s\n", SERVER_HOST, SERVER_PORT)
	fmt.Printf("Server type: %s\n", SERVER_TYPE)

	// Start message broadcaster
	go s.broadcastMessages()

	// Listen for connections
	listener, err := net.Listen(SERVER_TYPE, SERVER_HOST+":"+SERVER_PORT)
	if err != nil {
		return fmt.Errorf("failed to start server: %w", err)
	}
	defer listener.Close()

	fmt.Println("✅ Server started successfully!")
	fmt.Println("💡 Try connecting with: telnet localhost 8080")
	fmt.Println("💡 Or use: nc localhost 8080")
	fmt.Println("💡 Press Ctrl+C to stop the server\n")

	// Handle graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Accept connections
	go func() {
		for {
			conn, err := listener.Accept()
			if err != nil {
				log.Printf("❌ Connection error: %v", err)
				continue
			}
			go s.handleConnection(conn)
		}
	}()

	// Wait for shutdown signal
	<-sigChan
	fmt.Println("\n🛑 Shutting down server gracefully...")

	// Close all client connections
	for conn := range s.clients {
		conn.Write([]byte("Server is shutting down. Goodbye!\n"))
		conn.Close()
	}

	fmt.Println("✅ Server shutdown complete")
	return nil
}

func main() {
	server := NewServer()

	// Display system information
	fmt.Printf("🌐 RISC-V Network Server Example\n")
	fmt.Printf("Go version: %s\n", getGoVersion())
	fmt.Printf("Architecture: %s\n", getArchInfo())
	fmt.Printf("Server will listen on port %s\n\n", SERVER_PORT)

	if err := server.startServer(); err != nil {
		log.Fatalf("❌ Server error: %v", err)
	}
}

// Helper functions
func getBoardInfo() string {
	boardFiles := []string{
		"/proc/device-tree/model",
		"/sys/firmware/devicetree/base/model",
		"/etc/hostname",
	}

	for _, file := range boardFiles {
		if data, err := os.ReadFile(file); err == nil {
			return strings.TrimSpace(string(data))
		}
	}
	return "Unknown RISC-V Board"
}

func getGoVersion() string {
	return "Go 1.21+ (cross-compiled for RISC-V)"
}

func getArchInfo() string {
	return "RISC-V 64-bit (RV64GC)"
}

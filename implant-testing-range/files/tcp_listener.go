package main

import (
	"fmt"
	"net"
	"os"
)

// This source file isn't actually used in training-range
// But we compile it to run as the windows "cohab"
// GOOS=windows GOARCH=amd64 go build -o tcp_listener.exe tcp_listener.go
func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: tcp_listener <port>")
		return
	}

	port := os.Args[1]
	address := ":" + port

	listener, err := net.Listen("tcp", address)
	if err != nil {
		fmt.Println("Error starting server:", err)
		return
	}
	defer listener.Close()

	fmt.Println("Listening on port", port, "...")

	for {
		conn, err := listener.Accept()
		if err != nil {
			fmt.Println("Connection error:", err)
			continue
		}

		go handleConnection(conn)
	}
}

func handleConnection(conn net.Conn) {
	defer conn.Close()
	fmt.Println("Client connected:", conn.RemoteAddr())

	conn.Write([]byte("Hello from Go TCP server!\n"))
}

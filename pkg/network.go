package utils

import (
	"fmt"
	"log"
	"net"
	"time"
)

type UDPChecker struct {
	address  string
	timeout  time.Duration
	retries  int
	ispublic string
}

type TCPChecker struct {
	address  string
	timeout  time.Duration
	retries  int
	ispublic string
}

func (c *UDPChecker) Check() *Status {

	s := &Status{
		PingStatus: "down",
	}

	for attempt := 0; attempt <= c.retries; attempt++ {
		if attempt > 0 {
			fmt.Printf("Retry attempt %d/%d\n", attempt, c.retries)
		}

		// Increased timeout for each attempt to account for network variability
		attemptTimeout := c.timeout * time.Duration(attempt+1)

		if err := c.singleCheck(attemptTimeout); err != nil {
			time.Sleep(time.Second * time.Duration(attempt+1)) // Exponential backoff
			continue
		}
		s.PingStatus = "operational"
		break
	}

	return s
}

func (c *UDPChecker) singleCheck(timeout time.Duration) error {

	remoteAddr, err := net.ResolveUDPAddr(c.GetName(), c.address)
	if err != nil {
		return fmt.Errorf("failed to resolve address: %v", err)
	}

	localAddr, err := net.ResolveUDPAddr(c.GetName(), ":0")
	if err != nil {
		return fmt.Errorf("failed to resolve local address: %v", err)
	}

	conn, err := net.DialUDP(c.GetName(), localAddr, remoteAddr)
	if err != nil {
		return fmt.Errorf("failed to connect: %v", err)
	}
	defer conn.Close()
	_, err = conn.Write([]byte("kubestatus"))
	if err != nil {
		return fmt.Errorf("failed to send data: %v", err)
	}

	return nil
}

func (c *TCPChecker) Check() *Status {
	s := &Status{
		PingStatus: "down",
		IsPublic:   c.ispublic,
	}
	conn, err := net.DialTimeout(c.GetName(), c.address, c.timeout)
	if err != nil {
		log.Print("Connecting error: ", err)
		return s
	}
	if conn != nil {
		defer conn.Close()
	}

	return s
}

func (c *TCPChecker) GetName() string { return "tcp" }
func (c *UDPChecker) GetName() string { return "udp" }

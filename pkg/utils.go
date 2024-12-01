package utils

import (
	"net"
	"strings"
	"time"
)

type Status struct {
	PingStatus   string
	HealthStatus string
	IsPublic     string
}

type Pinger interface {
	Check() *Status
	GetName() string
}

func Ping(item string) Pinger {

	svc := strings.Split(item, "|")
	isPublic := svc[3]
	ep := net.JoinHostPort(svc[1], svc[2])
	var checker Pinger

	retries := 1 //TODO(soub4i): make this part of configuration
	timeout := 2 //TODO(soub4i): make this part of configuration
	if svc[0] == "TCP" {

		checker = &UDPChecker{
			ep, time.Duration(timeout), retries, isPublic,
		}
	}
	if svc[0] == "UDP" {
		checker = &UDPChecker{
			ep, time.Duration(timeout), retries, isPublic,
		}
	}

	return checker
}

package utils

import (
	b64 "encoding/base64"
	"log"
	"net"
	"strings"
	"time"

	ctrl "sigs.k8s.io/controller-runtime"

	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/client-go/dynamic"
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

func GetBasicAuthCredentials() (string, string) {

	config := ctrl.GetConfigOrDie()
	dynamic := dynamic.NewForConfigOrDie(config)
	log.Println("Fetching credentials")
	cm, err := GetSecret(dynamic)

	if err != nil {
		log.Println(err)
		return "", ""
	}

	cred, found, err := unstructured.NestedStringMap(cm.UnstructuredContent(), "data")
	if err != nil || !found {
		log.Println("Error fetching credentials", err)
		return "", ""
	}

	u, err := b64.StdEncoding.DecodeString(cred["user"])
	if err != nil {
		log.Println("Error Decode username", err)
		return "", ""
	}

	p, err := b64.StdEncoding.DecodeString(cred["password"])
	if err != nil {
		log.Println("Error Decode password", err)
		return "", ""
	}

	return string(u), string(p)

}

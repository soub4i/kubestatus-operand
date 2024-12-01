package utils

import (
	"context"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/dynamic"
)

const (
	DEFAULT_CM_NAME     = "kubestatus-configmap"
	DEFAULT_SECRET_NAME = "kubestatus-auth-secret"
	DEFAULT_NS          = "kubestatus"
)

func GetCM(dc *dynamic.DynamicClient) (*unstructured.Unstructured, error) {
	iface := dc.Resource(schema.GroupVersionResource{Group: "", Version: "v1", Resource: "configmaps"}).Namespace(DEFAULT_NS)
	return iface.Get(context.TODO(), DEFAULT_CM_NAME, metav1.GetOptions{})
}

func GetSecret(dc *dynamic.DynamicClient) (*unstructured.Unstructured, error) {
	iface := dc.Resource(schema.GroupVersionResource{Group: "", Version: "v1", Resource: "secrets"}).Namespace(DEFAULT_NS)
	return iface.Get(context.TODO(), DEFAULT_SECRET_NAME, metav1.GetOptions{})
}

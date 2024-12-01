package main

import (
	"encoding/json"
	"fmt"
	"html/template"
	utils "kubestatus/pkg"
	"log"
	"net/http"

	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/client-go/dynamic"
	ctrl "sigs.k8s.io/controller-runtime"
)

type Service struct {
	Name     string `json:"name,omitempty"  bson:"name"`
	Status   string `json:"status,omitempty"  bson:"status"`
	IsPublic string `json:"is_public,omitempty"  bson:"is_public"`
}

type KService struct {
	Metadata interface{}
	Spec     struct {
		Ports []map[string]interface{}
	}
}

const (
	PORT = "8080"
)

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
	u, p := utils.GetBasicAuthCredentials()

	tmpl := template.Must(template.ParseFiles("static/index.tpl"))
	tmpl.Execute(w, struct {
		Username string
		Password string
	}{Username: u, Password: p})

}

func statusHandler(w http.ResponseWriter, r *http.Request) {
	config := ctrl.GetConfigOrDie()
	dynamic := dynamic.NewForConfigOrDie(config)
	resources := []Service{}

	cm, err := utils.GetCM(dynamic)
	w.Header().Set("Content-Type", "application/json")

	if err != nil {
		log.Println(err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(resources)
		return
	}

	members, found, err := unstructured.NestedStringMap(cm.UnstructuredContent(), "data")
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		log.Println(err)
		json.NewEncoder(w).Encode(resources)
		return
	}

	if !found || len(members) == 0 {
		log.Println(err)
		w.WriteHeader(http.StatusAccepted)
		json.NewEncoder(w).Encode(resources)
		return
	}

	for svcName, item := range members {
		s := utils.Ping(item).Check()
		resources = append(resources, Service{Name: svcName, Status: s.PingStatus, IsPublic: s.IsPublic})
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(resources)

}

func basicAuth(next http.Handler, user, password string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		cUser, cPass, _ := r.BasicAuth()
		if !(user == cUser && password == cPass) {
			http.Error(w, "Unauthorized.", 401)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func CORSMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*") // change this later
		w.Header().Set("Access-Control-Allow-Credentials", "true")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")

		if r.Method == "OPTIONS" {
			w.WriteHeader(204)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func main() {

	u, p := utils.GetBasicAuthCredentials()
	mux := http.NewServeMux()
	mux.Handle("/", http.HandlerFunc(indexHandler))
	mux.Handle("/status", CORSMiddleware(basicAuth(http.HandlerFunc(statusHandler), u, p)))
	mux.Handle("/healthy", http.HandlerFunc(healthHandler))
	mux.Handle("/ready", http.HandlerFunc(healthHandler))
	log.Println("Starting Server on port " + PORT)
	if err := http.ListenAndServe(fmt.Sprintf(":%s", PORT), mux); err != nil {
		log.Fatal(err)
	}
}

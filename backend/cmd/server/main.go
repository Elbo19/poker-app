package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"poker-app/internal/handler"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", handler.EnableCORS(handler.RootHandler))
	http.HandleFunc("/health", handler.EnableCORS(handler.HealthHandler))
	http.HandleFunc("/api/evaluate", handler.EnableCORS(handler.EvaluateHandler))
	http.HandleFunc("/api/compare", handler.EnableCORS(handler.CompareHandler))
	http.HandleFunc("/api/probability", handler.EnableCORS(handler.ProbabilityHandler))

	addr := fmt.Sprintf(":%s", port)
	log.Printf("Starting poker API server on %s", addr)

	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}

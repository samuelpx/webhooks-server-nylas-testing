package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// CONSTANTS

const PORT = 3000

// METRICS VARS

var (
	requestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "webhook_requests_total",
			Help: "Total number of webhook requests by method",
		},
		[]string{"method"},
	)
	requestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "webhook_request_duration_seconds",
			Help:    "Duration of webhook requests",
			Buckets: []float64{.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5, 10},
		},
		[]string{"method"},
	)
)

func healthCheck(w http.ResponseWriter, r *http.Request) {

	response := map[string]string{
		"status": "healthy",
		"time":   time.Now().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func root(w http.ResponseWriter, r *http.Request) {

	start := time.Now()
	defer func() {

		duration := time.Since(start).Seconds()
		requestDuration.WithLabelValues(r.Method).Observe(duration)

		requestsTotal.WithLabelValues(r.Method).Inc()
	}()

	if r.Method == http.MethodGet {

		challenge := r.URL.Query().Get("challenge")

		if challenge != "" {
			log.Printf("Received challenge code: %s", challenge)
			fmt.Fprint(w, challenge)
			log.Printf("Sending challenge code: %s", challenge)
			return
		}
	}

	if r.Method == http.MethodPost {

		log.Printf("This is the signature: %s\n", r.Header.Get("x-nylas-signature"))

		body, err := io.ReadAll(r.Body)
		if err != nil {
			log.Printf("Error reading body: %v", err)
			http.Error(w, "Error reading the body", http.StatusBadRequest)
			return
		}

		sizeInBytes := len(body)
		sizeInKB := float64(sizeInBytes) / 1024
		sizeInMB := sizeInKB / 1024

		if sizeInMB >= 1 {
			log.Printf("Webhook size: %.2f MB", sizeInMB)
		} else if sizeInKB >= 1 {
			log.Printf("Webhook size: %.2f KB", sizeInKB)
		} else {
			log.Printf("Webhook size: %d bytes", sizeInBytes)
		}

		var prettyJSON bytes.Buffer
		if err := json.Indent(&prettyJSON, body, "", "    "); err != nil {
			log.Printf("Raw body (not JSON ):\n%s", string(body))
		} else {
			log.Printf("Received JSON body:\n%s", prettyJSON.String())
		}
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "Webhook Received")
	}
}

func main() {

	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	http.HandleFunc("/", root)
	http.HandleFunc("/health", healthCheck)
	http.Handle("/metrics", promhttp.Handler())

	serverAddr := ":" + port
	log.Printf("Server starting on port %s...", port)

	if err := http.ListenAndServe(serverAddr, nil); err != nil {
		log.Fatal(err)
	}

}

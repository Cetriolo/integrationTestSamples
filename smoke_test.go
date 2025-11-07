package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"
)

var baseURL = getBaseURL()

func getBaseURL() string {
	url := os.Getenv("API_URL")
	if url == "" {
		url = "http://localhost:8080"
	}
	return url
}

func TestHealthEndpoint(t *testing.T) {
	resp, err := http.Get(baseURL + "/health")
	if err != nil {
		t.Fatalf("Failed to call health endpoint: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}

	var health HealthResponse
	if err := json.NewDecoder(resp.Body).Decode(&health); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	if health.Status != "healthy" {
		t.Errorf("Expected status 'healthy', got '%s'", health.Status)
	}
}

func TestReadinessEndpoint(t *testing.T) {
	resp, err := http.Get(baseURL + "/ready")
	if err != nil {
		t.Fatalf("Failed to call readiness endpoint: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}
}

func TestGetUsers(t *testing.T) {
	resp, err := http.Get(baseURL + "/api/users")
	if err != nil {
		t.Fatalf("Failed to get users: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}

	var users []User
	if err := json.NewDecoder(resp.Body).Decode(&users); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	if len(users) == 0 {
		t.Error("Expected at least one user")
	}
}

func TestCreateAndDeleteUser(t *testing.T) {
	// Create user
	newUser := map[string]string{
		"name":  "Test User",
		"email": "test@example.com",
	}
	body, _ := json.Marshal(newUser)

	resp, err := http.Post(baseURL+"/api/users", "application/json", strings.NewReader(string(body)))
	if err != nil {
		t.Fatalf("Failed to create user: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusCreated {
		bodyBytes, _ := io.ReadAll(resp.Body)
		t.Fatalf("Expected status 201, got %d. Body: %s", resp.StatusCode, string(bodyBytes))
	}

	var createdUser User
	if err := json.NewDecoder(resp.Body).Decode(&createdUser); err != nil {
		t.Fatalf("Failed to decode created user: %v", err)
	}

	if createdUser.ID == 0 {
		t.Error("Expected user ID to be set")
	}

	// Delete user
	req, _ := http.NewRequest("DELETE", fmt.Sprintf("%s/api/users/%d", baseURL, createdUser.ID), nil)
	client := &http.Client{}
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to delete user: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent {
		t.Errorf("Expected status 204, got %d", resp.StatusCode)
	}
}

func TestGetProducts(t *testing.T) {
	resp, err := http.Get(baseURL + "/api/products")
	if err != nil {
		t.Fatalf("Failed to get products: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}

	var products []Product
	if err := json.NewDecoder(resp.Body).Decode(&products); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	if len(products) == 0 {
		t.Error("Expected at least one product")
	}
}

func TestResponseTime(t *testing.T) {
	start := time.Now()
	resp, err := http.Get(baseURL + "/health")
	duration := time.Since(start)

	if err != nil {
		t.Fatalf("Failed to call endpoint: %v", err)
	}
	defer resp.Body.Close()

	if duration > 1*time.Second {
		t.Errorf("Response time too slow: %v", duration)
	}
}

func TestErrorEndpoint(t *testing.T) {
	resp, err := http.Get(baseURL + "/api/error")
	if err != nil {
		t.Fatalf("Failed to call error endpoint: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusInternalServerError {
		t.Errorf("Expected status 500, got %d", resp.StatusCode)
	}
}

func TestNotFoundEndpoint(t *testing.T) {
	resp, err := http.Get(baseURL + "/api/nonexistent")
	if err != nil {
		t.Fatalf("Failed to call endpoint: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNotFound {
		t.Errorf("Expected status 404, got %d", resp.StatusCode)
	}
}

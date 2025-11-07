package main

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/gorilla/mux"
)

type User struct {
	ID        int       `json:"id"`
	Name      string    `json:"name"`
	Email     string    `json:"email"`
	CreatedAt time.Time `json:"created_at"`
}

type Product struct {
	ID    int     `json:"id"`
	Name  string  `json:"name"`
	Price float64 `json:"price"`
	Stock int     `json:"stock"`
}

type HealthResponse struct {
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
	Version   string    `json:"version"`
}

type ErrorResponse struct {
	Error   string `json:"error"`
	Code    int    `json:"code"`
	Message string `json:"message"`
}

var (
	users         = make(map[int]User)
	products      = make(map[int]Product)
	usersMux      sync.RWMutex
	prodMux       sync.RWMutex
	nextUserID    = 1
	nextProductID = 1
)

func main() {
	// Inizializza dati di esempio
	initData()

	r := mux.NewRouter()

	// Health & Status endpoints
	r.HandleFunc("/health", healthCheck).Methods("GET")
	r.HandleFunc("/ready", readinessCheck).Methods("GET")
	r.HandleFunc("/version", versionHandler).Methods("GET")

	// User endpoints
	r.HandleFunc("/api/users", getUsers).Methods("GET")
	r.HandleFunc("/api/users/{id}", getUser).Methods("GET")
	r.HandleFunc("/api/users", createUser).Methods("POST")
	r.HandleFunc("/api/users/{id}", updateUser).Methods("PUT")
	r.HandleFunc("/api/users/{id}", deleteUser).Methods("DELETE")

	// Product endpoints
	r.HandleFunc("/api/products", getProducts).Methods("GET")
	r.HandleFunc("/api/products/{id}", getProduct).Methods("GET")
	r.HandleFunc("/api/products", createProduct).Methods("POST")
	r.HandleFunc("/api/products/{id}", updateProduct).Methods("PUT")

	// Special endpoints for testing
	r.HandleFunc("/api/slow", slowEndpoint).Methods("GET")
	r.HandleFunc("/api/error", errorEndpoint).Methods("GET")
	r.HandleFunc("/api/random", randomEndpoint).Methods("GET")

	log.Println("Server starting on :8080")
	log.Fatal(http.ListenAndServe(":8080", r))
}

func initData() {
	users[1] = User{ID: 1, Name: "Mario Rossi", Email: "mario@example.com", CreatedAt: time.Now()}
	users[2] = User{ID: 2, Name: "Laura Bianchi", Email: "laura@example.com", CreatedAt: time.Now()}
	nextUserID = 3

	products[1] = Product{ID: 1, Name: "Laptop", Price: 999.99, Stock: 10}
	products[2] = Product{ID: 2, Name: "Mouse", Price: 29.99, Stock: 50}
	products[3] = Product{ID: 3, Name: "Keyboard", Price: 79.99, Stock: 30}
	nextProductID = 4
}

// Health Check Handlers
func healthCheck(w http.ResponseWriter, r *http.Request) {
	response := HealthResponse{
		Status:    "healthy",
		Timestamp: time.Now(),
		Version:   "1.0.0",
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func readinessCheck(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"ready":     true,
		"timestamp": time.Now(),
		"checks": map[string]bool{
			"database": true,
			"cache":    true,
		},
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func versionHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]string{
		"version":    "1.0.0",
		"build_date": "2025-11-07",
		"go_version": "1.21",
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// User Handlers
func getUsers(w http.ResponseWriter, r *http.Request) {
	usersMux.RLock()
	defer usersMux.RUnlock()

	userList := make([]User, 0, len(users))
	for _, user := range users {
		userList = append(userList, user)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(userList)
}

func getUser(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		sendError(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	usersMux.RLock()
	user, exists := users[id]
	usersMux.RUnlock()

	if !exists {
		sendError(w, "User not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

func createUser(w http.ResponseWriter, r *http.Request) {
	var user User
	if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
		sendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if user.Name == "" || user.Email == "" {
		sendError(w, "Name and email are required", http.StatusBadRequest)
		return
	}

	usersMux.Lock()
	user.ID = nextUserID
	user.CreatedAt = time.Now()
	users[user.ID] = user
	nextUserID++
	usersMux.Unlock()

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(user)
}

func updateUser(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		sendError(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	usersMux.Lock()
	defer usersMux.Unlock()

	user, exists := users[id]
	if !exists {
		sendError(w, "User not found", http.StatusNotFound)
		return
	}

	var updateData User
	if err := json.NewDecoder(r.Body).Decode(&updateData); err != nil {
		sendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if updateData.Name != "" {
		user.Name = updateData.Name
	}
	if updateData.Email != "" {
		user.Email = updateData.Email
	}
	users[id] = user

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

func deleteUser(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		sendError(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	usersMux.Lock()
	defer usersMux.Unlock()

	if _, exists := users[id]; !exists {
		sendError(w, "User not found", http.StatusNotFound)
		return
	}

	delete(users, id)
	w.WriteHeader(http.StatusNoContent)
}

// Product Handlers
func getProducts(w http.ResponseWriter, r *http.Request) {
	prodMux.RLock()
	defer prodMux.RUnlock()

	productList := make([]Product, 0, len(products))
	for _, product := range products {
		productList = append(productList, product)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(productList)
}

func getProduct(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		sendError(w, "Invalid product ID", http.StatusBadRequest)
		return
	}

	prodMux.RLock()
	product, exists := products[id]
	prodMux.RUnlock()

	if !exists {
		sendError(w, "Product not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(product)
}

func createProduct(w http.ResponseWriter, r *http.Request) {
	var product Product
	if err := json.NewDecoder(r.Body).Decode(&product); err != nil {
		sendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if product.Name == "" || product.Price <= 0 {
		sendError(w, "Name and valid price are required", http.StatusBadRequest)
		return
	}

	prodMux.Lock()
	product.ID = nextProductID
	products[product.ID] = product
	nextProductID++
	prodMux.Unlock()

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(product)
}

func updateProduct(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		sendError(w, "Invalid product ID", http.StatusBadRequest)
		return
	}

	prodMux.Lock()
	defer prodMux.Unlock()

	product, exists := products[id]
	if !exists {
		sendError(w, "Product not found", http.StatusNotFound)
		return
	}

	var updateData Product
	if err := json.NewDecoder(r.Body).Decode(&updateData); err != nil {
		sendError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if updateData.Name != "" {
		product.Name = updateData.Name
	}
	if updateData.Price > 0 {
		product.Price = updateData.Price
	}
	if updateData.Stock >= 0 {
		product.Stock = updateData.Stock
	}
	products[id] = product

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(product)
}

// Special Testing Endpoints
func slowEndpoint(w http.ResponseWriter, r *http.Request) {
	time.Sleep(3 * time.Second)
	response := map[string]string{
		"message": "This endpoint is intentionally slow",
		"delay":   "3s",
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func errorEndpoint(w http.ResponseWriter, r *http.Request) {
	sendError(w, "This endpoint always returns an error", http.StatusInternalServerError)
}

func randomEndpoint(w http.ResponseWriter, r *http.Request) {
	if time.Now().Unix()%2 == 0 {
		response := map[string]interface{}{
			"success": true,
			"random":  time.Now().Unix(),
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	} else {
		sendError(w, "Random error occurred", http.StatusServiceUnavailable)
	}
}

// Helper function
func sendError(w http.ResponseWriter, message string, code int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(ErrorResponse{
		Error:   http.StatusText(code),
		Code:    code,
		Message: message,
	})
}

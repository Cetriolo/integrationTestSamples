.PHONY: help build run test test-smoke test-newman test-k6 test-playwright test-hurl test-all clean docker-build docker-up docker-down

# Variables
APP_NAME=go-api-test
DOCKER_IMAGE=$(APP_NAME):latest
API_URL=http://localhost:8080

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Build & Run
build: ## Build the Go application
	go build -o $(APP_NAME) .

run: build ## Run the application locally
	./$(APP_NAME)

install-deps: ## Install Go dependencies
	go mod download
	go mod tidy

# Docker
docker-build: ## Build Docker image
	docker build -t $(DOCKER_IMAGE) .

docker-run: docker-build ## Run application in Docker
	docker run -p 8080:8080 $(DOCKER_IMAGE)

docker-up: ## Start all services with Docker Compose
	docker-compose up -d api
	@echo "Waiting for API to be ready..."
	@timeout 30 sh -c 'until curl -f $(API_URL)/health > /dev/null 2>&1; do sleep 1; done' || echo "API failed to start"

docker-down: ## Stop all Docker Compose services
	docker-compose down -v

# Testing
test: ## Run Go unit tests
	go test -v -race -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

test-smoke: ## Run smoke tests with Go
	@echo "Running smoke tests..."
	API_URL=$(API_URL) go test -v -run "Test(Health|GetUsers|GetProducts)" ./...

test-newman: ## Run Newman/Postman tests
	@echo "Running Newman tests..."
	newman run tests/postman/collection.json \
		--environment tests/postman/environment.json \
		--reporters cli,htmlextra \
		--reporter-htmlextra-export reports/newman-report.html

test-newman-docker: docker-up ## Run Newman tests with Docker
	docker-compose run --rm newman

test-k6: ## Run k6 performance tests
	@echo "Running k6 tests..."
	k6 run --vus 10 --duration 30s tests/k6/load-test.js

test-k6-smoke: ## Run k6 smoke tests
	@echo "Running k6 smoke tests..."
	k6 run --vus 1 --duration 10s tests/k6/load-test.js

test-k6-docker: docker-up ## Run k6 tests with Docker
	docker-compose run --rm k6

test-playwright: ## Run Playwright tests
	@echo "Running Playwright tests..."
	cd tests/playwright && npm install && npx playwright test

test-playwright-ui: ## Run Playwright tests with UI
	@echo "Running Playwright tests in UI mode..."
	cd tests/playwright && npx playwright test --ui

test-hurl: ## Run Hurl tests
	@echo "Running Hurl tests..."
	hurl --test --variable base_url=$(API_URL) tests/hurl/*.hurl

test-hurl-docker: docker-up ## Run Hurl tests with Docker
	docker-compose run --rm hurl

test-all: test test-smoke test-newman test-k6-smoke test-playwright test-hurl ## Run all tests

test-all-docker: docker-up ## Run all tests with Docker
	@echo "Running all tests with Docker..."
	docker-compose run --rm newman
	docker-compose run --rm k6
	docker-compose run --rm hurl

# CI/CD helpers
ci-test: ## Run tests suitable for CI environment
	go test -v -race -coverprofile=coverage.out ./...
	API_URL=$(API_URL) go test -v -run "Test(Health|Readiness)" ./...

ci-install-tools: ## Install testing tools for CI
	@echo "Installing testing tools..."
	npm install -g newman newman-reporter-htmlextra
	# Install k6
	sudo gpg -k
	sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
	echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
	sudo apt-get update
	sudo apt-get install k6
	# Install Hurl
	VERSION=4.3.0 && \
	curl -LO https://github.com/Orange-OpenSource/hurl/releases/download/$$VERSION/hurl_$${VERSION}_amd64.deb && \
	sudo dpkg -i hurl_$${VERSION}_amd64.deb

# Cleanup
clean: ## Clean build artifacts and test reports
	rm -f $(APP_NAME)
	rm -f coverage.out coverage.html
	rm -rf reports/
	rm -rf tests/playwright/playwright-report/
	rm -rf tests/playwright/test-results/

clean-all: clean docker-down ## Clean everything including Docker resources
	docker rmi $(DOCKER_IMAGE) || true

# Development
dev: ## Run application with hot reload (requires air)
	air

install-dev-tools: ## Install development tools
	go install github.com/cosmtrek/air@latest

# Reports
show-coverage: test ## Show test coverage in browser
	go tool cover -html=coverage.out

show-newman-report: ## Open Newman HTML report in browser
	@if [ -f reports/newman-report.html ]; then \
		open reports/newman-report.html || xdg-open reports/newman-report.html || echo "Please open reports/newman-report.html manually"; \
	else \
		echo "Newman report not found. Run 'make test-newman' first."; \
	fi

show-playwright-report: ## Open Playwright HTML report in browser
	cd tests/playwright && npx playwright show-report

# Linting & Formatting
lint: ## Run Go linter
	golangci-lint run ./...

fmt: ## Format Go code
	go fmt ./...
	goimports -w .

vet: ## Run go vet
	go vet ./...
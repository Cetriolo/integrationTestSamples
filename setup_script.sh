#!/bin/bash

# Setup Script per Go API Test Suite
# Questo script configura automaticamente tutto il necessario per il progetto

set -e

echo "🚀 Setup Go API Test Suite"
echo "=========================="
echo ""

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funzioni helper
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "ℹ️  $1"
}

# Check prerequisiti
check_prerequisites() {
    print_info "Controllo prerequisiti..."

    local missing=0

    # Go
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}')
        print_success "Go installato: $GO_VERSION"
    else
        print_error "Go non trovato. Installa Go 1.21+"
        ((missing++))
    fi

    # Docker
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}')
        print_success "Docker installato: $DOCKER_VERSION"
    else
        print_warning "Docker non trovato. Alcune funzionalità non saranno disponibili"
    fi

    # Docker Compose
    if command -v docker-compose &> /dev/null; then
        print_success "Docker Compose installato"
    else
        print_warning "Docker Compose non trovato"
    fi

    # Node.js
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_success "Node.js installato: $NODE_VERSION"
    else
        print_warning "Node.js non trovato. Playwright tests non disponibili"
    fi

    # Make
    if command -v make &> /dev/null; then
        print_success "Make installato"
    else
        print_error "Make non trovato. Installa make"
        ((missing++))
    fi

    echo ""

    if [ $missing -gt 0 ]; then
        print_error "Prerequisiti mancanti: $missing"
        exit 1
    fi
}

# Crea struttura directory
create_directory_structure() {
    print_info "Creando struttura directory..."

    directories=(
        ".github/workflows"
        "tests/postman"
        "tests/k6"
        "tests/playwright/tests"
        "tests/hurl"
        "reports/newman"
        "reports/k6"
        "reports/playwright"
        "reports/hurl"
    )

    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_success "Creata directory: $dir"
        else
            print_info "Directory già esistente: $dir"
        fi
    done

    echo ""
}

# Setup Go
setup_go() {
    print_info "Setup Go dependencies..."

    if [ -f "go.mod" ]; then
        print_info "go.mod trovato, scaricando dipendenze..."
        go mod download
        go mod tidy
        print_success "Dipendenze Go installate"
    else
        print_warning "go.mod non trovato. Esegui 'go mod init' prima"
    fi

    echo ""
}

# Setup Playwright
setup_playwright() {
    print_info "Setup Playwright..."

    if command -v npm &> /dev/null; then
        cd tests/playwright

        if [ ! -f "package.json" ]; then
            print_warning "package.json non trovato in tests/playwright"
            cd ../..
            return
        fi

        print_info "Installando dipendenze npm..."
        npm install

        print_info "Installando browser Playwright..."
        npx playwright install chromium

        cd ../..
        print_success "Playwright configurato"
    else
        print_warning "npm non trovato, skip Playwright setup"
    fi

    echo ""
}

# Setup tools testing
setup_testing_tools() {
    print_info "Setup testing tools opzionali..."

    # Newman
    if command -v npm &> /dev/null; then
        print_info "Installando Newman globalmente..."
        npm install -g newman newman-reporter-htmlextra 2>/dev/null || {
            print_warning "Newman non installato globalmente. Usa Docker per Newman tests"
        }
    fi

    # k6 (Linux only)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_info "Controllando k6..."
        if ! command -v k6 &> /dev/null; then
            print_warning "k6 non installato. Vedi: https://k6.io/docs/get-started/installation/"
        else
            print_success "k6 già installato"
        fi
    fi

    # Hurl (opzionale)
    if command -v hurl &> /dev/null; then
        print_success "Hurl già installato"
    else
        print_warning "Hurl non installato. Vedi: https://hurl.dev/docs/installation.html"
    fi

    echo ""
}

# Build applicazione
build_application() {
    print_info "Building applicazione Go..."

    if [ -f "main.go" ]; then
        go build -o go-api-test .
        print_success "Applicazione compilata: ./go-api-test"
    else
        print_error "main.go non trovato"
        return 1
    fi

    echo ""
}

# Docker build
docker_build() {
    print_info "Building Docker image..."

    if command -v docker &> /dev/null && [ -f "Dockerfile" ]; then
        docker build -t go-api-test:latest .
        print_success "Docker image creata: go-api-test:latest"
    else
        print_warning "Docker non disponibile o Dockerfile mancante"
    fi

    echo ""
}

# Verifica file necessari
verify_files() {
    print_info "Verificando file necessari..."

    required_files=(
        "main.go"
        "go.mod"
        "Dockerfile"
        "docker-compose.yml"
        "Makefile"
        ".gitignore"
        "tests/postman/collection.json"
        "tests/postman/environment.json"
    )

    local missing=0
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            print_error "File mancante: $file"
            ((missing++))
        fi
    done

    if [ $missing -eq 0 ]; then
        print_success "Tutti i file necessari presenti"
    else
        print_warning "$missing file(i) mancanti"
    fi

    echo ""
}

# Test veloce
quick_test() {
    print_info "Eseguendo test rapido..."

    # Avvia applicazione in background
    ./go-api-test &
    APP_PID=$!

    # Aspetta che sia pronta
    sleep 2

    # Test health endpoint
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        print_success "Health check OK"
    else
        print_error "Health check fallito"
    fi

    # Ferma applicazione
    kill $APP_PID 2>/dev/null || true

    echo ""
}

# Mostra prossimi passi
show_next_steps() {
    echo "═══════════════════════════════════════"
    echo "🎉 Setup completato!"
    echo "═══════════════════════════════════════"
    echo ""
    echo "📋 Prossimi passi:"
    echo ""
    echo "1. Avvia l'applicazione:"
    echo "   make run"
    echo ""
    echo "2. Oppure con Docker:"
    echo "   make docker-up"
    echo ""
    echo "3. Esegui i test:"
    echo "   make test-smoke       # Test veloci Go"
    echo "   make test-newman      # Test API con Newman"
    echo "   make test-k6          # Performance test"
    echo "   make test-playwright  # E2E test"
    echo "   make test-hurl        # Integration test"
    echo "   make test-all         # Tutti i test"
    echo ""
    echo "4. Visualizza i comandi disponibili:"
    echo "   make help"
    echo ""
    echo "📚 Documentazione: README.md"
    echo ""
}

# Main
main() {
    echo ""
    check_prerequisites
    create_directory_structure
    verify_files
    setup_go
    setup_playwright
    setup_testing_tools

    # Opzionale: build
    read -p "Vuoi compilare l'applicazione ora? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        build_application

        read -p "Vuoi eseguire un test rapido? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            quick_test
        fi
    fi

    # Opzionale: Docker
    if command -v docker &> /dev/null; then
        read -p "Vuoi buildare l'immagine Docker? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker_build
        fi
    fi

    show_next_steps
}

# Run
main
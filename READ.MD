Go API Testing Suite - Documentazione Completa

Un'applicazione Go completa con suite di testing avanzata che include smoke testing, integration testing, performance testing e E2E testing utilizzando le migliori pratiche e tecnologie moderne.
📋 Indice

    Panoramica
    Tecnologie Utilizzate
    Struttura del Progetto
    Quick Start
    API Endpoints
    Testing
    CI/CD
    Best Practices

🎯 Panoramica

Questo progetto dimostra un approccio completo al testing di API in Go, implementando:

    REST API completa con CRUD operations
    5 approcci diversi di testing (Go, Newman, k6, Playwright, Hurl)
    GitHub Actions per CI/CD automatizzato
    Docker e Docker Compose per ambiente isolato
    Multiple test types: Unit, Smoke, Integration, Performance, E2E

Perché questa architettura?

    Go Direct Tests: Veloce, nativo, perfetto per smoke tests
    Newman/Postman: Standard industriale per API testing, ottima documentazione
    k6: Eccellente per performance testing e load testing
    Playwright: Moderno, potente per E2E e API testing
    Hurl: Leggero, dichiarativo, perfetto per CI/CD

🛠 Tecnologie Utilizzate
Backend

    Go 1.21: Linguaggio principale
    Gorilla Mux: HTTP router e URL matcher

Testing Frameworks

    Go testing: Test nativi
    Newman: CLI runner per Postman
    k6: Load testing tool moderno
    Playwright: E2E testing framework
    Hurl: Declarative HTTP testing

DevOps

    Docker: Containerizzazione
    GitHub Actions: CI/CD
    Make: Task automation

📁 Struttura del Progetto

.
├── main.go                          # Applicazione Go principale
├── smoke_test.go                    # Smoke tests in Go
├── go.mod                           # Go dependencies
├── Dockerfile                       # Docker image
├── docker-compose.yml               # Orchestrazione servizi
├── Makefile                         # Automazione task
│
├── .github/
│   └── workflows/
│       ├── main.yml                 # Pipeline CI/CD principale
│       ├── go-tests.yml             # Go smoke tests
│       ├── newman.yml               # Newman tests
│       ├── k6.yml                   # k6 performance tests
│       ├── playwright.yml           # Playwright E2E tests
│       └── hurl.yml                 # Hurl integration tests
│
├── tests/
│   ├── postman/
│   │   ├── collection.json         # Postman collection
│   │   └── environment.json        # Environment variables
│   │
│   ├── k6/
│   │   └── load-test.js            # k6 test scenarios
│   │
│   ├── playwright/
│   │   ├── playwright.config.js    # Playwright config
│   │   ├── package.json            # Node dependencies
│   │   └── tests/
│   │       └── api.spec.js         # Test specs
│   │
│   └── hurl/
│       └── api-tests.hurl          # Hurl test suite
│
└── reports/                         # Test reports directory

🚀 Quick Start
Prerequisiti

    Go 1.21+
    Docker & Docker Compose
    Node.js 20+ (per Playwright e Newman)
    Make

Installazione

    Clone il repository

bash

git clone https://github.com/yourusername/go-api-test.git
cd go-api-test

    Installa le dipendenze Go

bash

make install-deps

    Build l'applicazione

bash

make build

    Avvia l'applicazione

bash

make run

L'API sarà disponibile su http://localhost:8080
Test rapido
bash

# Verifica che l'API sia funzionante
curl http://localhost:8080/health

📡 API Endpoints
Health & Status

Endpoint	Method	Descrizione
/health	GET	Health check
/ready	GET	Readiness check
/version	GET	Versione applicazione

Users

Endpoint	Method	Descrizione
/api/users	GET	Lista tutti gli utenti
/api/users/{id}	GET	Ottieni singolo utente
/api/users	POST	Crea nuovo utente
/api/users/{id}	PUT	Aggiorna utente
/api/users/{id}	DELETE	Elimina utente

Products

Endpoint	Method	Descrizione
/api/products	GET	Lista tutti i prodotti
/api/products/{id}	GET	Ottieni singolo prodotto
/api/products	POST	Crea nuovo prodotto
/api/products/{id}	PUT	Aggiorna prodotto

Test Endpoints

Endpoint	Method	Descrizione
/api/slow	GET	Endpoint lento (3s delay)
/api/error	GET	Ritorna sempre errore 500
/api/random	GET	Risposta casuale success/error

Esempi di Request

Creare un utente:
bash

curl -X POST http://localhost:8080/api/users \
-H "Content-Type: application/json" \
-d '{
"name": "Mario Rossi",
"email": "mario@example.com"
}'

Creare un prodotto:
bash

curl -X POST http://localhost:8080/api/products \
-H "Content-Type: application/json" \
-d '{
"name": "Laptop",
"price": 999.99,
"stock": 10
}'

🧪 Testing
1. Go Direct Tests (Smoke Tests)

Esegui localmente:
bash

make test-smoke

Caratteristiche:

    ✅ Veloci (< 1 secondo)
    ✅ Nessuna dipendenza esterna
    ✅ Perfetti per smoke testing
    ✅ Facili da debuggare

Test inclusi:

    Health check
    Readiness check
    GET users
    CREATE/DELETE user
    GET products
    Response time validation

2. Newman/Postman Tests

Esegui localmente:
bash

make test-newman

Con Docker:
bash

make test-newman-docker

Caratteristiche:

    ✅ Standard industriale
    ✅ Ottima documentazione auto-generata
    ✅ Facile da mantenere
    ✅ Report HTML dettagliati

Test inclusi:

    Health checks con assertions
    CRUD completo su Users
    CRUD completo su Products
    Error handling
    Response structure validation

3. k6 Performance Tests

Smoke test:
bash

make test-k6-smoke

Load test completo:
bash

make test-k6

Con Docker:
bash

make test-k6-docker

Caratteristiche:

    ✅ Scritto in JavaScript
    ✅ Metriche dettagliate
    ✅ Thresholds configurabili
    ✅ Ottimo per CI/CD

Scenari disponibili:

    Smoke Test: 1 VU, 30 secondi
    Load Test: 10-200 VU, ramping graduale
    Stress Test: Fino a 400 VU

Metriche monitorate:

    Request duration (p95, p99)
    Error rate
    Request per second
    Custom metrics

4. Playwright Tests

Esegui localmente:
bash

make test-playwright

Con UI:
bash

make test-playwright-ui

Caratteristiche:

    ✅ Moderno e veloce
    ✅ Ottimo per API testing
    ✅ Report HTML interattivi
    ✅ Video e screenshot on failure

Test inclusi:

    Workflow completi (create-read-update-delete)
    Validazione struttura response
    Error handling
    Test paralleli
    Retry automatici

5. Hurl Tests

Esegui localmente:
bash

make test-hurl

Con Docker:
bash

make test-hurl-docker

Caratteristiche:

    ✅ Sintassi dichiarativa
    ✅ Estremamente leggero
    ✅ Perfetto per CI/CD
    ✅ Captures e assertions potenti

Test inclusi:

    Catena di test con variable capture
    Assertions su JSON
    Duration checks
    Status code validation

Eseguire tutti i test
bash

# Localmente (richiede API in esecuzione)
make test-all

# Con Docker (gestisce tutto automaticamente)
make test-all-docker

🔄 CI/CD con GitHub Actions

Il progetto include 6 workflow GitHub Actions:
1. Main CI/CD Pipeline (.github/workflows/main.yml)

Pipeline principale che orchestra tutti i test:
yaml

Build → Unit Tests → Smoke Tests → Integration Tests → Performance Tests → Deploy

Trigger:

    Push su main e develop
    Pull requests
    Manual dispatch

Jobs:

    Build e push Docker image
    Unit tests con coverage
    Smoke tests con Go
    Integration tests con Hurl
    API tests con Newman
    E2E tests con Playwright
    Performance tests con k6 (solo su main)
    Deployment automatico (solo su main)

2. Go Direct Tests (.github/workflows/go-tests.yml)

Esegue:

    Smoke tests nativi in Go
    Full test suite con coverage
    Upload coverage su Codecov

Quando: Su ogni push e PR
3. Newman Tests (.github/workflows/newman.yml)

Esegue:

    API tests completi con Postman/Newman
    Genera report HTML
    Commenta i risultati su PR

Quando: Su ogni push e PR
4. k6 Performance Tests (.github/workflows/k6.yml)

Esegue:

    Smoke test (sempre)
    Load test (schedulato o manual)
    Stress test (solo manual)

Quando:

    Smoke: Su ogni push su main
    Load: Lunedì alle 2 AM o manual
    Stress: Solo manual dispatch

5. Playwright Tests (.github/workflows/playwright.yml)

Esegue:

    E2E tests completi
    Genera report con video e screenshot
    Upload artifacts

Quando: Su ogni push e PR
6. Hurl Tests (.github/workflows/hurl.yml)

Esegue:

    Integration tests dichiarativi
    Genera report JUnit
    Summary dettagliata

Quando: Su ogni push e PR
Visualizzare i risultati

Tutti i workflow generano:

    GitHub Summary: Visibile nella tab Actions
    Artifacts: Report scaricabili
    PR Comments: Risultati automatici sulle PR
    Status badges: Per il README

Secrets richiesti
yaml

# GitHub Secrets da configurare:
GITHUB_TOKEN            # Automatico
TEST_ENV_URL           # URL ambiente di test
CODECOV_TOKEN          # Per upload coverage (opzionale)

🐳 Docker
Build immagine
bash

make docker-build

Run con Docker
bash

make docker-run

Docker Compose
bash

# Start tutti i servizi
make docker-up

# Stop tutti i servizi
make docker-down

# Run test specifico
docker-compose run newman
docker-compose run k6
docker-compose run hurl

Multi-stage build

Il Dockerfile usa multi-stage build per immagini ottimizzate:
dockerfile

# Stage 1: Build
FROM golang:1.21-alpine AS builder
# ... build logic ...

# Stage 2: Runtime
FROM alpine:latest
# ... runtime con solo il binario ...

Vantaggi:

    Immagine finale molto piccola (~10MB)
    Nessun tool di build in produzione
    Sicurezza aumentata

📊 Reports
Visualizzare i report
bash

# Coverage report
make show-coverage

# Newman HTML report
make show-newman-report

# Playwright report
make show-playwright-report

Tipi di report generati

    Go Coverage: coverage.html
    Newman: reports/newman-report.html
    k6: reports/k6-summary.json
    Playwright: tests/playwright/playwright-report/
    Hurl: reports/hurl/

🎯 Best Practices Implementate
Testing Pyramid

         /\
        /E2\      ← Playwright (pochi, critici)
       /────\
      /Integ\     ← Hurl, Newman (medi, API)
     /──────\
    / Smoke  \    ← Go, k6 smoke (molti, veloci)
/──────────\
/   Unit     \  ← Go tests (moltissimi, rapidi)
/──────────────\

1. Smoke Tests First

Prima di eseguire test costosi, verifica sempre:

    Health endpoint
    Connettività base
    Struttura response minima

2. Fail Fast

Test organizzati per fallire velocemente:
yaml

smoke → integration → performance → e2e

Se i smoke tests falliscono, gli altri non partono.
3. Test Independence

Ogni test è indipendente:

    Nessun shared state
    Cleanup dopo ogni test
    Dati di test generati dinamicamente

4. Meaningful Assertions
   go

// ❌ Bad
assert.Equal(t, 200, resp.StatusCode)

// ✅ Good
assert.Equal(t, http.StatusOK, resp.StatusCode,
"Health endpoint should return 200 OK")

5. Test Data Management

   Go tests: In-memory data
   Integration tests: Test fixtures
   Load tests: Generazione dinamica

6. Parallel Execution
   go

t.Run("parallel tests", func(t *testing.T) {
t.Parallel()
// test code
})

7. Retry Logic

   Playwright: 2 retry su CI
   k6: Retry automatici configurabili
   Newman: Bail on first failure

8. Timeouts

Tutti i test hanno timeout configurati:

    Smoke: 30s
    Integration: 2m
    Performance: 10m

🔧 Troubleshooting
API non si avvia
bash

# Verifica le porte
lsof -i :8080

# Verifica i log
docker logs <container-id>

Test falliscono localmente
bash

# Pulisci tutto e ricomincia
make clean-all
make docker-build
make docker-up
make test-all-docker

Newman non trova la collection
bash

# Verifica il path
ls -la tests/postman/collection.json

# Verifica il formato JSON
jq . tests/postman/collection.json

k6 errori di connessione
bash

# Verifica che l'API sia raggiungibile
curl http://localhost:8080/health

# Usa API_URL corretto
API_URL=http://localhost:8080 k6 run tests/k6/load-test.js

📚 Risorse Aggiuntive

    Documentazione Go
    Newman CLI
    k6 Documentation
    Playwright Docs
    Hurl Tutorial

🤝 Contributing

    Fork il progetto
    Crea il tuo feature branch (git checkout -b feature/AmazingFeature)
    Commit le modifiche (git commit -m 'Add some AmazingFeature')
    Push sul branch (git push origin feature/AmazingFeature)
    Apri una Pull Request

📄 License

MIT License - vedi file LICENSE per dettagli
👤 Autore

Il tuo nome - @yourtwitter
🌟 Acknowledgments

    Gorilla Mux per il routing
    Testcontainers per integration testing
    La community Go per le best practices
    GitHub Actions per CI/CD gratuito


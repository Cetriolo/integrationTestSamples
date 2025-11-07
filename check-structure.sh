#!/bin/bash

echo "🔍 Verificando la struttura del progetto..."

files=(
    "main.go"
    "smoke_test.go"
    "go.mod"
    "go.sum"
    "Dockerfile"
    "docker-compose.yml"
    "Makefile"
    ".gitignore"
    "README.md"
    "tests/postman/collection.json"
    "tests/postman/environment.json"
    "tests/k6/load-test.js"
    "tests/playwright/playwright.config.js"
    "tests/playwright/package.json"
    "tests/playwright/tests/api.spec.js"
    "tests/hurl/api-tests.hurl"
    ".github/workflows/main.yml"
)

missing=0
for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Manca: $file"
        ((missing++))
    else
        echo "✅ Trovato: $file"
    fi
done

if [ $missing -eq 0 ]; then
    echo ""
    echo "🎉 Tutti i file necessari sono presenti!"
else
    echo ""
    echo "⚠️  Mancano $missing file(i)"
fi
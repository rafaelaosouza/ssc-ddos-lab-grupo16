#!/usr/bin/env bash
set -euo pipefail

docker exec ids sh -c ': > /var/log/suricata/fast.log' 2>/dev/null || true
docker exec vitima nft flush ruleset >/dev/null 2>&1 || true

echo ">> Disparando SYN flood por 8s"
bash ataques/atacar_syn.sh 8 >/dev/null 2>&1 || true
sleep 2

echo ">> Disparando Slowloris por 12s"
bash ataques/atacar_slowloris.sh 300 12 >/dev/null 2>&1 || true
docker exec atacante pkill -f slowloris.py >/dev/null 2>&1 || true
sleep 2

echo ">> Alertas gerados pelo Suricata"
docker exec ids sh -c 'cat /var/log/suricata/fast.log' | grep -E "SYN flood|Slowloris" || echo "nenhum alerta registrado"

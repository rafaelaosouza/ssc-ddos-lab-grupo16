#!/usr/bin/env bash
set -euo pipefail

cenario="${1:-baseline}"
total="${2:-50}"

arquivo_csv="resultados/resultados.csv"
mkdir -p resultados

amostras=$(docker exec cliente sh -c '
  i=0
  while [ $i -lt '"$total"' ]; do
    curl -s -o /dev/null -w "%{http_code} %{time_total}\n" --max-time 2 http://vitima/ 2>/dev/null || echo "000 2"
    i=$((i + 1))
  done
')

sucessos=$(echo "$amostras" | awk '$1=="200"{c++} END{print c+0}')
disponibilidade=$(awk "BEGIN{printf \"%.1f\", $sucessos * 100 / $total}")
tempo_medio_ms=$(echo "$amostras" | awk '$1=="200"{s+=$2; n++} END{if(n>0) printf "%.1f", (s/n)*1000; else print "0"}')

cpu=$(docker stats vitima --no-stream --format "{{.CPUPerc}}")
cpu_num=$(echo "$cpu" | tr -d '%')

syn_recv=$(docker exec vitima awk '$2 ~ /:0050$/ && $4=="03"{c++} END{print c+0}' /proc/net/tcp)
established=$(docker exec vitima awk '$2 ~ /:0050$/ && $4=="01"{c++} END{print c+0}' /proc/net/tcp)

if [ ! -f "$arquivo_csv" ]; then
    echo "cenario,disponibilidade,tempo_medio_ms,cpu,syn_recv,established" > "$arquivo_csv"
fi
echo "$cenario,$disponibilidade,$tempo_medio_ms,$cpu_num,$syn_recv,$established" >> "$arquivo_csv"

printf "%-26s | disponibilidade %6s%% | tempo medio %8s ms | CPU %7s | SYN-RECV %5s | ESTABLISHED %5s\n" \
    "$cenario" "$disponibilidade" "$tempo_medio_ms" "$cpu" "$syn_recv" "$established"

#!/usr/bin/env bash
set -euo pipefail

acao="${1:-on}"

if [ "$acao" = "on" ]; then
    docker exec vitima nft -f /etc/firewall.nft
    echo "firewall ativado"
else
    docker exec vitima nft flush ruleset
    echo "firewall desativado"
fi

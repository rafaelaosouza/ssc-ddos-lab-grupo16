#!/usr/bin/env bash
set -euo pipefail

acao="${1:-on}"

if [ "$acao" = "on" ]; then
    docker exec vitima sh -c 'cp /configs/defesa.conf /etc/nginx/nginx.conf && nginx -s reload'
    echo "defesa do nginx ativada"
else
    docker exec vitima sh -c 'cp /configs/base.conf /etc/nginx/nginx.conf && nginx -s reload'
    echo "defesa do nginx desativada"
fi

#!/bin/sh
cp /configs/base.conf /etc/nginx/nginx.conf
exec /docker-entrypoint.sh "$@"

#!/bin/sh
# Entrypoint for the Moon SSH (SNI-only) container.
# Makes sure the persistent data directory exists and the self-signed TLS
# certificate can be generated before handing over to the Node process.
set -e

DATA_DIR="${DATA_DIR:-/app/data}"
mkdir -p "$DATA_DIR"

if ! command -v openssl >/dev/null 2>&1; then
  echo "[entrypoint] WARNING: openssl binary not found -- the SNI-only TLS listener will be disabled." >&2
fi

echo "[entrypoint] data dir: $DATA_DIR"
echo "[entrypoint] HTTP port: ${PORT:-3000} | TLS port: ${TLS_PORT:-8443} | SNI: ${SNI_HOST:-youtube.com}"

exec "$@"

#!/bin/sh
# Builds the repository a device reads into public/ (or the directory given):
# makecatalogs build packs each item's tree into zips, compiles the catalogs
# and checks the result. Set MAKECATALOGS to a makecatalogs that is not on PATH.
set -eu
cd "$(dirname "$0")"
exec "${MAKECATALOGS:-makecatalogs}" build . -o "${1:-public}" \
  --location-prefix packages/harness

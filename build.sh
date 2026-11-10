#!/bin/sh
# Builds the repository a device reads into public/ (or the directory given):
# packs each item's trees into zips, compiles the catalogs and
# checks the result. Set MAKECATALOGS to a makecatalogs that is not on PATH.
set -eu
out=${1:-public}
mc=${MAKECATALOGS:-makecatalogs}
cd "$(dirname "$0")"

rm -rf -- "$out"
mkdir -p "$out/manifests" "$out/packages-info"
cp placements.yaml "$out/"
cp -R templates "$out/"
cp manifests/*.yaml "$out/manifests/"
for item in items/*.yaml; do
  name=$(basename "$item" .yaml)
  "$mc" zip-item --placements placements.yaml --item "$item" \
    --trees "item-trees/$name" --location-prefix packages/harness \
    -o "$out" > "$out/packages-info/$name.yaml"
done
"$mc" "$out"
"$mc" -check "$out"

#!/usr/bin/env sh
set -eu

INPUT_FILE="${1:-./ai-track-docs/architecture.mmd}"
OUTPUT_FILE="${2:-./BuildOutput/architecture.svg}"
PUPPETEER_CONFIG_FILE="${3:-./scripts/mermaid-puppeteer-config.json}"

if [ ! -f "$INPUT_FILE" ]; then
  echo "Architecture diagram source not found: $INPUT_FILE" >&2
  exit 1
fi

if [ ! -f "$PUPPETEER_CONFIG_FILE" ]; then
  echo "Puppeteer config not found: $PUPPETEER_CONFIG_FILE" >&2
  exit 1
fi

OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR"

echo "[validate-architecture] Rendering Mermaid diagram from $INPUT_FILE"
npx --yes @mermaid-js/mermaid-cli@10.9.1 -i "$INPUT_FILE" -o "$OUTPUT_FILE" -p "$PUPPETEER_CONFIG_FILE"

echo "[validate-architecture] Render successful: $OUTPUT_FILE"

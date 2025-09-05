#!/usr/bin/env bash
# Regenerate Pizza Stack architecture diagram(s)
set -euo pipefail

DOT_FILE="docs/architecture.dot"
PNG_FILE="docs/architecture.png"
SVG_FILE="docs/architecture.svg"

if ! command -v dot >/dev/null 2>&1; then
  echo "Error: graphviz is not installed. Install with: sudo apt update && sudo apt install graphviz -y"
  exit 1
fi

if [[ ! -f "$DOT_FILE" ]]; then
  echo "Error: $DOT_FILE not found. Run from project root (./render-diagram.sh)."
  exit 1
fi

echo "Rendering Pizza Stack architecture diagram..."
dot -Tpng "$DOT_FILE" -o "$PNG_FILE"
dot -Tsvg "$DOT_FILE" -o "$SVG_FILE"

echo "✅ Done:"
echo " - $PNG_FILE"
echo " - $SVG_FILE"

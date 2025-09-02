#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
rm -f hello.zip
zip -q hello.zip handler.py
echo "Built lambda/hello.zip"

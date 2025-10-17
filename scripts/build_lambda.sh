#!/usr/bin/env bash
set -euo pipefail
# Minimal lambda build script — installs pure-python deps into a build folder and zips them with the handler
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAMBDA_DIR="$ROOT_DIR/lambda"
BUILD_DIR="$ROOT_DIR/build_lambda"

echo "Building lambda in $LAMBDA_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/python"

if [ -f "$LAMBDA_DIR/requirements.txt" ]; then
  echo "Installing Python packages from requirements.txt"
  pip install --upgrade -r "$LAMBDA_DIR/requirements.txt" --target "$BUILD_DIR/python"
else
  echo "No requirements.txt found in $LAMBDA_DIR — skipping pip install"
fi

echo "Copying lambda source files"
cp "$LAMBDA_DIR"/*.py "$BUILD_DIR/python/" 2>/dev/null || true

pushd "$BUILD_DIR" >/dev/null
zip -r "$LAMBDA_DIR/function.zip" .
popd >/dev/null

echo "Created $LAMBDA_DIR/function.zip"

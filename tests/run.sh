#!/bin/bash
# Compiles the testable half of the app together with its tests and runs them.
set -euo pipefail
cd "$(dirname "$0")/.."

BIN="$(mktemp -d)/EncoderTests"
swiftc src/Encoder.swift tests/main.swift -o "$BIN" \
  -target "$(uname -m)-apple-macosx13.0"
"$BIN"

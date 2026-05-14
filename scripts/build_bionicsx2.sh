#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$REPO_ROOT/build-ios"
TOOLCHAIN="$REPO_ROOT/cmake/ios.toolchain.cmake"
PARALLEL="$(sysctl -n hw.logicalcpu 2>/dev/null || echo 4)"

echo ">>> Configuring BionicSX2 for iOS..."
cmake -S "$REPO_ROOT" -B "$BUILD_DIR" \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_QT=OFF -DENABLE_OPENGL=OFF \
    -DENABLE_VULKAN=OFF -DUSE_SDL=OFF \
    -DBUILD_TESTS=OFF \
    -G Ninja

echo ">>> Building BionicSX2..."
cmake --build "$BUILD_DIR" --config Release -j"$PARALLEL" 2>&1 | tee "$BUILD_DIR/build.log"

echo ""
echo "===== BUILD COMPLETE ====="
echo "Output in: $BUILD_DIR"

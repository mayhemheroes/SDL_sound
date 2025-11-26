#!/bin/bash
set -euo pipefail

# RLENV Build Script
# This script rebuilds the application from source located at /rlenv/source/sdl-sound/
#
# Original image: ghcr.io/mayhemheroes/sdl_sound:main
# Git revision: f245e080f0305b35ab9b3dae19e355347a9d08d3

# ============================================================================
# Environment Variables
# ============================================================================
export CC=clang
export CXX=clang++
export LD_LIBRARY_PATH=/install/lib

# ============================================================================
# REQUIRED: Change to Source Directory
# ============================================================================
cd /rlenv/source/sdl-sound/

# ============================================================================
# Clean Previous Build (recommended)
# ============================================================================
# Remove old build artifacts to ensure fresh rebuild
rm -rf build/ 2>/dev/null || true
rm -f /SDL_sound-fuzzer 2>/dev/null || true

# Clean install directory to avoid permission issues during make install
# (files created by root in Dockerfile can't have permissions changed by unprivileged user)
rm -rf /install/* 2>/dev/null || true

# ============================================================================
# Build Commands (NO NETWORK, NO PACKAGE INSTALLATION)
# ============================================================================
# Create build directory and install directory
mkdir build
mkdir -p /install

# Configure with CMake
cd build
CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/install .. -DSDLSOUND_INSTRUMENT=1

# Build with single core (more reliable for rebuilds)
make -j1

# Install libraries to /install prefix
make install

# ============================================================================
# Copy Artifacts (use 'cat >' for busybox compatibility)
# ============================================================================
# Copy fuzzer binary to expected location
cat /rlenv/source/sdl-sound/build/fuzz/SDL_sound-fuzzer > /SDL_sound-fuzzer

# ============================================================================
# Set Permissions
# ============================================================================
chmod 777 /SDL_sound-fuzzer 2>/dev/null || true

# ============================================================================
# REQUIRED: Verify Build Succeeded
# ============================================================================
if [ ! -f /SDL_sound-fuzzer ]; then
    echo "Error: Build artifact not found at /SDL_sound-fuzzer"
    exit 1
fi

# Verify executable bit
if [ ! -x /SDL_sound-fuzzer ]; then
    echo "Warning: Build artifact is not executable"
fi

# Verify file size
SIZE=$(stat -c%s /SDL_sound-fuzzer 2>/dev/null || stat -f%z /SDL_sound-fuzzer 2>/dev/null || echo 0)
if [ "$SIZE" -lt 1000 ]; then
    echo "Warning: Build artifact is suspiciously small ($SIZE bytes)"
fi

echo "Build completed successfully: /SDL_sound-fuzzer ($SIZE bytes)"

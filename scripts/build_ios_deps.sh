#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL_DIR="$REPO_ROOT/BionicSX2/ios-deps/install"
BUILD_DIR="$REPO_ROOT/BionicSX2/ios-deps/build"
SRC_DIR="$REPO_ROOT/BionicSX2/ios-deps/src"
TOOLCHAIN="$REPO_ROOT/BionicSX2/cmake/ios.toolchain.cmake"
PARALLEL="$(sysctl -n hw.logicalcpu 2>/dev/null || echo 4)"

mkdir -p "$INSTALL_DIR" "$BUILD_DIR" "$SRC_DIR"

build_lib() {
    local NAME="$1"; local SRC="$2"; shift 2
    echo ">>> Building $NAME"
    mkdir -p "$BUILD_DIR/$NAME"
    cmake -S "$SRC" -B "$BUILD_DIR/$NAME" \
        -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_FIND_ROOT_PATH="$INSTALL_DIR" \
        -DCMAKE_PREFIX_PATH="$INSTALL_DIR" \
        "$@"
    cmake --build "$BUILD_DIR/$NAME" --config Release -j"$PARALLEL"
    cmake --install "$BUILD_DIR/$NAME"
    echo ">>> $NAME OK"
}

# ── Tier 1: No dependencies ──

# lz4
if [ ! -f "$INSTALL_DIR/lib/liblz4.a" ]; then
    if [ ! -d "$SRC_DIR/lz4" ]; then
        git clone --depth 1 --branch v1.10.0 https://github.com/lz4/lz4.git "$SRC_DIR/lz4"
    fi
    build_lib lz4 "$SRC_DIR/lz4/build/cmake" \
        -DLZ4_BUILD_CLI=OFF -DLZ4_BUILD_LEGACY_LZ4C=OFF
fi

# zstd
if [ ! -f "$INSTALL_DIR/lib/libzstd.a" ]; then
    if [ ! -d "$SRC_DIR/zstd" ]; then
        git clone --depth 1 --branch v1.5.6 https://github.com/facebook/zstd.git "$SRC_DIR/zstd"
    fi
    build_lib zstd "$SRC_DIR/zstd/build/cmake" \
        -DZSTD_BUILD_PROGRAMS=OFF -DZSTD_BUILD_SHARED=OFF -DZSTD_BUILD_STATIC=ON -DZSTD_BUILD_TESTS=OFF
fi

# xz/lzma
if [ ! -f "$INSTALL_DIR/lib/liblzma.a" ]; then
    if [ ! -d "$SRC_DIR/xz" ]; then
        git clone --depth 1 --branch v5.6.3 https://github.com/tukaani-project/xz.git "$SRC_DIR/xz"
    fi
    build_lib xz "$SRC_DIR/xz" \
        -DBUILD_TESTING=OFF \
        -DXZ_TOOL_XZ=OFF -DXZ_TOOL_XZDEC=OFF -DXZ_TOOL_LZMADEC=OFF -DXZ_TOOL_LZMAINFO=OFF \
        -DXZ_TOOL_SCRIPTS=OFF -DENABLE_NLS=OFF \
        -DCREATE_XZ_SYMLINKS=OFF -DCREATE_LZMA_SYMLINKS=OFF \
        -DCMAKE_EXE_LINKER_FLAGS="" \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_DISABLE_FIND_PACKAGE_Intl=ON
fi

# fmt
if [ ! -f "$INSTALL_DIR/lib/libfmt.a" ]; then
    build_lib fmt "$REPO_ROOT/pcsx2/3rdparty/fmt" \
        -DFMT_TEST=OFF -DFMT_DOC=OFF
fi

# ── Tier 2: Depends on lz4/zstd/lzma ──

# zlib
if [ ! -f "$INSTALL_DIR/lib/libz.a" ]; then
    if [ ! -d "$SRC_DIR/zlib" ]; then
        git clone --depth 1 --branch v1.3.1 https://github.com/madler/zlib.git "$SRC_DIR/zlib"
    fi
    build_lib zlib "$SRC_DIR/zlib" \
        -DZLIB_BUILD_EXAMPLES=OFF
fi

# ── Tier 3: Depends on zlib ──

# libpng
if [ ! -f "$INSTALL_DIR/lib/libpng16.a" ]; then
    if [ ! -d "$SRC_DIR/libpng" ]; then
        git clone --depth 1 --branch v1.6.44 https://github.com/glennrp/libpng.git "$SRC_DIR/libpng"
    fi
    build_lib libpng "$SRC_DIR/libpng" \
        -DPNG_SHARED=OFF -DPNG_STATIC=ON -DPNG_TESTS=OFF -DPNG_BUILD_FRAMEWORK=OFF \
        -DCMAKE_SKIP_RPATH=ON -DCMAKE_SKIP_INSTALL_RPATH=ON \
        -DZLIB_ROOT="$INSTALL_DIR"
fi

# libzip — use bundled source (has HAVE_MEMCPY_S/HAVE_STRNCPY_S guards for MSVC-only)
if [ ! -f "$INSTALL_DIR/lib/libzip.a" ]; then
    # Copy bundled source to build dir so we can patch without modifying original
    LZIP_SRC="$REPO_ROOT/pcsx2/3rdparty/libzip"
    LZIP_BUILD_SRC="$SRC_DIR/libzip"
    rm -rf "$LZIP_BUILD_SRC"
    cp -R "$LZIP_SRC" "$LZIP_BUILD_SRC"
    # Disable zstd (target name mismatch Zstd::Zstd vs zstd::libzstd)
    sed -i '' 's/set(HAVE_LIBZSTD TRUE)/set(HAVE_LIBZSTD FALSE)/' "$LZIP_BUILD_SRC/CMakeLists.txt"
    sed -i '' '/zip_algorithm_zstd/d' "$LZIP_BUILD_SRC/CMakeLists.txt"
    sed -i '' '/Zstd::Zstd/d' "$LZIP_BUILD_SRC/CMakeLists.txt"
    build_lib libzip "$LZIP_BUILD_SRC" \
        -DLIBZIP_ENABLE_TOOLS=OFF -DLIBZIP_ENABLE_REGRESS=OFF \
        -DLIBZIP_ENABLE_EXAMPLES=OFF -DLIBZIP_ENABLE_DOCS=OFF \
        -DLIBZIP_USE_COMMONCRYPTO=ON -DENABLE_GNUTLS=OFF -DENABLE_MBEDTLS=OFF -DENABLE_OPENSSL=OFF \
        -DZLIB_LIBRARY="$INSTALL_DIR/lib/libz.a" -DZLIB_INCLUDE_DIR="$INSTALL_DIR/include"
fi

# freetype
if [ ! -f "$INSTALL_DIR/lib/libfreetype.a" ]; then
    if [ ! -d "$SRC_DIR/freetype" ]; then
        git clone --depth 1 --branch VER-2-13-3 https://gitlab.freedesktop.org/freetype/freetype.git "$SRC_DIR/freetype"
    fi
    build_lib freetype "$SRC_DIR/freetype" \
        -DFT_DISABLE_BZIP2=ON -DFT_DISABLE_HARFBUZZ=ON -DFT_DISABLE_BROTLI=ON \
        -DZLIB_ROOT="$INSTALL_DIR" -DPNG_ROOT="$INSTALL_DIR"
fi

# ── Tier 4: Depends on lz4 + zstd + zlib ──

# libchdr
if [ ! -f "$INSTALL_DIR/lib/libchdr.a" ]; then
    if [ ! -d "$SRC_DIR/libchdr" ]; then
        git clone --depth 1 https://github.com/rtissera/libchdr.git "$SRC_DIR/libchdr"
    fi
    build_lib libchdr "$SRC_DIR/libchdr" \
        -DWITH_SYSTEM_ZLIB=ON -DZLIB_ROOT="$INSTALL_DIR" \
        -Dlz4_DIR="$INSTALL_DIR/lib/cmake/lz4" \
        -Dzstd_DIR="$INSTALL_DIR/lib/cmake/zstd"
fi

# ── Tier 5: Audio (independent) ──

# soundtouch
if [ ! -f "$INSTALL_DIR/lib/libSoundTouch.a" ]; then
    if [ ! -d "$SRC_DIR/soundtouch" ]; then
        git clone --depth 1 --branch 2.3.3 https://codeberg.org/soundtouch/soundtouch.git "$SRC_DIR/soundtouch"
    fi
    build_lib soundtouch "$SRC_DIR/soundtouch" \
        -DCMAKE_CXX_FLAGS="-DSOUNDTOUCH_DISABLE_X86_OPTIMIZATIONS"
fi

# cubeb
if [ ! -f "$INSTALL_DIR/lib/libcubeb.a" ]; then
    if [ ! -d "$SRC_DIR/cubeb" ]; then
        git clone --depth 1 https://github.com/mozilla/cubeb.git "$SRC_DIR/cubeb"
    fi
    build_lib cubeb "$SRC_DIR/cubeb" \
        -DBUILD_TESTS=OFF -DBUILD_TOOLS=OFF -DUSE_SANITIZERS=OFF
fi

echo ""
echo "===== ALL DEPENDENCIES BUILT SUCCESSFULLY ====="
echo "Output in: $INSTALL_DIR"
ls -la "$INSTALL_DIR/lib/" 2>/dev/null || echo "(no libs yet)"

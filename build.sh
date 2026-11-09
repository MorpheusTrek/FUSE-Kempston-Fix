#!/bin/sh
# Build fuse_libretro.so for the Anbernic RG35XX with the joystick fix applied.
#
# Requirements: git, make, patch and an ARM hard-float toolchain, e.g. on
# Debian/Ubuntu:  sudo apt install build-essential git gcc-arm-linux-gnueabihf
#
# Usage:
#   ./build.sh
#   CROSS=/opt/gcc-arm/bin/arm-linux-gnueabihf- ./build.sh   # custom toolchain
set -eu

UPSTREAM=${UPSTREAM:-https://github.com/libretro/fuse-libretro.git}
PIN=${PIN:-e997e2bc32c888348f862f69f2c53babfedf7791}
CROSS=${CROSS:-arm-linux-gnueabihf-}
JOBS=${JOBS:-$(nproc 2>/dev/null || echo 4)}

cd "$(dirname "$0")"
ROOT=$(pwd)
SRC="$ROOT/build/fuse-libretro"

mkdir -p "$ROOT/build"
if [ ! -d "$SRC/.git" ]; then
    echo "==> fetching $UPSTREAM @ $PIN"
    rm -rf "$SRC"
    git init -q "$SRC"
    git -C "$SRC" remote add origin "$UPSTREAM"
    if git -C "$SRC" fetch -q --depth 1 origin "$PIN"; then
        git -C "$SRC" checkout -q FETCH_HEAD
    else
        echo "==> server refused SHA fetch, cloning full history"
        git -C "$SRC" fetch -q origin
        git -C "$SRC" checkout -q "$PIN"
    fi
else
    echo "==> reusing $SRC"
fi

# Start from a clean tree so re-running the script does not double-patch.
git -C "$SRC" checkout -q -- .

echo "==> applying fuse-joypad-type.patch"
patch -p1 -d "$SRC" < "$ROOT/fuse-joypad-type.patch"

echo "==> building (platform=rg35xx, $JOBS jobs)"
make -C "$SRC" -f Makefile.libretro platform=rg35xx \
     CC="${CROSS}gcc" CXX="${CROSS}g++" -j"$JOBS"

echo
echo "built: $SRC/fuse_libretro.so"
ls -l "$SRC/fuse_libretro.so"

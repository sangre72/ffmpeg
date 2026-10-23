#!/bin/bash
# Builds ffmpeg.exe / ffprobe.exe (win64, LGPL) from this repository inside the BtbN FFmpeg-Builds image,
# with the same configure flags as the BtbN win64-lgpl-8.1 release build.
# Run from the host (see BUILD.md):
#   docker run --rm -v <out-dir>:/ffbuild -v <this-repo>:/src:ro ghcr.io/btbn/ffmpeg-builds/win64-lgpl-8.1:latest bash /src/build/build_in_btbn_image.sh
# The source is cloned into /work inside the container: compiling on a Windows bind mount is very slow.
set -xe
BRANCH="${BRANCH:-main}"
git config --global --add safe.directory '*'
mkdir -p /work && cd /work
git clone --depth 1 --branch="$BRANCH" file:///src ffmpeg
cd ffmpeg
./configure --prefix=/work/prefix --pkg-config-flags="--static" $FFBUILD_TARGET_FLAGS $FF_CONFIGURE \
    --extra-cflags="$FF_CFLAGS" --extra-cxxflags="$FF_CXXFLAGS" --extra-libs="$FF_LIBS" \
    --extra-ldflags="$FF_LDFLAGS" --extra-ldexeflags="$FF_LDEXEFLAGS" \
    --cc="$CC" --cxx="$CXX" --ar="$AR" --ranlib="$RANLIB" --nm="$NM" \
    --extra-version="20261023-a1568" || { tail -50 ffbuild/config.log; exit 1; }
make -j"$(nproc)"
make install
mkdir -p /ffbuild/out
cp /work/prefix/bin/ffmpeg.exe /work/prefix/bin/ffprobe.exe /ffbuild/out/
cp LICENSE.md COPYING.LGPLv2.1 COPYING.LGPLv3 /ffbuild/out/
echo BUILD_OK

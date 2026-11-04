# Patched FFmpeg 8.1 (n8.1.3-17) — D3D11 planar render-target array fix, live bitrate, forced key frame

This repository holds the complete source of the FFmpeg build that ships with Colibre, as the
LGPL requires: the upstream tree, three patches, and the build instructions. It contains no other code.

## Releases

| Tag | Build | Libraries inside ffmpeg.exe |
|---|---|---|
| `n8.1.3-17-d3d11fix-r3` (current, 2026-11-04) | exactly the r2 build (same image digest, same configure: BtbN flags **minus chromaprint and libzvbi**) plus patches 0002 and 0003 | no GPL code. `ffmpeg -buildconf` differs from r2 only in `--extra-version`. Library sources: the same pinned commits as r2 (same image); the tarballs are attached to this release too. |
| `n8.1.3-17-d3d11fix-r2` (2026-11-01) | BtbN image pinned by digest (`sha256:2e5ac613…`, BtbN FFmpeg-Builds [5ece6289](https://github.com/BtbN/FFmpeg-Builds/tree/5ece62897c650b863c1ddda7b6964845344aef2d)), BtbN flags **minus chromaprint and libzvbi** | no GPL code. The source of every LGPL/MPL library (exact pinned commit) is attached to the release as `.tar.gz`. |
| `n8.1.3-17-d3d11fix` (2026-10-23) | BtbN `win64-lgpl-8.1:latest` of that day (FFmpeg-Builds [93786836](https://github.com/BtbN/FFmpeg-Builds/tree/937868360a21d711ec94a33f5591d345ad9b7754)) | contained chromaprint with FFTW3 (GPL-2.0-or-later) and zvbi, so that binary is also under GPL-3.0; the full source of all its libraries, FFTW3 included, is attached to that release. Replaced by r2. |

The only difference in features between the two: r2 has no `chromaprint` muxer and no `libzvbi_teletext` decoder.

## What is here

| Commit | Content |
|---|---|
| `FFmpeg n8.1.3-17-gc389840894 ... unmodified snapshot` | upstream FFmpeg `release/8.1` at [c389840894](https://github.com/FFmpeg/FFmpeg/commit/c389840894), byte-identical (git tree `e46ac2edfb9f0ac016a137a3333e45043eb6a732`). This is the source of BtbN's `ffmpeg-n8.1.3-17-gc389840894-win64-lgpl-8.1` build. |
| `avutil/hwcontext_d3d11va: no array textures for planar render-target/encoder pools` | patch 0001 (`libavutil/hwcontext_d3d11va.c`, +8 / −1) |
| `fftools: runtime video bitrate on stdin (b<bps>); nvenc: reconf_idr` | patch 0002 (r3): stdin key `b<bps>` + newline sets the video encoder bit rate (maxrate/bufsize in the same ratio) before its next frame; NVENC option `-reconf_idr 0` applies a runtime rate change without an encoder reset or IDR (default 1 = upstream behaviour) |
| `fftools: stdin key k forces a key frame on the next video frame` | patch 0003 (r3): stdin key `k` sends the next video frame as a key frame (with NVENC `-forced-idr 1` an IDR); listed in the `?` help |
| `build: --extra-version from FF_XV` | build script only: the version suffix can be set per release (`-e FF_XV=20261104-r3`) |

- `patches/0001-…`, `patches/0002-…`, `patches/0003-…` hold the same changes as `git format-patch` files. They apply in order to upstream c389840894 with `git am`.
- `build/build_in_btbn_image.sh` is the build script.

## Why the patch

FFmpeg commit efd484c (2025-09-17, first released in 8.1) removed the old "no texture arrays for render targets" rule in
`libavutil/hwcontext_d3d11va.c`. Since then, a D3D11 frame pool such as the `scale_d3d11` output becomes one texture array:

- 10 × NV12;
- bound `D3D11_BIND_RENDER_TARGET | D3D11_BIND_VIDEO_ENCODER`.

D3D11 rejects planar YUV (NV12, P010, ...) texture arrays with more than 2 slices under these bind flags. It returns `E_INVALIDARG`, and FFmpeg logs:

    Could not create the texture (80070057)

So a `ddagrab -> scale_d3d11 -> h264_nvenc` pipeline produces no frames. This was seen on both NVIDIA and Intel; 8.0.x is unaffected.

The patch keeps single textures for exactly these pools (planar format, render-target or encoder bind, ArraySize > 2), which was the 8.0 behaviour. Non-planar arrays such as BGRA, the case efd484c was written for, are unchanged.

## Build (Windows host with Docker Desktop, or Linux with Docker)

The build uses BtbN's FFmpeg-Builds image for win64 / LGPL / 8.1, with the same variant and configure flags as the BtbN release:

```sh
git clone https://github.com/sangre72/ffmpeg.git ffsrc
mkdir out
docker pull ghcr.io/btbn/ffmpeg-builds/win64-lgpl-8.1@sha256:2e5ac613c1142d618f588620df68a518a94ca427e080855660f8d94a5d4b2925
docker run --rm -v "$PWD/out:/ffbuild" -v "$PWD/ffsrc:/src:ro" \
  ghcr.io/btbn/ffmpeg-builds/win64-lgpl-8.1@sha256:2e5ac613c1142d618f588620df68a518a94ca427e080855660f8d94a5d4b2925 bash /src/build/build_in_btbn_image.sh
```

- The result is `out/out/ffmpeg.exe` and `out/out/ffprobe.exe`, plus the license files.
- It takes about 10 minutes on 24 cores.
- Build another branch with `-e BRANCH=<name>`; r3 was built from its tag with `-e FF_XV=20261104-r3`.

Configure line of the result, as printed by `ffmpeg -buildconf` (variant `win64-lgpl-8.1`):

```
--pkg-config-flags=--static --pkg-config=pkg-config --cross-prefix=x86_64-w64-mingw32- --arch=x86_64 --target-os=mingw32
--enable-version3 --disable-debug --disable-w32threads --enable-pthreads --enable-iconv --enable-zlib --enable-libxml2
--enable-libvmaf --enable-fontconfig --enable-libharfbuzz --enable-libfreetype --enable-libfribidi --enable-lcms2
--enable-vulkan --enable-libshaderc --enable-libdav1d --enable-libvorbis --enable-librav1e --enable-librsvg --disable-libxcb
--disable-xlib --disable-libpulse --enable-gmp --enable-lzma --enable-liblcevc-dec --enable-opencl --enable-amf
--enable-libaom --disable-avisynth --enable-chromaprint --disable-libdavs2 --disable-libdvdread --disable-libdvdnav
--disable-libfdk-aac --enable-ffnvcodec --enable-cuda-llvm --disable-frei0r --enable-libgme --enable-libkvazaar
--enable-libaribb24 --enable-libaribcaption --enable-libass --enable-libbluray --enable-libjxl --enable-libmp3lame
--enable-libopus --enable-libplacebo --enable-librist --enable-libssh --enable-libtheora --enable-libvpx --enable-libwebp
--enable-libzmq --enable-lv2 --enable-libvpl --enable-openal --enable-liboapv --enable-libopencore-amrnb
--enable-libopencore-amrwb --enable-libopenh264 --enable-libopenjpeg --enable-libopenmpt --disable-librubberband
--enable-schannel --enable-sdl2 --enable-libsnappy --enable-libsoxr --enable-libsrt --enable-libsvtav1 --enable-libtwolame
--enable-libuavs3d --disable-libdrm --enable-vaapi --enable-vapoursynth --disable-libvidstab --enable-libvvenc
--disable-whisper --disable-libx264 --disable-libx265 --disable-libxavs2 --disable-libxvid --enable-libzimg --enable-libzvbi
--disable-chromaprint --disable-libzvbi   (r2: appended by build/build_in_btbn_image.sh, see below)
```

## License

FFmpeg is licensed under the GNU LGPL v2.1 or later. Because this build uses `--enable-version3`, it falls under LGPL v3 or later.
See `LICENSE.md`, `COPYING.LGPLv2.1` and `COPYING.LGPLv3`. The patch is offered under the same license as FFmpeg.

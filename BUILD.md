# Patched FFmpeg 8.1 (n8.1.3-17) — D3D11 planar render-target array fix

This repository holds the complete source of the FFmpeg build that ships with TeslaTune, as the
LGPL requires: the upstream tree, one patch, and the build instructions. It contains no other code.

## What is here

| Commit | Content |
|---|---|
| `FFmpeg n8.1.3-17-gc389840894 ... unmodified snapshot` | upstream FFmpeg `release/8.1` at [c389840894](https://github.com/FFmpeg/FFmpeg/commit/c389840894), byte-identical (git tree `e46ac2edfb9f0ac016a137a3333e45043eb6a732`). This is the source of BtbN's `ffmpeg-n8.1.3-17-gc389840894-win64-lgpl-8.1` build. |
| `avutil/hwcontext_d3d11va: no array textures for planar render-target/encoder pools` | the only modification (`libavutil/hwcontext_d3d11va.c`, +8 / −1) |

- `patches/0001-hwcontext_d3d11va-no-planar-rt-arrays.patch` holds the same change as a `git format-patch` file. It applies to upstream c389840894 with `git am`.
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
docker pull ghcr.io/btbn/ffmpeg-builds/win64-lgpl-8.1:latest
docker run --rm -v "$PWD/out:/ffbuild" -v "$PWD/ffsrc:/src:ro" \
  ghcr.io/btbn/ffmpeg-builds/win64-lgpl-8.1:latest bash /src/build/build_in_btbn_image.sh
```

- The result is `out/out/ffmpeg.exe` and `out/out/ffprobe.exe`, plus the license files.
- It takes about 10 minutes on 24 cores.
- Build another branch with `-e BRANCH=<name>`.

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
```

## License

FFmpeg is licensed under the GNU LGPL v2.1 or later. Because this build uses `--enable-version3`, it falls under LGPL v3 or later.
See `LICENSE.md`, `COPYING.LGPLv2.1` and `COPYING.LGPLv3`. The patch is offered under the same license as FFmpeg.

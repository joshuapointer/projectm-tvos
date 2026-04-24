# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

libprojectM — the core C/C++ library behind the Milkdrop-compatible music visualizer. **Library only**: all frontends (SDL, Music.app plug-in, etc.) live in separate repos under the `projectM-visualizer` org. Expect to produce a shared or static lib with a stable C API, not a runnable app.

- Language/standard: C++14 (`CMAKE_CXX_STANDARD 14`), C
- License: LGPL-2.1
- Current version: 4.1.0, API SO version 4
- Symbol visibility is hidden by default — only explicitly exported C-API symbols are visible in the shared lib.

## Build

CMake 3.21+ is required. Always build out-of-tree.

Standard desktop build (OpenGL Core 3.3):

```bash
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON ..
cmake --build . -j
ctest --output-on-failure          # after BUILD_TESTING=ON
```

GLES build (mobile / Pi / Emscripten / Android):

```bash
cmake -DENABLE_GLES=ON ..
```

A ready-to-use local build directory exists at `build-local/` (Ninja generator) — use `cmake --build build-local --target projectM` for a quick rebuild of just the main lib.

### Important CMake options

| Option | Default | Notes |
|---|---|---|
| `BUILD_SHARED_LIBS` | ON | Static lib when OFF (required for tvOS/iOS) |
| `ENABLE_GLES` | OFF | Forced ON for Emscripten and Android; required for tvOS |
| `ENABLE_PLAYLIST` | ON | Builds the optional playlist library |
| `ENABLE_SDL_UI` | OFF at root / ON per `BUILDING-cmake.md` — confirm via `option()` block | Dev test app, needs SDL2 |
| `BUILD_TESTING` | OFF | Enables gtest suites under `tests/` |
| `ENABLE_SYSTEM_PROJECTM_EVAL` | ON | When OFF, uses the vendored copy at `vendor/projectm-eval` |

### Tests

Two gtest suites, registered with `add_test`:

- `projectM-unittest` — `tests/libprojectM/` (shader comment parsing, preset file parser, etc.)
- `projectM-playlist-unittest` — `tests/playlist/`

Run one suite: `ctest -R projectM-unittest --output-on-failure` or invoke the binary directly (`build/tests/libprojectM/projectM-unittest --gtest_filter=...`).

### macOS framework smoke test

`scripts/test-macos-framework.sh` — verifies `MacOSFramework.cmake` output on macOS builds.

## Architecture

```
src/
├── api/include/projectM-4/   # Public C API — the stable surface (core.h, render_opengl.h, audio.h, playlist.h, …)
├── api/cxx-interface/        # Optional C++ interface (OFF by default; not supported for external use)
├── libprojectM/              # Core implementation
│   ├── ProjectM.{hpp,cpp}               # Top-level pipeline coordinator
│   ├── ProjectMCWrapper.{hpp,cpp}       # C-API → C++ trampolines
│   ├── PresetFactoryManager / Preset*   # Preset loading + transitions
│   ├── TimeKeeper, Utils, Logging
│   ├── Audio/                           # PCM ingest, FFT (MilkdropFFT), beat/loudness, WaveformAligner
│   ├── Renderer/                        # GL-based rendering; FBOs, textures, shaders, transitions
│   │   ├── OpenGL.h                     # GL header umbrella (desktop vs GLES)
│   │   └── Platform/                    # Dynamic GL loader abstraction
│   ├── MilkdropPreset/                  # Milkdrop .milk preset engine (uses projectm-eval)
│   └── UserSprites/                     # Programmatic sprite overlay API
└── playlist/                 # Optional playlist library (libprojectM::playlist target)

vendor/
├── glad          # GL/GLES loader (regenerated, do not hand-edit)
├── glm           # Header-only math (ENABLE_SYSTEM_GLM to use system copy)
├── hlslparser    # HLSL→GLSL for Milkdrop preset warp/comp shaders
├── projectm-eval # Milkdrop math expression interpreter (tree-walking, no JIT → store-safe)
└── stb_image

cmake/            # Custom modules (GenerateShaderResources, MacOSFramework, FindGLM, …)
tests/            # gtest suites
docs/             # Doxygen config + web assets
```

### Data/control flow at runtime

1. Host app creates a projectM instance via `projectm_create` or `projectm_create_with_opengl_load_proc` (see `src/api/include/projectM-4/core.h`, `render_opengl.h`). It must set the GL context current on the calling thread before creating.
2. Host pushes PCM via `projectm_pcm_add_float/int16` (`audio.h`). `Audio/PCM.cpp` buffers it; `Loudness` + `MilkdropFFT` compute frame features; `WaveformAligner` stabilizes waveform display.
3. Host calls `projectm_opengl_render_frame` (owns the default FB) or `projectm_opengl_render_frame_fbo` (when host has its own bound FBO — e.g. GLKView). `ProjectM::RenderFrame` drives the `Renderer/` + `MilkdropPreset/` pipeline.
4. `Renderer/Platform/GLResolver` + `GladLoader` resolve GL entry points lazily through `glad`; the backend (CGL, WGL, GLX, EGL, user-resolver, EAGL) is selected at runtime via `PlatformLibraryNames.hpp`.

### Renderer platform abstraction

`src/libprojectM/Renderer/Platform/` is where per-OS GL loading lives. Edits here affect every platform — be careful.

- `GladLoader.cpp` — enforces minimum GL/GLES version and calls `gladLoadGL`/`gladLoadGLES2` under a mutex.
- `GLResolver.cpp` — backend selection, `ProbeCurrentContext`, user-resolver bridging.
- `PlatformLibraryNames.hpp` — per-OS library name candidates tried by `dlopen`/`LoadLibrary`.

All three files have `PROJECTM_TVOS` / `PROJECTM_IOS` guarded branches (see "In-flight local modifications" below). Keep any new platform code behind compile guards so desktop targets are unaffected.

### Shader resource generation

At configure time, CMake runs `GenerateShaderResources` → `ShaderResources.hpp` (embedded shader sources). Do not edit the generated header; edit the `.glsl`/`.frag`/`.vert` sources and reconfigure.

## In-flight local modifications (tvOS work)

This checkout has uncommitted work in progress for a personal-use tvOS visualizer under `apps/tvos/` (see that dir's `README.md`). The three modified upstream files are:

- `src/libprojectM/Renderer/Platform/GladLoader.cpp` — GLES floor relaxed to 3.0/GLSL 3.00 on tvOS/iOS (EAGL tops out there).
- `src/libprojectM/Renderer/Platform/PlatformLibraryNames.hpp` — Apple branch routes to `OpenGLES.framework` on tvOS/iOS (no `OpenGL.framework`).
- `src/libprojectM/Renderer/Platform/GLResolver.cpp` — `ProbeCurrentContext` reuses the CGL slot to accept user-resolver presence as proof of a current EAGL context.

All three are `#if defined(PROJECTM_TVOS) || defined(PROJECTM_IOS)` guarded. Desktop builds are unchanged; verified with a local `cmake --build build-local --target projectM`. Rationale is documented in `.omc/autopilot/m1-loader-decision.md`.

If you're working on desktop/Linux/Windows and these edits confuse you, they're inert on your platform — leave them alone.

## Conventions and gotchas

- **C API is the supported interface.** The C++ interface (`ENABLE_CXX_INTERFACE`, `api/cxx-interface/`) is explicitly unsupported for external consumers. Prefer adding/extending C-API functions for new features; internal C++ classes should stay hidden.
- **Thread safety.** Audio ingest and rendering typically happen on different threads. `PCM.cpp` uses a mutex (recent commit `16f40af10` fixed a bug there). `GladLoader::Initialize` holds a mutex across GLAD loading to protect global function pointers.
- **`projectm_opengl_render_frame` vs `_fbo`.** If your host has its own bound framebuffer (e.g. GLKView on tvOS), use `_fbo` and pass the FBO ID. The non-fbo variant assumes default framebuffer zero.
- **LGPL.** External consumers must link projectM dynamically (or comply with LGPL static-link terms). Static linking for personal-use/dev builds is fine but don't bake that assumption into distributed code.
- **No Metal backend.** Renderer is OpenGL/GLES only. Any "Metal port" is a hypothetical future — don't claim it exists.
- **Out-of-tree builds only.** `build-local/` is fine; never configure at the source root.
- **Don't hand-edit `vendor/glad/`** — it's regenerated. If GL entry points are missing, regenerate glad rather than patching the generated code.

## Ongoing personal work

`apps/tvos/` is a personal-use Apple TV visualizer built on this library (not part of upstream). Its own README at `apps/tvos/README.md` is authoritative for that build. `.omc/` contains autopilot planning artifacts for the same effort. Neither is part of the upstream library release and both are safe to ignore when working on core libprojectM changes.

#!/usr/bin/env bash
# Build libprojectM for Apple tvOS (device + simulator) and package as an XCFramework.
#
# Prerequisites:
#   - Xcode 14.2+ (for tvOS 16 SDK) or Xcode 15+ (for tvOS 17 SDK)
#   - CMake 3.26+
#   - The three guarded upstream edits applied (GladLoader, PlatformLibraryNames, GLResolver)
#
# Output: apps/tvos/Frameworks/libprojectM.xcframework
#
# Usage:
#   ./apps/tvos/scripts/build-libprojectm-xcframework.sh [--clean]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
OUT_DIR="${REPO_ROOT}/apps/tvos/Frameworks"
BUILD_ROOT="${REPO_ROOT}/build-tvos"
TOOLCHAIN="${SCRIPT_DIR}/toolchains/tvos.cmake"
XCFRAMEWORK_NAME="libprojectM.xcframework"
XCFRAMEWORK_PATH="${OUT_DIR}/${XCFRAMEWORK_NAME}"

# The CMake target name for libprojectM (see src/libprojectM/CMakeLists.txt).
CMAKE_TARGET="projectM"

# The static archive name CMake produces. libprojectM ships as libprojectM-4.a.
LIB_ARCHIVE_NAME="libprojectM-4.a"

if [[ ! -f "${TOOLCHAIN}" ]]; then
    echo "ERROR: toolchain file not found at ${TOOLCHAIN}" >&2
    exit 1
fi

if [[ "${1-}" == "--clean" ]]; then
    echo "Cleaning ${BUILD_ROOT} and ${XCFRAMEWORK_PATH}"
    rm -rf "${BUILD_ROOT}" "${XCFRAMEWORK_PATH}"
fi

mkdir -p "${OUT_DIR}" "${BUILD_ROOT}"

configure_and_build() {
    local sdk="$1"      # appletvos | appletvsimulator
    local build_dir="${BUILD_ROOT}/${sdk}"

    echo "=== Configuring ${sdk} ==="
    cmake -S "${REPO_ROOT}" -B "${build_dir}" \
        -G Xcode \
        -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN}" \
        -DCMAKE_OSX_SYSROOT="${sdk}" \
        -DCMAKE_BUILD_TYPE=Release

    echo "=== Building ${sdk} ==="
    cmake --build "${build_dir}" --config Release --target "${CMAKE_TARGET}" -- -quiet
}

find_archive() {
    local sdk="$1"
    local build_dir="${BUILD_ROOT}/${sdk}"
    # CMake with Xcode generator puts artifacts under <build>/<path-to-target>/Release-<sdk>/
    local candidate
    candidate=$(find "${build_dir}" -type f -name "${LIB_ARCHIVE_NAME}" -path "*Release-${sdk}*" | head -n 1)
    if [[ -z "${candidate}" ]]; then
        # Fallback: any Release-* directory
        candidate=$(find "${build_dir}" -type f -name "${LIB_ARCHIVE_NAME}" | head -n 1)
    fi
    if [[ -z "${candidate}" ]]; then
        echo "ERROR: could not locate ${LIB_ARCHIVE_NAME} under ${build_dir}" >&2
        exit 1
    fi
    printf '%s' "${candidate}"
}

configure_and_build appletvos
configure_and_build appletvsimulator

DEVICE_LIB="$(find_archive appletvos)"
SIM_LIB="$(find_archive appletvsimulator)"

echo "=== Creating XCFramework ==="
echo "Device lib:    ${DEVICE_LIB}"
echo "Simulator lib: ${SIM_LIB}"

# Headers come from the public API include directory.
HEADERS_DIR="${REPO_ROOT}/src/api/include"
if [[ ! -d "${HEADERS_DIR}/projectM-4" ]]; then
    echo "ERROR: expected headers at ${HEADERS_DIR}/projectM-4" >&2
    exit 1
fi

rm -rf "${XCFRAMEWORK_PATH}"
xcodebuild -create-xcframework \
    -library "${DEVICE_LIB}" -headers "${HEADERS_DIR}" \
    -library "${SIM_LIB}"    -headers "${HEADERS_DIR}" \
    -output "${XCFRAMEWORK_PATH}"

echo ""
echo "=== XCFramework built at ${XCFRAMEWORK_PATH} ==="
ls "${XCFRAMEWORK_PATH}"

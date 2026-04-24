# Install script for directory: /Users/joshpointer/Developer/projectm/src/api

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/Users/joshpointer/Developer/projectm-install")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set path to fallback-tool for dependency-resolution.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/usr/bin/objdump")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Devel" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/projectM-4" TYPE FILE FILES
    "/Users/joshpointer/Developer/projectm/build-local/src/api/include/projectM-4/projectM_export.h"
    "/Users/joshpointer/Developer/projectm/build-local/src/api/include/projectM-4/version.h"
    "/Users/joshpointer/Developer/projectm/src/api/include/projectM-4/audio.h"
    "/Users/joshpointer/Developer/projectm/src/api/include/projectM-4/callbacks.h"
    "/Users/joshpointer/Developer/projectm/src/api/include/projectM-4/core.h"
    "/Users/joshpointer/Developer/projectm/src/api/include/projectM-4/debug.h"
    "/Users/joshpointer/Developer/projectm/src/api/include/projectM-4/logging.h"
    "/Users/joshpointer/Developer/projectm/src/api/include/projectM-4/memory.h"
    "/Users/joshpointer/Developer/projectm/src/api/include/projectM-4/parameters.h"
    "/Users/joshpointer/Developer/projectm/src/api/include/projectM-4/projectM.h"
    "/Users/joshpointer/Developer/projectm/src/api/include/projectM-4/render_opengl.h"
    "/Users/joshpointer/Developer/projectm/src/api/include/projectM-4/touch.h"
    "/Users/joshpointer/Developer/projectm/src/api/include/projectM-4/types.h"
    "/Users/joshpointer/Developer/projectm/src/api/include/projectM-4/user_sprites.h"
    )
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/Users/joshpointer/Developer/projectm/build-local/src/api/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()

# Copyright (C) 2006-2018 Istituto Italiano di Tecnologia (IIT)
# Copyright (C) 2006-2010 RobotCub Consortium
# All rights reserved.
#
# This software may be modified and distributed under the terms of the
# BSD-3-Clause license. See the accompanying LICENSE file for details.

cmake_minimum_required(VERSION 3.5)

# UseSWIG generates now standard target names.
if(NOT ${CMAKE_VERSION} VERSION_LESS 3.13)
  cmake_policy(SET CMP0078 OLD)
endif()

include(CMakeDependentOption)
include(CheckCXXCompilerFlag)
include(GNUInstallDirs)

# disable all warnings for current folder and subfolders
set(CMAKE_C_FLAGS -w)
set(CMAKE_CXX_FLAGS -w)

if(NOT YARP_VERSION)

  #############################################################################
  ## Discourage inplace compilation

  if(CMAKE_BINARY_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    option(COMPILE_INPLACE "Allow inplace compilation" FALSE)
    if(NOT COMPILE_INPLACE)
      if(NOT BEND_OVER_BACKWARDS_COMPATIBLE)
        message(FATAL_ERROR "Please don't compile bindings in the source directory, make a separate build directory (ideally one per language).  If CMake has now added a CMakeCache.txt file in the source directory, please delete it.  If you really really want to compile in place, set the COMPILE_INPLACE flag.")
      endif()
    endif()
  endif()

  # Find YARP for bindings-only builds
  find_package(YARP COMPONENTS conf OS sig dev REQUIRED)
  foreach(_component conf OS sig dev)
    get_property(YARP_${_component}_INCLUDE_DIRS TARGET YARP::YARP_${_component} PROPERTY INTERFACE_INCLUDE_DIRECTORIES)
    include_directories(${YARP_${_component}_INCLUDE_DIRS})
  endforeach()

  find_package(SWIG 3.0 REQUIRED)

  set(_nested_build 0)
else()
  # this is necessary for SWIG to parse yarp.i file
  # FIXME: Find a better way to do this (using generator expressions?)
  include_directories("${CMAKE_BINARY_DIR}/src/libYARP_conf/include")
  include_directories("${CMAKE_SOURCE_DIR}/src/libYARP_OS/include")
  include_directories("${CMAKE_SOURCE_DIR}/src/libYARP_sig/include")
  include_directories("${CMAKE_SOURCE_DIR}/src/libYARP_dev/include")
  set(_nested_build 1)
endif()

include(${YARP_MODULE_DIR}/YarpPrintFeature.cmake)

set(YARP_COMPILE_BINDINGS_DEFAULT TRUE)
set(YARP_BASE_DIR ${CMAKE_CURRENT_BINARY_DIR})
if(_nested_build)
  # this is a nested build
  set(YARP_COMPILE_BINDINGS_DEFAULT FALSE)
  set(YARP_BASE_DIR ${CMAKE_BINARY_DIR})
endif()
option(YARP_COMPILE_BINDINGS "Compile optional language bindings" ${YARP_COMPILE_BINDINGS_DEFAULT})
yarp_print_feature(YARP_COMPILE_BINDINGS 0 "Bindings")

#############################################################################
## Options for compiling supported languages.  There's nothing magical
## about this list, any SWIG-supported language should work - take a
## look at e.g. ruby code below for how to do it.

set(SUPPORTED_LANGUAGES "Java"
                        "Python"
                        "Perl"
                        "Chicken Scheme"
                        "CSharp"
                        "Allegro Common Lisp"
                        "TCL"
                        "Ruby"
                        "Lua"
                        "Octave")

foreach(Lang ${SUPPORTED_LANGUAGES})
  string(TOUPPER "${Lang}" LANG)
  string(REGEX REPLACE " .+" "" LANG "${LANG}")
  cmake_dependent_option(CREATE_${LANG} "Do you want to create the ${Lang} interface" OFF
                         YARP_COMPILE_BINDINGS OFF)
  yarp_print_feature(CREATE_${LANG} 1 "${Lang} bindings")
endforeach()

#############################################################################

if (_nested_build)
  # Make sure yarp.i and related source files get installed, to allow
  # bindings for other languages to be compiled from the build material.

  # Install main CMakeLists and Swig input file
  foreach(f CMakeLists.txt yarp.i macrosForMultipleAnalogSensors.i matlab/vectors_fromTo_matlab.i README.md)
      install(FILES ${CMAKE_SOURCE_DIR}/bindings/${f}
              COMPONENT development
              DESTINATION ${CMAKE_INSTALL_DATADIR}/yarp/bindings)
  endforeach(f)

  # Install supported languages data
  foreach(Lang ${SUPPORTED_LANGUAGES})
    string(TOLOWER "${Lang}" lang)
    string(REGEX REPLACE " .+" "" lang "${lang}")

    install(DIRECTORY ${CMAKE_SOURCE_DIR}/bindings/${lang}
            COMPONENT development
            DESTINATION ${CMAKE_INSTALL_DATADIR}/yarp/bindings)
  endforeach()

endif()

#############################################################################
## Allow passing extra flags to swig (e.g. -Wall)

set(SWIG_EXTRA_FLAGS "" CACHE STRING "Extra flags passed to swig commands (e.g. -Wall)")
mark_as_advanced(SWIG_EXTRA_FLAGS)

#############################################################################

if(YARP_COMPILE_BINDINGS)
  unset(SWIG_COMMON_FLAGS)

  #############################################################################
  ## Do not build deprecated functions when disabled

  if(YARP_NO_DEPRECATED)
    list(APPEND SWIG_COMMON_FLAGS "-DYARP_NO_DEPRECATED")
  endif()

  # Append user flags
  list(APPEND SWIG_COMMON_FLAGS ${SWIG_EXTRA_FLAGS})

  #############################################################################
  # Include SWIG use file
  include(${SWIG_USE_FILE})

  set(SWIG_YARP_LIBRARIES YARP::YARP_OS
                          YARP::YARP_sig
                          YARP::YARP_dev
                          YARP::YARP_init)

  set(SWIG_BINDINGS_SOURCE_FILE "${CMAKE_CURRENT_SOURCE_DIR}/yarp.i")

  #############################################################################
  # Create bindings for enabled languages

  foreach(Lang ${SUPPORTED_LANGUAGES})
    string(REGEX REPLACE " .+" "" trimmed_lang "${Lang}")
    string(TOUPPER ${trimmed_lang} LANG)
    string(TOLOWER ${trimmed_lang} lang)

    if(CREATE_${LANG})
      add_subdirectory(${lang})
    endif()
  endforeach()

endif()

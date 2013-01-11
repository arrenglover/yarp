# Copyright: (C) 2009 RobotCub Consortium
# Authors: Paul Fitzpatrick, Giorgio Metta, Lorenzo Natale, Alessandro Scalzo
# CopyPolicy: Released under the terms of the LGPLv2.1 or later, see LGPL.TXT

#########################################################################
# Check whether system is big- or little- endian

include(TestBigEndian)
test_big_endian(IS_BIG_ENDIAN)
if(${IS_BIG_ENDIAN})
  set(YARP_BIG_ENDIAN 1)
else(${IS_BIG_ENDIAN})
  set(YARP_LITTLE_ENDIAN 1)
endif(${IS_BIG_ENDIAN})

#########################################################################
# Find 16, 32, and 64 bit types, portably

include(CheckTypeSize)

set(YARP_INT16)
set(YARP_INT32)
set(YARP_INT64)
set(YARP_FLOAT64)

check_type_size("short" SIZEOF_SHORT)
check_type_size("int" SIZEOF_INT)
check_type_size("long" SIZEOF_LONG)
if(SIZEOF_INT EQUAL 4)
  set(YARP_INT32 "int")
else(SIZEOF_INT EQUAL 4)
  if(SIZEOF_SHORT EQUAL 4)
    set(YARP_INT32 "short")
  else(SIZEOF_SHORT EQUAL 4)
    if(SIZEOF_LONG EQUAL 4)
      set(YARP_INT32 "long")
    endif(SIZEOF_LONG EQUAL 4)
  endif(SIZEOF_SHORT EQUAL 4)
endif(SIZEOF_INT EQUAL 4)

if(SIZEOF_SHORT EQUAL 2)
  set(YARP_INT16 "short")
else(SIZEOF_SHORT EQUAL 2)
  # Hmm - there's no other native type to get 16 bits
  # We will continue since most people using YARP do not need one.
  message(STATUS "Warning: cannot find a 16 bit type on your system")
  message(STATUS "Continuing...")
endif(SIZEOF_SHORT EQUAL 2)

check_type_size("float" SIZEOF_FLOAT)
check_type_size("double" SIZEOF_DOUBLE)
if(SIZEOF_DOUBLE EQUAL 8)
  set(YARP_FLOAT64 "double")
else(SIZEOF_DOUBLE EQUAL 8)
  if(SIZEOF_FLOAT EQUAL 8)
    set(YARP_FLOAT64 "float")
  endif(SIZEOF_FLOAT EQUAL 8)
endif(SIZEOF_DOUBLE EQUAL 8)

if(SIZEOF_DOUBLE EQUAL 4)
  set(YARP_FLOAT32 "double")
else()
  if(SIZEOF_FLOAT EQUAL 4)
    set(YARP_FLOAT32 "float")
  endif()
endif()

if (SIZEOF_LONG EQUAL 8)
  set(YARP_INT64 "long")
else ()
  check_type_size("long long" SIZEOF_LONGLONG)
  if (SIZEOF_LONGLONG EQUAL 8)
    set(YARP_INT64 "long long")
  else ()
    check_type_size("__int64" SIZEOF___INT64)
    if (SIZEOF___INT64 EQUAL 8)
      set(YARP_INT64 "__int64")
    endif ()
  endif ()
endif ()

#########################################################################
# Set up compile flags, and configure ACE

set(YARP_ADMIN "$ENV{YARP_ADMIN}")

if (YARP_ADMIN)
  # be very serious about warnings if in admin mode
  add_definitions(-Werror -Wfatal-errors)
endif (YARP_ADMIN)

add_definitions(-DYARP_PRESENT)
add_definitions(-D_REENTRANT)
# due to cmake 2.6.0 bug, cannot use APPEND here
# set_property(GLOBAL APPEND PROPERTY YARP_DEFS -D_REENTRANT)
set_property(GLOBAL PROPERTY YARP_DEFS -D_REENTRANT)

# on windows, we have to tell ace how it was compiled
if(WIN32)
    ## check if we are using the CYGWIN compiler
    if(NOT CYGWIN)
        add_definitions(-DWIN32 -D_WINDOWS)
    else(NOT CYGWIN)
        add_definitions(-DCYGWIN)
    endif(NOT CYGWIN)

    ## check if we are using the MINGW compiler
    if(MINGW)
        add_definitions(-D__MINGW__ -D__MINGW32__ "-mms-bitfields" "-mthreads" "-Wpointer-arith" "-pipe")
        # "-fno-exceptions" can be useful too... unless you need exceptions :-)
        if(MSYS)
            add_definitions(-D__ACE_INLINE__ -DACE_HAS_ACE_TOKEN -DACE_HAS_ACE_SVCCONF -DACE_BUILD_DLL)
        else(MSYS)
            add_definitions("-fvisibility=hidden" "-fvisibility-inlines-hidden" "-Wno-attributes")
        endif(MSYS)
    endif(MINGW)

    ## check if we are using the MSVC compiler
    if(MSVC)
        # ACE uses a bunch of functions MSVC warns about.
        # The warnings make sense in general, but not in this case.
        # this gets rids of deprecated unsafe crt functions
        add_definitions(-D_CRT_SECURE_NO_DEPRECATE)
        # this gets rid of warning about deprecated POSIX names
        add_definitions(-D_CRT_NONSTDC_NO_DEPRECATE)

        # disable: warning C4355: 'this' : used ...
        ## this never worked, giving up.
        #add_definitions(/wd4355)

        # Traditionally, we add "d" postfix to debug libraries
        set(CMAKE_DEBUG_POSTFIX "d")
    endif(MSVC)

endif(WIN32)

mark_as_advanced(SKIP_ACE)

if (SKIP_ACE)
  set(ACE_LIBRARIES pthread rt)
else ()
  set(YARP_HAS_ACE 1)

  find_package(ACE REQUIRED)

  include(YarpCheckTypeSize) # regular script does not do C++ types
  set(CMAKE_EXTRA_INCLUDE_FILES ace/config.h ace/String_Base_Const.h)
  set(CMAKE_REQUIRED_INCLUDES ${ACE_INCLUDE_DIR} ${ACE_INCLUDE_CONFIG_DIR})
  set(CMAKE_REQUIRED_LIBRARIES ${ACE_LIBRARIES})
  yarp_check_type_size(ACE_String_Base_Const::size_type SIZE_TYPE)
  set(CMAKE_EXTRA_INCLUDE_FILES) 
  set(CMAKE_REQUIRED_INCLUDES)
  set(CMAKE_REQUIRED_LIBRARIES)
  set(YARP_USE_ACE_STRING_BASE_CONST_SIZE_TYPE ${HAVE_SIZE_TYPE})

  include(YarpCheckStructHasMember)
  set(CMAKE_REQUIRED_INCLUDES ${ACE_INCLUDE_DIR} ${ACE_INCLUDE_CONFIG_DIR})
  set(CMAKE_REQUIRED_LIBRARIES ${ACE_LIBRARIES})
  yarp_check_struct_has_member("ACE_INET_Addr" is_loopback ace/INET_Addr.h YARP_ACE_ADDR_HAS_LOOPBACK_METHOD) 
  set(CMAKE_EXTRA_INCLUDE_FILES) 
  set(CMAKE_REQUIRED_LIBRARIES)

  # From YARP 6.0.2 on, __ACE_INLINE__ is needed
  INCLUDE (CheckCXXSourceCompiles)
  set(CMAKE_REQUIRED_INCLUDES ${ACE_INCLUDE_DIR} ${ACE_INCLUDE_CONFIG_DIR})
  set(CMAKE_REQUIRED_LIBRARIES ${ACE_LIBRARIES})
  file(READ ${CMAKE_SOURCE_DIR}/conf/ace_test.cpp YARP_ACE_NEEDS_INLINE_CPP)
  CHECK_CXX_SOURCE_COMPILES("${YARP_ACE_NEEDS_INLINE_CPP}" YARP_ACE_COMPILES_WITHOUT_INLINE)
  set(CMAKE_EXTRA_INCLUDE_FILES) 
  set(CMAKE_REQUIRED_LIBRARIES)

  if (NOT YARP_ACE_COMPILES_WITHOUT_INLINE)
    ADD_DEFINITIONS(-D__ACE_INLINE__)
  endif ()

endif ()


include(CheckCXXCompilerFlag)


check_cxx_compiler_flag("-fvisibility=hidden" CXX_HAS_FVISIBILITY_HIDDEN)
if(CXX_HAS_FVISIBILITY_HIDDEN)
    set(VISIBILITY_HIDDEN_FLAGS "-fvisibility=hidden")
else(CXX_HAS_FVISIBILITY_HIDDEN)
    set(VISIBILITY_HIDDEN_FLAGS)
endif(CXX_HAS_FVISIBILITY_HIDDEN)

check_cxx_compiler_flag("-fvisibility-inlines-hidden" CXX_HAS_FVISIBILITY_INLINES_HIDDEN)
if(CXX_HAS_FVISIBILITY_INLINES_HIDDEN)
    set(VISIBILITY_HIDDEN_FLAGS "${VISIBILITY_HIDDEN_FLAGS} -fvisibility-inlines-hidden")
endif(CXX_HAS_FVISIBILITY_INLINES_HIDDEN)

check_cxx_compiler_flag("-Wdeprecated-declarations" CXX_HAS_WDEPRECATED_DECLARATIONS)
if(CXX_HAS_WDEPRECATED_DECLARATIONS)
    set(DEPRECATED_DECLARATIONS_FLAGS "-Wdeprecated-declarations")
else(CXX_HAS_WDEPRECATED_DECLARATIONS)
    set(DEPRECATED_DECLARATIONS_FLAGS)
endif(CXX_HAS_WDEPRECATED_DECLARATIONS)

# Translate the names of some YARP options, for yarp_config_options.h.in
# and YARPConfig.cmake.in
set (YARP_HAS_MATH_LIB ${CREATE_LIB_MATH})
set (YARP_HAS_NAME_LIB ${YARP_USE_PERSISTENT_NAMESERVER})

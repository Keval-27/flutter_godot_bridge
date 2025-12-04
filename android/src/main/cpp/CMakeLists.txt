cmake_minimum_required(VERSION 3.4.1)
project(flutter_godot_bridge_plugin)

# Go up three levels to android root
get_filename_component(PLUGIN_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)
set(GODOT_AAR "${PLUGIN_ROOT}/libs/godot-lib-debug.aar")

message(STATUS "Plugin root: ${PLUGIN_ROOT}")
message(STATUS "Looking for AAR at: ${GODOT_AAR}")

if(NOT EXISTS "${GODOT_AAR}")
    message(FATAL_ERROR "Godot AAR not found at: ${GODOT_AAR}")
endif()

# Create extraction directory
set(GODOT_AAR_EXTRACT_DIR "${CMAKE_BINARY_DIR}/godot_aar")
file(MAKE_DIRECTORY "${GODOT_AAR_EXTRACT_DIR}")

# Extract AAR (AAR is a ZIP file)
execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xf "${GODOT_AAR}"
        WORKING_DIRECTORY "${GODOT_AAR_EXTRACT_DIR}"
        RESULT_VARIABLE EXTRACT_RESULT
)

if(NOT EXTRACT_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to extract Godot AAR")
endif()

# Verify the .so file exists after extraction
set(GODOT_SO "${GODOT_AAR_EXTRACT_DIR}/jni/${ANDROID_ABI}/libgodot_android.so")
if(NOT EXISTS "${GODOT_SO}")
    message(FATAL_ERROR "Godot .so not found at: ${GODOT_SO} after extraction")
endif()

message(STATUS "Found Godot .so at: ${GODOT_SO}")

# Import Godot engine shared library
add_library(godot_android SHARED IMPORTED)
set_target_properties(godot_android PROPERTIES
        IMPORTED_LOCATION "${GODOT_SO}"
)

# Create the bridge library
add_library(flutter_godot_bridge_plugin SHARED
        godot_bridge.cpp
)

# Find system libraries
find_library(log-lib log)

# Link everything
target_link_libraries(flutter_godot_bridge_plugin
        godot_android
        ${log-lib}
)

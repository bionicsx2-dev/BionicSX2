# BionicSX2 Metal Rendering Backend
# AUDIT REFERENCE: Section 13.4

file(GLOB METAL_SOURCES *.mm *.cpp)
file(GLOB METAL_SHADERS *.metal)
file(GLOB METAL_HEADERS *.h)

add_library(metal-backend STATIC ${METAL_SOURCES})

target_include_directories(metal-backend PUBLIC
    ${CMAKE_SOURCE_DIR}/src
    ${PCSX2_ROOT}/common
    ${PCSX2_ROOT}/3rdparty/include
)

target_compile_features(metal-backend PUBLIC cxx_std_20)
target_compile_definitions(metal-backend PUBLIC PCSX2_TARGET_IOS=1)

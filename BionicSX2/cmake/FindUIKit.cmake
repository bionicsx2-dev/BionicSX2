# PORTED FROM: New file — BionicSX2 iOS Port
# AUDIT REFERENCE: Section 4.3 (UIView/UIWindow replaces NSView/NSWindow)
# STATUS: NEW

# Find module for UIKit.framework (Audit Section 4.3)
# UIKit is always available on iOS — replaces AppKit from macOS

find_library(UIKIT_LIBRARY UIKit)
mark_as_advanced(UIKIT_LIBRARY)

if(UIKIT_LIBRARY)
    add_library(UIKit::UIKit UNKNOWN IMPORTED)
    set_target_properties(UIKit::UIKit PROPERTIES
        IMPORTED_LOCATION "${UIKIT_LIBRARY}"
    )
endif()

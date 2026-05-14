# PORTED FROM: New file — BionicSX2 iOS Port
# AUDIT REFERENCE: Section 8.3 (GameController.framework for input)
# STATUS: NEW

# Find module for GameController.framework (Audit Section 8.3)
# GCController handles MFi, PS4/5, Xbox controllers natively on iOS

find_library(GAMECONTROLLER_LIBRARY GameController)
mark_as_advanced(GAMECONTROLLER_LIBRARY)

if(GAMECONTROLLER_LIBRARY)
    add_library(GameController::GameController UNKNOWN IMPORTED)
    set_target_properties(GameController::GameController PROPERTIES
        IMPORTED_LOCATION "${GAMECONTROLLER_LIBRARY}"
    )
endif()

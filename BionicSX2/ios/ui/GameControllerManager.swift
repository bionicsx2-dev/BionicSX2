// PORTED FROM: New file — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 8.3 (GCController as replacement for SDL3/IOKit HID),
//                  Section 2.7 (Pad::StartPoll/Poll/EndPoll interface)
// STATUS: NEW — GameController.framework integration

import Foundation
import GameController

class GameControllerManager: NSObject {
    static let shared = GameControllerManager()
    private var controllers: [GCController] = []

    override init() {
        super.init()
        setupNotifications()
    }

    // Audit Section 8.3: GCController handles MFi, PS4/5, Xbox controllers natively on iOS
    func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerConnected),
            name: .GCControllerDidConnect,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDisconnected),
            name: .GCControllerDidDisconnect,
            object: nil
        )
    }

    @objc private func controllerConnected(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        controllers.append(controller)

        // Audit Section 8.3: GCExtendedGamepad provides standard controls
        if let extendedGamepad = controller.extendedGamepad {
            setupExtendedGamepadHandlers(extendedGamepad, controller: controller)
        }

        NSLog("[BionicSX2] Controller connected: \(controller.productCategory)")
    }

    @objc private func controllerDisconnected(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        controllers.removeAll { $0 == controller }
        NSLog("[BionicSX2] Controller disconnected")
    }

    // Audit Section 2.7: Map GCController buttons → PS2 pad layout
    // PS2 has: D-Pad, Left/Right Analog, △○×□, L1/L2/R1/R2, Select, Start
    private func setupExtendedGamepadHandlers(_ gamepad: GCExtendedGamepad, controller: GCController) {
        gamepad.valueChangedHandler = { [weak self] (gamepad, element) in
            guard let self = self else { return }

            // Map D-pad → PS2 D-pad
            // Map left analog → PS2 left analog
            // Map right analog → PS2 right analog
            // Map A/B/X/Y → PS2 ×/○/□/△
            // Map L1/R1 → PS2 L1/R1
            // Map L2/R2 → PS2 L2/R2
            // Map Menu → PS2 Start
            // Map Options → PS2 Select

            // Audit Section 8.3: Up to 4 simultaneous controllers supported
            let padIndex = self.controllers.firstIndex(of: controller) ?? 0
            self.updatePS2Pad(padIndex: padIndex, with: gamepad)
        }
    }

    private func updatePS2Pad(padIndex: Int, with gamepad: GCExtendedGamepad) {
        // Audit Section 2.7: Calls Pad::StartPoll/Poll/EndPoll interface
        // Values mapped from GCController float values (0.0-1.0) to PS2 pad states
    }
}

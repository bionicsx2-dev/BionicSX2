// PORTED FROM: New file — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 4.3 (UIViewController hosting CAMetalLayer),
//                  Section 2.3-E/F (iOSVMManager init call)
// STATUS: NEW

import SwiftUI
import UIKit
import MetalKit

struct MetalViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MetalViewController {
        return MetalViewController()
    }

    func updateUIViewController(_ uiViewController: MetalViewController, context: Context) {}
}

class MetalViewController: UIViewController {
    private var metalLayer: CAMetalLayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        // PORTED: UIView/CAMetalLayer instead of NSView/CAMetalLayer (Audit Sec 4.3)
        metalLayer = CAMetalLayer()
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.bounds
        metalLayer.contentsScale = UIScreen.main.scale

        view.layer.addSublayer(metalLayer)

        // Audit Section 2.3-E/F: Initialize iOS VM with correct init order
        // iOSVMManager_Init() calls SysMemory::Reset() BEFORE cpuReset()
        // to prevent nVif HashBucket crash
        iOSVMManager_Init()

        // Metal renderer initialization deferred to ObjC++ layer
        // Audit Section 4.2: CAMetalLayer + GSDeviceMTL setup done in
        // ios/platform/CocoaTools.mm via a C-compatible bridge

        // Set up display link for frame pacing
        let displayLink = CADisplayLink(target: self, selector: #selector(frameStep))
        displayLink.add(to: .main, forMode: .common)
    }

    @objc private func frameStep() {
        // Audit Section 4.2: Frame rendering callback
        // Called by CADisplayLink at display refresh rate
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        metalLayer.frame = view.bounds
    }
}

// Extern C function for iOSVMManager
// Defined in ios/platform/iOSVMManager.mm
@_silgen_name("iOSVMManager_Init")
func iOSVMManager_Init()

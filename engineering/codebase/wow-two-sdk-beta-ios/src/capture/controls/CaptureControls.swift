@preconcurrency import AVFoundation
import Foundation

/// Installs the controls this instance owns. Call `apply` and `remove` on the capture session's serial queue.
@available(iOS 18.0, *)
public final class CaptureControls: NSObject, AVCaptureSessionControlsDelegate {
    private let queue: DispatchQueue
    private let onChange: @MainActor @Sendable (String, CaptureControlValue) -> Void
    private let onAppearance: @MainActor @Sendable (CaptureControlsAppearance) -> Void
    private weak var device: AVCaptureDevice?
    private var previous: [CaptureControlSpec] = []
    private var installed: [AVCaptureControl?] = []

    public init(queue: DispatchQueue, onChange: @escaping @MainActor @Sendable (String, CaptureControlValue) -> Void,
                onAppearance: @escaping @MainActor @Sendable (CaptureControlsAppearance) -> Void = { _ in }) {
        self.queue = queue
        self.onChange = onChange
        self.onAppearance = onAppearance
    }

    public func apply(_ specs: [CaptureControlSpec], to session: AVCaptureSession, device: AVCaptureDevice) {
        guard session.supportsControls else { return }
        let desired = CaptureControlsPlan.fitted(specs, supportsControls: true, limit: session.maxControlsCount,
                                                 canZoom: device.maxAvailableVideoZoomFactor > device.minAvailableVideoZoomFactor)
        guard !desired.isEmpty else {
            remove(from: session)
            return
        }

        if self.device === device, CaptureControlsPlan.definitionsMatch(previous, desired) {
            for ((old, new), control) in zip(zip(previous, desired), installed) where old != new {
                if let control { setSelection(new, on: control) }
            }
        } else {
            remove(from: session)
            session.setControlsDelegate(self, queue: queue)
            self.device = device
            installed = desired.map { spec in
                let control = make(spec, device: device)
                guard session.canAddControl(control) else { return nil }
                session.addControl(control)
                return control
            }
        }
        previous = desired
    }

    public func remove(from session: AVCaptureSession) {
        installed.compactMap { $0 }.forEach(session.removeControl)
        if session.controlsDelegate === self { session.setControlsDelegate(nil, queue: nil) }
        installed = []
        previous = []
        device = nil
    }

    public func sessionControlsDidBecomeActive(_ session: AVCaptureSession) { appear(.active) }
    public func sessionControlsWillEnterFullscreenAppearance(_ session: AVCaptureSession) { appear(.fullscreen) }
    public func sessionControlsWillExitFullscreenAppearance(_ session: AVCaptureSession) { appear(.active) }
    public func sessionControlsDidBecomeInactive(_ session: AVCaptureSession) { appear(.inactive) }

    private func make(_ spec: CaptureControlSpec, device: AVCaptureDevice) -> AVCaptureControl {
        switch spec {
        case .systemZoom:
            return AVCaptureSystemZoomSlider(device: device)
        case let .discreteSlider(id, title, symbol, values, _, format):
            let slider = AVCaptureSlider(title, symbolName: symbol, values: values)
            slider.localizedValueFormat = format
            slider.setActionQueue(queue) { [onChange] value in
                Task { @MainActor in onChange(id, .slider(value)) }
            }
            setSelection(spec, on: slider)
            return slider
        case let .indexPicker(id, title, symbol, titles, _):
            let picker = AVCaptureIndexPicker(title, symbolName: symbol, localizedIndexTitles: titles)
            picker.setActionQueue(queue) { [onChange] index in
                Task { @MainActor in onChange(id, .index(index)) }
            }
            setSelection(spec, on: picker)
            return picker
        }
    }

    private func setSelection(_ spec: CaptureControlSpec, on control: AVCaptureControl) {
        switch (spec, control) {
        case let (.discreteSlider(_, _, _, _, selected, _), slider as AVCaptureSlider):
            if slider.value != selected { slider.value = selected }
        case let (.indexPicker(_, _, _, _, selected), picker as AVCaptureIndexPicker):
            if picker.selectedIndex != selected { picker.selectedIndex = selected }
        default:
            break
        }
    }

    private func appear(_ appearance: CaptureControlsAppearance) {
        Task { @MainActor [onAppearance] in onAppearance(appearance) }
    }
}

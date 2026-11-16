import Foundation

/// The actions an app can put in the iPhone Camera Control overlay, in priority order.
public enum CaptureControlSpec: Equatable, Sendable {
    case systemZoom
    case discreteSlider(id: String, title: String, symbol: String, values: [Float], selected: Float, valueFormat: String?)
    case indexPicker(id: String, title: String, symbol: String, titles: [String], selected: Int)

    var definition: Self {
        switch self {
        case .systemZoom: self
        case let .discreteSlider(id, title, symbol, values, _, format):
            .discreteSlider(id: id, title: title, symbol: symbol, values: values, selected: 0, valueFormat: format)
        case let .indexPicker(id, title, symbol, titles, _):
            .indexPicker(id: id, title: title, symbol: symbol, titles: titles, selected: 0)
        }
    }

    var isValid: Bool {
        switch self {
        case .systemZoom: true
        case let .discreteSlider(_, _, _, values, selected, _):
            values.count > 1 && values.allSatisfy(\.isFinite) && Set(values).count == values.count && values.contains(selected)
        case let .indexPicker(_, _, _, titles, selected):
            titles.count > 1 && titles.indices.contains(selected)
        }
    }
}

public enum CaptureControlValue: Equatable, Sendable {
    case slider(Float)
    case index(Int)
}

public enum CaptureControlsAppearance: Equatable, Sendable {
    case inactive
    case active
    case fullscreen
}

enum CaptureControlsPlan {
    static func fitted(_ specs: [CaptureControlSpec], supportsControls: Bool, limit: Int, canZoom: Bool) -> [CaptureControlSpec] {
        guard supportsControls, limit > 0 else { return [] }
        return Array(specs.lazy.filter { $0.isValid && ($0 != .systemZoom || canZoom) }.prefix(limit))
    }

    static func definitionsMatch(_ previous: [CaptureControlSpec], _ next: [CaptureControlSpec]) -> Bool {
        previous.map(\.definition) == next.map(\.definition)
    }
}

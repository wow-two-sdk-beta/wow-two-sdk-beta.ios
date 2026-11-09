import Foundation

/// Strips what a log line must not carry from a URL or path: the query, the fragment and any user info.
public enum UrlRedaction {
    /// `"/users?email=a@b.c#top"` → `"/users"`; `"https://u:p@host/x?y"` → `"https://host/x"`.
    public static func path(of text: String) -> String {
        if var components = URLComponents(string: text) {
            components.query = nil
            components.fragment = nil
            components.user = nil
            components.password = nil
            if let clean = components.string { return clean }
        }
        let cut = text.firstIndex { $0 == "?" || $0 == "#" } ?? text.endIndex
        return String(text[..<cut])
    }
}

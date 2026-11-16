import Foundation

enum Base64URL {
    static func encode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func decode(_ segment: some StringProtocol) -> Data? {
        let value = String(segment)
        guard !value.isEmpty, value.utf8.allSatisfy({ byte in
            (0x41...0x5A).contains(byte) || (0x61...0x7A).contains(byte)
                || (0x30...0x39).contains(byte) || byte == 0x2D || byte == 0x5F
        }) else { return nil }
        let pad = (4 - value.utf8.count % 4) % 4
        let base64 = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
            + String(repeating: "=", count: pad)
        guard let data = Data(base64Encoded: base64), encode(data) == value else { return nil }
        return data
    }
}

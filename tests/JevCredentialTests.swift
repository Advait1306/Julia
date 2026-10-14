import Alamofire
import Foundation
@testable import julia

final class JevResponseStub: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var headers: [String?] = []

    static var authorizations: [String?] {
        lock.lock()
        defer { lock.unlock() }
        return headers
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock()
        Self.headers.append(request.value(forHTTPHeaderField: "Authorization"))
        Self.lock.unlock()
        let choices = ["wifi": "off", "bluetooth": "off", "darkMode": "off",
                       "audioMute": "unchanged", "audioDevice": "unchanged",
                       "playback": "unchanged", "focusMode": "unchanged", "openApp": "unchanged"]
        let body = try! JSONSerialization.data(withJSONObject: ["answers": choices.mapValues { ["choice": $0] }])
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() { }
}

@main
struct JevCredentialTests {
    @MainActor static func main() async throws {
        let store = JevKeychain(service: "julia.jev.tests.\(UUID().uuidString)")
        defer { try? store.delete() }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [JevResponseStub.self]
        let jev = Jev(session: Session(configuration: configuration), apiKeyProvider: { try store.read() })
        let state = SettingsState(wifi: false, bluetooth: false, darkMode: false,
                                  audio: .init(devices: [], selectedDeviceID: nil, isMuted: nil),
                                  focus: .init(modes: nil, isActive: nil, currentModeID: nil), apps: [], vpns: [])
        try store.save("test-key-one")
        _ = try await jev.evaluate(prompt: "test", state: state)
        try store.save("test-key-two")
        _ = try await jev.evaluate(prompt: "test", state: state)
        precondition(JevResponseStub.authorizations == ["Bearer test-key-one", "Bearer test-key-two"],
                     "The same Jev instance must use the latest key for each request")
        try store.delete()
        do {
            _ = try await jev.evaluate(prompt: "test", state: state)
            preconditionFailure("Evaluation without a key must fail before sending a request")
        } catch {
            precondition((error as NSError).domain == "Jev")
        }
        precondition(JevResponseStub.authorizations.count == 2, "Removing a key must prevent further requests")
        print("PASS: Jev uses replacement credentials immediately and sends no request after removal")
    }
}

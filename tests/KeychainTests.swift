import Foundation

@main
struct KeychainTests {
    static func expect(_ condition: Bool, _ message: String) {
        precondition(condition, message)
    }

    static func main() throws {
        // A unique service isolates test data from Julia and all existing keys.
        let store = JevKeychain(service: "julia.tests.\(UUID().uuidString)")
        defer { try? store.delete() }
        expect(try store.read() == nil, "A new service must have no key")
        expect(try !store.containsKey(), "No key should be reported")
        try store.save("  test-key-one\n")
        expect(try store.containsKey(), "Saved key metadata must be discoverable")
        expect(try store.read() == "test-key-one", "Save must trim surrounding whitespace")
        try store.save("test-key-two")
        expect(try store.read() == "test-key-two", "Replacement must update the existing item")
        for invalid in ["", " \n", "key with spaces", "key\nwith-newline"] {
            do {
                try store.save(invalid)
                preconditionFailure("Invalid keys must be rejected")
            } catch JevKeychain.Failure.invalidKey { }
        }
        expect(try store.read() == "test-key-two", "Invalid input must preserve the saved key")
        try store.delete()
        expect(try store.read() == nil, "Delete must remove the secret")
        expect(try !store.containsKey(), "Delete must remove metadata")
        try store.delete()
        print("PASS: Keychain create, read, replace, validation, presence, and idempotent deletion")
    }
}

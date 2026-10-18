import SwiftUI

struct AIView: View {
    @ObservedObject var setup: AppSetup
    @Binding var apiKey: String

    var savesOnFocusLoss = true
    var showsSectionHeaders = true

    @State private var savedKey = ""

    var body: some View {
        Form {
            Section {
                LabeledContent("Jev") {
                    NativeAPIKeyField(text: $apiKey) {
                        if savesOnFocusLoss { save() }
                    }
                    .frame(minWidth: 0, idealWidth: 320, maxWidth: 320)
                    .frame(height: 22)
                    .privacySensitive()
                }
            } header: {
                if showsSectionHeaders { Text("Decision model") }
            } footer: {
                Text("Keys are encrypted and stored in Keychain")
            }

            SpeechModelSection(sst: setup.assistant.sst, showsSectionHeaders: showsSectionHeaders)
        }
        .formStyle(.grouped)
        .onAppear {
            do {
                apiKey = try setup.readAPIKey() ?? ""
                savedKey = apiKey
            } catch { print("Keychain: \(error.localizedDescription)") }
        }
        .onDisappear {
            if savesOnFocusLoss { save() }

            apiKey = ""
            savedKey = ""
        }
    }

    private func save() {
        guard apiKey != savedKey else { return }

        do {
            if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                try setup.removeAPIKey()
            } else {
                try setup.saveAPIKey(apiKey)
            }

            savedKey = apiKey
        } catch { print("Keychain: \(error.localizedDescription)") }
    }
}

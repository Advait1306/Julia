import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @ObservedObject var setup: AppSetup
    @ObservedObject var permissions: AppPermissions
    @ObservedObject var sst: SST
    @AppStorage("onboarding.step") private var savedStep = 1
    @State private var apiKey = ""

    private enum Step: Int {
        case permissions = 1, ai = 2, ready = 4

        var title: String {
            switch self {
                case .permissions: "Permissions"
                case .ai: "AI"
                case .ready: "Get Started"
            }
        }
    }

    // Resume the former second AI page (3) on the combined AI page.
    private var step: Step { Step(rawValue: savedStep) ?? .ai }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                content

                if step == .ready && !canContinue {
                    Text("Review the unfinished steps to start using Julia.")
                        .font(.callout).foregroundStyle(.secondary)
                }

                HStack {
                    if step != .permissions {
                        Button("Back") { savedStep = step == .ready ? Step.ai.rawValue : Step.permissions.rawValue }
                    }

                    Spacer()

                    Button(step == .ready ? "Start Using Julia" : "Continue", action: advance)
                        .keyboardShortcut(.defaultAction)
                        .disabled(!canContinue)
                }
            }
            .padding(24)
            .navigationTitle(step.title)
        }
        .frame(minWidth: 620, idealWidth: 680, minHeight: 580, idealHeight: 680)
        .task {
            setup.refreshKeyStatus()

            await permissions.refresh()

            await sst.restoreModelIfAvailable()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
            case .permissions:
                PermissionsView(permissions: permissions)

            case .ai:
                AIView(setup: setup, apiKey: $apiKey, savesOnFocusLoss: false)

            case .ready:
                GetStartedView()
        }
    }

    private var canContinue: Bool {
        switch step {
            case .permissions: permissions.voiceReady
            case .ai: !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && sst.modelState == .ready
            case .ready: permissions.voiceReady && setup.hasAPIKey && sst.modelState == .ready
        }
    }

    private func advance() {
        guard canContinue else { return }

        switch step {
            case .permissions:
                savedStep = Step.ai.rawValue

            case .ai:
                do {
                    try setup.saveAPIKey(apiKey)

                    savedStep = Step.ready.rawValue
                } catch { print("Onboarding: \(error.localizedDescription)") }

            case .ready:
                Task {
                    if await setup.complete() { dismissWindow(id: "onboarding") }
                }
        }
    }
}

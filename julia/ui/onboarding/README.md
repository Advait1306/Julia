# Julia setup

Native SwiftUI onboarding lives in this directory; its permission and AI panels
are shared with `../settings`. The first launch opens the permissions page,
followed by AI and Get Started. AI contains Decision model (Jev key) and Speech model
sections in one native Form. Its Continue button requires a key and a ready
speech model. Saved progress from either former AI step resumes on this page.
Get Started displays a Command symbol that turns green while right Command is
held. A separate shortcut observer provides feedback without recording or
running a command during first-time setup, and stops when the page is closed.
Onboarding uses `NavigationStack` with native Back and Continue buttons below
each page and a compact native titlebar with traffic lights. Settings uses `NavigationSplitView` with a
standard sidebar `List`, native `.searchable`, and an always-visible sidebar.
All panels use grouped `Form`, `Section`, and `LabeledContent`; there are no
custom cards, search fields, shortcut badges, branding footers, or bottom bars.
Closing it preserves the current step. The menu bar and General settings reopen it.
Voice hotkeys start once setup finishes. Existing completed installations start
normally, and revoked permissions or removed keys can be repaired in Settings.

## Permissions

| Access | Why | Setup requirement |
| --- | --- | --- |
| Microphone | Capture audio while right Command is held | Required for voice |
| Input Monitoring | Observe right Command in other apps | Required for voice; existing Accessibility access also satisfies the hotkey implementation |
| Bluetooth | Read and change Bluetooth power | Optional; requested by the Enable button |
| Automation → System Events | Change macOS light/dark appearance | Optional; the consent request runs off the main thread and changes no appearance setting |
| Full Disk Access | Read/write the Focus database used by FocusKit | Optional; manually add Julia in System Settings and restart if macOS requests it |

Full Disk Access has no public authorization query. The displayed Focus status
checks access to the specific configuration/assertion files used by FocusKit;
it does not claim to inspect macOS's privacy database. Missing files are shown
as unavailable. Focus observers restart when file access becomes available.
No Screen Recording, Apple Speech Recognition, or Location access is needed
by the current implementation. Transcription uses the on-device FluidAudio model.

Permissions refresh every two seconds while the permissions panel is visible.
The final setup action rechecks permissions and key presence before completing.
The native `⌘,` menu key equivalent is local to Julia; it is not registered as a
global shortcut. Right Command is the existing global voice trigger.

## Credentials

`JevKeychain` stores one generic password in the macOS login keychain, with a
bundle-scoped service, synchronization disabled, and the default ACL restricting
secret access to the creating app's code-signing identity. This uses the macOS
file-based keychain; iOS accessibility attributes are intentionally not applied.
Setup checks key metadata without loading the secret. Opening AI reads the
stored value into a native AppKit `NSSecureTextField` hosted in SwiftUI. The same
control uses a secure cell when idle and a plain text cell when focused. AppKit
provides selection, cursor placement, and scrolling; clicking outside the field
ends editing and restores the secure cell. There is no eye button or replacement
of the text control. Onboarding saves edits when Continue is pressed. Settings
saves on Return or focus loss;
committing an intentionally cleared field removes the stored key.
The transient field value is cleared on closing/leaving the form and is never
written to UserDefaults or the launch scheme. Keychain failures appear in the UI.

Jev reads the key for each evaluation, so replacement and deletion affect the
next request without restarting. Already-sent requests may finish. Only the
Authorization header contains the credential. Saving checks local input and
storage; Jev validates the credential when a command runs.

## Checks

From the repository root, run `tests/run-onboarding-checks.sh`. It builds the app,
checks the native field's focus, cursor, fixed width, identity, and remasking,
checks Keychain create/read/replace/delete behavior, and uses a URLProtocol stub
to check per-request credential replacement and removal. Tests use synthetic
credentials with unique Keychain service names and remove them after the run.
They never contact Jev or modify Julia's real credentials.

Manual UI checks: first launch/resume, required permission denial and recovery,
optional grants, key editing and focus masking, model download/failure/retry, setup
completion, Settings navigation/search, and Open at Login approval. Real TCC
consent and login registration should be checked in a signed app by its user.

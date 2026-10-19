# Julia

Julia is an ultrafast Siri-like assistant for macOS. It uses a system one model called [Jev](https://typesafe.ai/blog/introducing-system-one-models-and-jev). Julia only works with boolean(ish) operations, as that's Jev's only supported output. There are plans to add a standard LLM layer as a fallback for non-boolean tasks.

As Jev is priced extremely well, inference barely costs anything. In my one month of extensive testing, I was only able to spend $0.20. I think it should be possible to run a similar model locally to eliminate this cost as well.

The only KPI that Julia has is speed. **Supported operations are completed end to end within 100ms.**

## Supported operations

| Area | Supported operations | Example |
| --- | --- | --- |
| Wi-Fi | Enable, disable, toggle | “Turn off Wi-Fi” |
| Bluetooth | Enable, disable, toggle | “Toggle Bluetooth” |
| Appearance | Dark mode, light mode, toggle | “Switch to light mode” |
| Audio mute | Mute, unmute, toggle mute | “Unmute my Mac” |
| Audio output | Switch to an available output device | “Switch audio to my speakers” |
| Media playback | Play/resume, pause | “Pause the music” |
| Focus | Activate an existing mode, switch modes, disable Focus; toggle using known state | “Turn on Work Focus” |
| Applications | Launch or bring one installed app to the foreground | “Open Codex” |
| VPNs | Connect, disconnect, toggle; control multiple VPNs with exceptions | “Disconnect all VPNs except Tailscale” |

## AI models

Julia uses two models:

1. Transcription model — Parakeet Unified EN 0.6B
2. Decision model — Jev by TypeSafe AI

You are expected to provide a [Jev API key](https://console.typesafe.ai/keys). The transcription model is downloaded for you during onboarding.

## macOS APIs & permissions

Julia needs extensive permissions to your system to do tasks such as changing Focus mode. No data is ever sent outside (except to the decision model). All the code for Julia is open source; you can ask your nearest AI agent to vet it. :)

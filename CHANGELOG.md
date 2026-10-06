# Changelog

This fork's releases are dated (`vYYYY-MM-DD`). Entries are written for
players; the build-level detail stays in the commit log and in each release's
notes.

## v2026-10-06

First release published from this fork. Seventeen cores in the package —
upstream's set plus Flycast and SwanStation — on top of upstream's RADV
frontend.

### Controller

- DualSense rumble through the joypad driver
- DualSense haptic feedback streamed through the pad's audio port
- Adaptive triggers and compatible vibration modes selected when the pad
  opens

### New cores

- **Flycast** — Dreamcast, Naomi and Atomiswave. Dreamcast Now presence,
  selectable community DNS (Shuouma and friends), a DreamPi-compatible
  configuration page served by the console, and a configurable MAC identity.
  The VMU's buzzer can also play through the DualSense speaker.
- **SwanStation** — PlayStation, as an alternative to Beetle PSX HW.

### Online play (Flycast)

- Dreamcast Now reports which game you're playing to dreamcast.online
- Community DNS selection for the game services that remain online
- Inbound UDP through NAT verified end to end; match hosting in Alien Front
  Online is still being worked on

## Upstream baseline

Everything upstream through the `dualsense-rumble` merge, on
[mihawk-99/PS5_RetroArch](https://github.com/mihawk-99/PS5_RetroArch)
v0.5.7-alpha.5: RADV Vulkan rendering, XMB, native input and audio, the
hardware-rendered cores (PPSSPP, Dolphin, LRPS2, Beetle PSX HW,
Mupen64Plus-Next, Azahar) and the rest of upstream's verified feature set.

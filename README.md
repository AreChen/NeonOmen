# NeonOmen

A threat meter for World of Warcraft Forever, customized with a neon-style interface and English, Traditional Chinese, and Simplified Chinese text.

## Features

- Threat bars, configurable warnings, and optional threat per second.
- Customizable theme color, glow, and window background opacity.
- Test mode for previewing the display.
- A low-layer meter that stays below system settings and dialogs.
- NeonCast-inspired dark tracks, shaded fills, restrained glow and a clear progress edge.

## Installation

The installation folder retains the original name for compatibility. Copy this repository's addon files into `Interface/AddOns/OmenReloadedForever`, then reload the game UI. The development repository and the installed addon are separate copies; changes need to be copied into the game directory.

Use `/orf` to open settings and `/orf test` to toggle test mode.

`1.0.4-alpha.1` is a development build awaiting verification in the Forever client.
Existing saved settings and the `OmenReloadedForever` installation folder are retained.

## Development

Install `requirements-dev.txt` in a virtual environment, then run
`python -m pytest tests -q` and `python tools/package.py`.
See [the verification checklist](docs/DEVELOPMENT.md) before releasing a stable build.
Pull request checks also upload the installable ZIP as the `NeonOmen-test-build` artifact.

## Attribution and license

The original OmenReloadedForever addon identifies Cryptotaxi as its author. This repository contains the local customization of that addon. No license was included in the installed copy; redistribution rights have not been established. The neon card assets were copied from the local NeonCast project.

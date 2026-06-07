# easyeffects

EasyEffects **input** preset for the Elgato Wave:3 USB microphone.

Stows to `~/.local/share/easyeffects/input/wave3-voice.json` (EasyEffects 8.x
stores presets under `~/.local/share`, not `~/.config`).

## Dependencies

Installed via `_pkgs_base` in the justfile:

- `easyeffects` — pulls `rnnoise` (noise suppression) as a hard dependency
- `lsp-plugins-lv2` — Linux Studio Plugins (LV2), powers the Filter, Equalizer,
  Compressor and Limiter. Without it those effects show "Effect Not Available".

The Wave:3 is a USB condenser with its own preamp/ADC — no external pre-amp or
extra kernel config is needed; it is class-compliant and detected out of the box.

## Effect chain

`filter → rnnoise → compressor → equalizer → deesser → limiter`
("clean → shape → control → protect")

- **Filter** — high-pass ~80 Hz, removes rumble/handling
- **RNNoise** — full-wet noise suppression (wet 0 dB) with voice-activity
  gating (VAD enabled, threshold 70) so it ducks between phrases
- **Compressor** — 3:1, 15 ms attack, +6 dB makeup, evens out level
- **Equalizer** — a few parametric moves: 300 Hz mud cut, ~1 kHz honk cuts,
  4 kHz presence boost, 10 kHz air shelf (tuned by ear; adjust to taste)
- **De-esser** — tames sibilance from the presence boost
- **Limiter** — −1.5 dB safety ceiling, boost/ALR off (transparent)

## Apply on a new machine

The preset file is deployed by stow but EasyEffects does **not** auto-apply it:

1. Open EasyEffects → **Input** tab
2. **Presets** (bottom-left) → load **`wave3-voice`**

This is a **one-time** step per machine. The Hyprland autostart runs
`easyeffects --service-mode` (see `hypr/.config/hypr/hyprland.conf`), which keeps
the last-loaded preset active across reboots — but it does **not** perform this
first load itself.

Mic gain is set on the device, not in software — keep the hardware gain low
enough that your voice peaks around −12 dB (avoids ADC clipping before any
effects run).

## Note on re-saving

This file is a stow symlink. If you re-save the preset from EasyEffects and it
replaces the symlink with a regular file, just re-link it:

```sh
cp ~/.local/share/easyeffects/input/wave3-voice.json \
   ~/.dotfiles/easyeffects/.local/share/easyeffects/input/wave3-voice.json
rm ~/.local/share/easyeffects/input/wave3-voice.json
just restow easyeffects
```

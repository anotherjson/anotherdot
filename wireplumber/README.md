# wireplumber

WirePlumber config + script that fixes the **Elgato Wave:3 microphone going
silent** when the device is also used for audio output.

Stows to:
- `~/.config/wireplumber/wireplumber.conf.d/51-wave3.conf`
- `~/.local/share/wireplumber/scripts/wavedevicefix.lua`

## The problem

The Wave 1 / Wave 3 / Wave XLR have a long-standing firmware quirk on Linux: if
a **playback** stream opens on the device *before* mic capture starts, the
microphone delivers pure digital silence (capture peak is exactly `0`). Because
the Wave:3 is both a mic *and* a headphone output, any system sound routed to it
silences the mic.

It is **not** a mute, gain, or routing issue — `amixer`/`wpctl` show the capture
unmuted at full gain, and the USB capture stream is `RUNNING`. The signal is
zeroed at the device level by the playback-before-capture ordering.

## The fix

`wavedevicefix.lua` (loaded via `51-wave3.conf`):

1. Creates a virtual **null sink**.
2. Links the Wave:3 mic source to it, forcing **capture to start first**.
3. Once that link is bound, recreates the Wave:3 **playback sink** (`Wave3
   Sink`) so headphone monitoring still works.
4. Tears both down when the device is unplugged.

`51-wave3.conf` disables the auto-created Wave:3 output node and renames the
input node to `wave3-source` so the script can manage ordering.

## Provenance

Adapted from [jmansar/wavexlr-on-linux-cfg](https://github.com/jmansar/wavexlr-on-linux-cfg)
(`cfg1`, MIT). These are our own **local copies** — intentionally not tracked
against upstream. Local hardening on top of upstream:

- everything `local`-scoped (no globals leaking into WirePlumber's shared Lua
  env), functions forward-declared for mutual references
- failed capture link resets `nullSinkLink` so it can retry (upstream set a
  stray global, wedging the retry guard)
- the port `ObjectManager` is module-scoped and dropped on device removal, with
  a re-entrancy guard so replugs don't stack managers/links/sinks
- **playback sink is created from the link's activate-success callback** (with a
  double-create guard), because the upstream `onLinkCreated` trigger races on an
  unbound proxy id and reliably fails to create the sink

## Requirements

- PipeWire + WirePlumber **≥ 0.5** (both already in `_pkgs_base`).
- No extra package needed at runtime. (`alsa-utils` is handy for diagnosing the
  device with `amixer -c <card> sget 'Mic Capture'` but isn't required.)

## Apply / verify

```sh
just restow wireplumber          # or: stow wireplumber
systemctl --user restart wireplumber
```

Check the script ran and the sink came up:

```sh
journalctl --user -u wireplumber --since "30 seconds ago" | grep wavedevicefix
wpctl status | grep -E "wave3-source|Wave3 Sink"
```

Definitive test — record the mic while audio plays *to* the Wave:3; capture peak
should be non-zero (it was exactly `0` before the fix):

```sh
SINK=$(wpctl status | grep "Wave3 Sink"      | grep -oE '[0-9]+' | head -1)
SRC=$(wpctl status  | grep "Elgato Wave 3 Mono" | grep -oE '[0-9]+' | head -1)
pw-play --target "$SINK" /usr/share/sounds/alsa/Front_Center.wav &
pw-record --target "$SRC" /tmp/mictest.wav   # speak, then Ctrl-C
```

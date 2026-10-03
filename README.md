# Music Fairy (fixed for Linux)

Voice-controlled YouTube music player: press a key, say a song name, it plays
through MPD. A working, maintained fork of
[bugswriter/music_fairy](https://github.com/bugswriter/music_fairy) — same
architecture, but installable in one command and no longer dependent on dead
services.

```
you (keybind) ──> music-fairy
                    ├─ ffmpeg        record 5s from mic
                    ├─ vosk          offline speech-to-text (small model, ~50MB RAM)
                    ├─ yt-dlp        ytsearch1 → bestaudio stream URL
                    └─ mpc/MPD       add + play
```

Total RAM footprint: ~150MB. Runs fine on a Raspberry Pi with 1GB RAM
(32-bit or 64-bit).

## What was fixed vs. the original

| Original (broken)                  | Fixed                                            |
|------------------------------------|--------------------------------------------------|
| Invidious instance `vid.puffyan.us` (dead since ~2022) | `yt-dlp ytsearch1:` — no instance needed |
| `google_speech` (needs espeak + mpv, unmaintained) | `espeak-ng` directly, optional        |
| No install automation              | `install.sh` does everything                      |
| MPD must be pre-configured         | user MPD config written + auto-started            |
| `notify-send` assumed present      | guarded; falls back silently                      |
| 4s @44.1kHz capture, no error handling | 5s @16kHz (what vosk wants), errors reported  |

## Install

Requirements: Linux (Debian/Ubuntu, Fedora, Arch supported), a microphone,
internet access.

```sh
git clone https://github.com/KevinLy28/music_fairy.git
cd music_fairy
./install.sh
```

The installer:

1. installs system packages (`mpd mpc ffmpeg espeak-ng alsa-utils` ...)
2. creates a Python venv at `~/.local/share/music_fairy/venv` with `vosk` + `yt-dlp`
3. downloads the small vosk model (~40MB)
4. writes `~/.config/mpd/mpd.conf` and starts MPD (skips if MPD already runs)
5. installs `music-fairy` to `~/.local/bin` + default config to `~/.config/music-fairy/config`
6. binds the `s` key to `music-fairy` if a desktop session is detected (see Keybind below)

Re-run `./install.sh` any time to update yt-dlp/vosk (YouTube breaks often;
keep yt-dlp current).

## Usage

```sh
music-fairy --test-mic   # record + print what it heard, play nothing
music-fairy              # listen, then search & play
```

Say things like *"bohemian rhapsody"* or *"play daft punk hard harder..."*.

### Keybind (automatic)

`install.sh` binds the **`s`** key to `music-fairy` automatically when it
detects a desktop session — GNOME, Openbox (Raspberry Pi OS), labwc, i3,
with an sxhkd fallback. No graphical session (headless Pi, SSH)? It skips
this step; just run `music-fairy` manually, via SSH, or from a GPIO button.

```sh
MUSIC_FAIRY_KEY=super+s ./install.sh   # re-run to rebind (recommended for daily use:
                                       # bare "s" also fires while typing)
MUSIC_FAIRY_KEYBIND=0  ./install.sh    # don't touch keybinds at all
```

### Stop / control playback

Use `mpc` (or any MPD client): `mpc stop`, `mpc pause`, `mpc volume 80`.

## Configuration

`~/.config/music-fairy/config`:

```sh
MIC_DEVICE="default"      # your mic; list with: arecord -l   (e.g. "hw:1,0")
LISTEN_SECONDS=5
SAY_ENABLED=1             # spoken confirmations (espeak-ng)
YT_QUERY_SUFFIX=""        # e.g. "song audio" (original behaviour)
```

## Troubleshooting

- **"I didn't catch that"** — wrong `MIC_DEVICE` or too quiet. Test with
  `arecord -d 3 test.wav && aplay test.wav`, then set `MIC_DEVICE`.
- **No sound** — check `mpc status` and MPD's output: `~/.local/share/mpd/log`.
- **"no YouTube result"** — yt-dlp outdated (`./install.sh` again) or YouTube
  throttling your IP.
- **Raspberry Pi**: use `yt-dlp` from the venv (installer does this); avoid
  pip-installing as root.

## Uninstall

```sh
./uninstall.sh
```

Removes the script, venv, model and configs (leaves MPD config/system packages).

## Credits & License

Original idea & script: [Suraj Kushwah / bugswriter](https://bugswriter.com).
This fork is licensed under GPL-3 like the original.

#!/usr/bin/env bash
# music-fairy uninstaller (leaves MPD config and system packages alone)
set -u

echo "Removing music-fairy..."
rm -f "$HOME/.local/bin/music-fairy"
rm -rf "$HOME/.local/share/music_fairy"
rm -rf "$HOME/.cache/music-fairy"
rm -rf "$HOME/.config/music-fairy"

echo "Done. Not removed (edit/delete manually if wanted):"
echo "  - MPD config:  ~/.config/mpd/mpd.conf"
echo "  - MPD data:    ~/.local/share/mpd/"
echo "  - system packages: mpd mpc ffmpeg espeak-ng (apt/dnf/pacman remove ...)"

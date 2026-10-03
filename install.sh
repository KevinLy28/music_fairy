#!/usr/bin/env bash
# music-fairy installer for Linux
# Re-run any time to update yt-dlp/vosk and the speech model.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$HOME/.local/share/music_fairy"
VENV="$DATA_DIR/venv"
BIN_DIR="$HOME/.local/bin"
MODEL="vosk-model-small-en-us-0.15"
MODEL_URL="https://alphacephei.com/vosk/models/$MODEL.zip"

log() { printf '\n\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }

[ "$(uname -s)" = "Linux" ] || { echo "music-fairy only supports Linux." >&2; exit 1; }

# 1. system packages
if command -v apt-get >/dev/null 2>&1; then
    log "Installing system packages (apt)"
    sudo apt-get update -qq
    sudo apt-get install -y -qq mpd mpc ffmpeg espeak-ng alsa-utils \
        python3 python3-venv curl unzip ca-certificates libnotify-bin
elif command -v dnf >/dev/null 2>&1; then
    log "Installing system packages (dnf)"
    sudo dnf install -y mpd mpc espeak-ng alsa-utils python3 python3-pip curl unzip || true
    sudo dnf install -y ffmpeg || warn "ffmpeg not found in repos - enable RPM Fusion, then: sudo dnf install ffmpeg"
elif command -v pacman >/dev/null 2>&1; then
    log "Installing system packages (pacman)"
    sudo pacman -Sy --needed --noconfirm mpd mpc ffmpeg espeak-ng alsa-utils python curl unzip
else
    warn "unknown package manager - install manually: mpd mpc ffmpeg espeak-ng python3(venv) alsa-utils curl unzip"
fi

# 2. python venv with vosk + yt-dlp
log "Setting up Python environment (vosk, yt-dlp)"
mkdir -p "$DATA_DIR"
[ -d "$VENV" ] || python3 -m venv "$VENV"
"$VENV/bin/pip" install -q --upgrade pip
"$VENV/bin/pip" install -q --upgrade vosk yt-dlp

# 3. vosk speech model (~40 MB)
if [ ! -d "$DATA_DIR/$MODEL" ]; then
    log "Downloading Vosk model (~40 MB)"
    curl -L --fail --retry 3 -o "/tmp/$MODEL.zip" "$MODEL_URL"
    unzip -q "/tmp/$MODEL.zip" -d "$DATA_DIR"
    rm -f "/tmp/$MODEL.zip"
else
    log "Vosk model already present"
fi

# 4. MPD user config (skipped if one already exists; a running system MPD also works)
mkdir -p "$HOME/.local/share/mpd/playlists" "$HOME/Music" "$HOME/.config/mpd"
if [ ! -f "$HOME/.config/mpd/mpd.conf" ]; then
    log "Writing MPD config (~/.config/mpd/mpd.conf)"
    cat > "$HOME/.config/mpd/mpd.conf" <<EOF
music_directory    "$HOME/Music"
playlist_directory "$HOME/.local/share/mpd/playlists"
db_file            "$HOME/.local/share/mpd/database"
log_file           "$HOME/.local/share/mpd/log"
pid_file           "$HOME/.local/share/mpd/pid"
state_file         "$HOME/.local/share/mpd/state"
bind_to_address    "127.0.0.1"
port               "6600"
auto_update        "yes"
# no audio_output section: MPD auto-detects ALSA/PipeWire/PulseAudio
EOF
else
    log "MPD config already exists, leaving it untouched"
fi

if ! mpc status >/dev/null 2>&1; then
    log "Starting MPD"
    mpd "$HOME/.config/mpd/mpd.conf" || warn "MPD did not start (music-fairy will retry when used)"
fi

# 5. install launcher + default config
log "Installing music-fairy to $BIN_DIR"
mkdir -p "$BIN_DIR" "$HOME/.config/music-fairy"
install -m 755 "$REPO_DIR/music-fairy" "$BIN_DIR/music-fairy"

if [ ! -f "$HOME/.config/music-fairy/config" ]; then
    cat > "$HOME/.config/music-fairy/config" <<'EOF'
# music-fairy configuration (sourced as shell variables)
#MIC_DEVICE="default"          # see: arecord -l   (e.g. "hw:1,0" or "pulse")
#LISTEN_SECONDS=5              # how long to listen after launch
#SAY_ENABLED=1                 # speak confirmations (espeak-ng), 0 to mute
#YT_QUERY_SUFFIX=""            # appended to the search (original used "song audio")
#VOSK_MODEL_PATH="$HOME/.local/share/music_fairy/vosk-model-small-en-us-0.15"
EOF
fi

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) warn "$BIN_DIR is not in PATH - add it: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

log "Done!"
echo "  1. test your mic:   music-fairy --test-mic"
echo "  2. play something:  music-fairy    (then say a song name)"
echo "  3. optional: bind music-fairy to a key in your WM/DE"
echo "  config: ~/.config/music-fairy/config"

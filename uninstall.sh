#!/usr/bin/env bash
#
# Entfernt fedora-update wieder aus dem Benutzerverzeichnis.
#
set -euo pipefail

BINDIR="${BINDIR:-$HOME/.local/bin}"
APPDIR="${APPDIR:-$HOME/.local/share/applications}"
STATEDIR="${XDG_STATE_HOME:-$HOME/.local/state}/fedora-update"

rm -f "$BINDIR/fedora-update"       && echo "✔ Script entfernt"
rm -f "$APPDIR/fedora-update.desktop" && echo "✔ Menüeintrag entfernt"

if command -v update-desktop-database >/dev/null 2>&1; then
	update-desktop-database "$APPDIR" 2>/dev/null || true
fi

if [[ -d "$STATEDIR" ]]; then
	echo
	echo "Protokolle liegen weiterhin unter: $STATEDIR"
	echo "Löschen mit:  rm -rf \"$STATEDIR\""
fi

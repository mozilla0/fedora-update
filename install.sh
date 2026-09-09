#!/usr/bin/env bash
#
# Installiert fedora-update ins Benutzerverzeichnis und legt den Eintrag
# im Anwendungsmenü an. Kein root nötig.
#
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINDIR="${BINDIR:-$HOME/.local/bin}"
APPDIR="${APPDIR:-$HOME/.local/share/applications}"
BINPATH="$BINDIR/fedora-update"

mkdir -p "$BINDIR" "$APPDIR"

install -m 755 "$SRC/bin/fedora-update" "$BINPATH"
echo "✔ Script installiert:   $BINPATH"

sed "s|__BINPATH__|$BINPATH|g" "$SRC/share/applications/fedora-update.desktop" \
	>"$APPDIR/fedora-update.desktop"
chmod 644 "$APPDIR/fedora-update.desktop"
echo "✔ Menüeintrag angelegt: $APPDIR/fedora-update.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
	update-desktop-database "$APPDIR" 2>/dev/null || true
fi

# ~/.local/bin liegt auf Fedora normalerweise bereits im PATH.
case ":$PATH:" in
	*":$BINDIR:"*) ;;
	*)
		echo "▲ Hinweis: $BINDIR liegt nicht im PATH."
		echo "  Ergänze in ~/.bashrc:  export PATH=\"\$HOME/.local/bin:\$PATH\""
		;;
esac

echo
echo "Fertig. Start über das Anwendungsmenü («Systemaktualisierung») oder:"
echo "  fedora-update            interaktiv"
echo "  fedora-update --yes      ohne Rückfragen"
echo "  fedora-update --dry-run  Testlauf"

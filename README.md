# fedora-update

Ein Sammel-Update-Script für Fedora KDE. Aktualisiert Systempakete, Flatpaks und
Firmware in einem Durchgang und hält danach den Discover-Cache konsistent.

<img width="1372" height="1365" alt="image" src="https://github.com/user-attachments/assets/20e5d686-ed4e-4a91-a4ed-5b76908d4238" />

## Warum

Wer auf Fedora abwechselnd im Terminal (`dnf`, `flatpak`, `fwupdmgr`) und über
Discover aktualisiert, läuft früher oder später in dieses Problem: Discover
zeigt eine Zahl an Aktualisierungen an, bleibt beim Abrufen aber bei
«Aktualisierungen werden geholt …» hängen.

Der Grund ist ein Cache-Versatz. Discover und sein Hintergrunddienst
`DiscoverNotifier` führen einen eigenen Zwischenspeicher. Werden Pakete direkt
per `dnf` eingespielt, geht das an PackageKit vorbei – Discover bekommt davon
nichts mit und arbeitet mit einem Stand, den es nicht mehr auflösen kann.

Dieses Script löst das, indem es alle drei Update-Kanäle in fester Reihenfolge
abarbeitet und den Discover-Cache am Ende gezielt zurücksetzt.

## Installation

```bash
git clone https://github.com/mozilla0/fedora-update.git
cd fedora-update
make install
```

Alternativ ohne `make`:

```bash
./install.sh
```

Es wird kein root benötigt. Installiert wird nach:

| Datei | Ziel |
|---|---|
| Script | `~/.local/bin/fedora-update` |
| Menüeintrag | `~/.local/share/applications/fedora-update.desktop` |

Deinstallation mit `make uninstall` bzw. `./uninstall.sh`.

## Verwendung

Über das Anwendungsmenü als **«Systemaktualisierung»** – ein Rechtsklick auf den
Eintrag bietet zusätzlich «Ohne Rückfragen» und «Testlauf».

Oder im Terminal:

```bash
fedora-update                # interaktiv, fragt vor Firmware-Updates nach
fedora-update --yes          # vollautomatisch, keine Rückfragen
fedora-update --no-firmware  # Firmware-Updates überspringen
fedora-update --dry-run      # Testlauf, verändert nichts
```

## Ablauf

1. **Systempakete** – `sudo dnf upgrade --refresh`, im automatischen Modus
   zusätzlich `dnf autoremove`
2. **Flatpaks** – zuerst werden anstehende Aktualisierungen angezeigt und
   bestätigt, danach läuft `flatpak update -y --noninteractive`. Auf Wunsch
   werden zusätzlich ungenutzte Runtimes entfernt (die belegen sonst über die
   Zeit mehrere Gigabyte)
3. **Firmware** – `fwupdmgr refresh` und `fwupdmgr update` mit eigener
   Rückfrage, samt Warnung wenn kein Netzteil angeschlossen ist
4. **Discover** – Notifier beenden, Caches unter `~/.cache/discover`,
   `~/.cache/appstream` und `~/.cache/flatpak/system-cache` leeren,
   AppStream-Metadaten neu aufbauen, Notifier abgekoppelt neu starten

Zum Schluss folgen eine Zusammenfassung pro Kanal und ein Hinweis, falls ein
Neustart nötig ist.

## Protokolle

Jeder Lauf wird nach `~/.local/state/fedora-update/` geschrieben. Die letzten
20 Protokolle bleiben erhalten, ältere werden automatisch entfernt.

## Hinweise

- Das sudo-Passwort wird einmal zu Beginn abgefragt und über die Laufzeit offen
  gehalten, damit mitten in einem längeren Download keine Passwortabfrage
  dazwischenkommt.
- Firmware-Updates erfordern einen Neustart und sollten nur am Netzteil
  eingespielt werden. Das Script warnt, erzwingt aber nichts.
- Das Script darf nicht als root gestartet werden; es ruft `sudo` selbst dort
  auf, wo es nötig ist.

## Voraussetzungen

Fedora mit KDE Plasma 6. Fehlende Werkzeuge (`flatpak`, `fwupdmgr`,
`plasma-discover`) werden erkannt und der jeweilige Schritt übersprungen –
das Script läuft also auch auf einem System ohne Discover.

## Lizenz

MIT – siehe [LICENSE](LICENSE).

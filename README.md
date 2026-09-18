# fedora-update

Ein Sammel-Update-Script für Fedora KDE. Aktualisiert Systempakete, Flatpaks und
Firmware in einem Durchgang und hält danach den Discover-Cache konsistent. Ist die
Festplatte mit LUKS verschlüsselt und an das TPM gebunden, sorgt es zudem dafür,
dass die automatische Entsperrung ein Firmware-Update übersteht.

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
Eintrag bietet zusätzlich «Ohne Rückfragen», «Testlauf» und «TPM-Entsperrung
prüfen / neu einrichten».

Oder im Terminal:

```bash
fedora-update                # interaktiv, fragt vor Firmware-Updates nach
fedora-update --yes          # vollautomatisch, keine Rückfragen
fedora-update --no-firmware  # Firmware-Updates überspringen
fedora-update --no-tpm       # TPM-/LUKS-Prüfung überspringen
fedora-update --tpm-check    # nur TPM-Entsperrung prüfen und neu einrichten
fedora-update --dry-run      # Testlauf, verändert nichts
```

## Ablauf

1. **TPM-Entsperrung** – prüft bei TPM-gebundenen LUKS-Geräten, ob das TPM den
   Schlüssel noch freigibt, und richtet die Bindung bei Bedarf neu ein
   (siehe unten)
2. **Systempakete** – `sudo dnf upgrade --refresh`, im automatischen Modus
   zusätzlich `dnf autoremove`
3. **Flatpaks** – zuerst werden anstehende Aktualisierungen angezeigt und
   bestätigt, danach läuft `flatpak update -y --noninteractive`. Auf Wunsch
   werden zusätzlich ungenutzte Runtimes entfernt (die belegen sonst über die
   Zeit mehrere Gigabyte)
4. **Firmware** – `fwupdmgr refresh` und `fwupdmgr update` mit eigener
   Rückfrage, samt Warnung wenn kein Netzteil angeschlossen ist. Bei
   TPM-gebundenen LUKS-Geräten ohne Passphrase oder Recovery-Key wird das
   Update blockiert
5. **Discover** – Notifier beenden, Caches unter `~/.cache/discover`,
   `~/.cache/appstream` und `~/.cache/flatpak/system-cache` leeren,
   AppStream-Metadaten neu aufbauen, Notifier abgekoppelt neu starten

Zum Schluss folgen eine Zusammenfassung pro Kanal und ein Hinweis, falls ein
Neustart nötig ist.

## TPM2 und LUKS

Wer die LUKS-Verschlüsselung mit `systemd-cryptenroll` an das TPM gebunden hat
(typischerweise an PCR 7, den Secure-Boot-Zustand), kennt das Problem: Nach
einem Firmware- oder UEFI-dbx-Update über fwupd ändert sich PCR 7, das TPM gibt
den Schlüssel nicht mehr frei und beim Start wird wieder die Passphrase
verlangt. Die Daten sind dabei sicher – nur die TPM-Bindung passt nicht mehr.

Das Script kümmert sich darum in drei Schritten:

- **Vor dem Firmware-Update** prüft es, ob neben dem TPM noch eine Passphrase
  oder ein Recovery-Key eingerichtet ist. Fehlt beides, wird das
  Firmware-Update blockiert, weil das System sonst unzugänglich werden könnte.
- **Nach dem Neustart** gibst du einmalig die Passphrase ein.
- **Beim nächsten Lauf** (oder gezielt mit `fedora-update --tpm-check`) testet
  das Script mit `cryptsetup --test-passphrase --token-only`, ob das TPM den
  Schlüssel wieder freigibt. Wenn nicht, richtet es die Bindung mit
  `systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7` gegen
  die neuen PCR-Werte neu ein. Dafür wird die Passphrase einmal abgefragt; der
  alte TPM-Slot wird erst nach erfolgreicher Neuanmeldung entfernt.

Andere PCRs lassen sich über eine Umgebungsvariable festlegen, zum Beispiel
`FEDORA_UPDATE_TPM_PCRS=7+14 fedora-update --tpm-check`. TPM-Bindungen mit PIN
werden erkannt, aber nicht automatisch getestet.

Einen Recovery-Key legst du bei Bedarf so an und bewahrst ihn sicher auf:

```bash
sudo systemd-cryptenroll --recovery-key /dev/nvme0n1p3
```

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

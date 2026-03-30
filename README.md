# Tottis Arsch Tracker

Trackt automatisch wie lange du an Kunstwerken in **Clip Studio Paint** arbeitest.

## Download & Installation

### macOS

1. Gehe zu [**Releases**](https://github.com/Paulomat2025/TottisArschTracker/releases/latest)
2. Lade `TottisArschTracker-macOS.dmg` herunter
3. Doppelklick auf die `.dmg` Datei
4. `TottisArschTracker.app` in den **Programme**-Ordner ziehen
5. Beim ersten Start: Rechtsklick > "Öffnen" (Gatekeeper-Warnung bestätigen)

**Wichtig:** Die App braucht die Berechtigung **Bildschirmaufnahme** (Systemeinstellungen > Datenschutz & Sicherheit > Bildschirmaufnahme), um den Fenstertitel von Clip Studio Paint zu lesen.

### Windows

1. Gehe zu [**Releases**](https://github.com/Paulomat2025/TottisArschTracker/releases/latest)
2. Lade `TottisArschTracker-Windows.zip` herunter
3. ZIP entpacken in einen Ordner deiner Wahl (z.B. `C:\Programme\TottisArschTracker`)
4. `ArtTimeTracker.Windows.exe` starten
5. Optional: Rechtsklick auf die `.exe` > "An Taskleiste anheften" oder Desktop-Verknüpfung erstellen

**Keine Installation nötig** — einfach entpacken und starten.

## Updates

Die App prüft beim Start automatisch, ob eine neue Version verfügbar ist. Wenn ja, wirst du gefragt ob du das Update herunterladen möchtest.

Manuell: Einfach die [neueste Version](https://github.com/Paulomat2025/TottisArschTracker/releases/latest) herunterladen und die alte ersetzen. Deine Daten bleiben erhalten (die Datenbank liegt separat).

## Features

- **Auto-Tracking** — erkennt automatisch welche `.clip`-Datei in Clip Studio Paint geöffnet ist
- **Mehrere Kunstwerke** — arbeite an beliebig vielen Werken gleichzeitig
- **Session-Historie** — alle Sessions mit Datum, Start, Ende und Dauer
- **Statistiken** — Diagramme für Zeit pro Tag und Stunden pro Kunstwerk
- **Datei-Verknüpfung** — Dateien umbenennen und neu verknüpfen (wie InDesign Links)
- **Zusammenführen** — mehrere Kunstwerke zu einem verschmelzen
- **Manuelles Anlegen** — Kunstwerke auch ohne Datei-Verknüpfung erstellen

## Wo sind meine Daten?

Die SQLite-Datenbank wird automatisch angelegt:

| OS | Pfad |
|----|------|
| macOS | `~/Library/Application Support/ArtTimeTracker/arttimetracker.db` |
| Windows | `%LOCALAPPDATA%\ArtTimeTracker\arttimetracker.db` |

Du kannst die `.db`-Datei sichern/kopieren — sie enthält alle deine Tracking-Daten.
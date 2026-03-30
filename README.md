# 💩 Tottis Arsch Tracker

Trackt automatisch wie lange du an Kunstwerken in **Clip Studio Paint** arbeitest.

## Features

- **Auto-Tracking**: Erkennt automatisch welche .clip-Datei in Clip Studio Paint geöffnet ist
- **Mehrere Kunstwerke**: Arbeite an beliebig vielen Werken gleichzeitig
- **Session-Historie**: Alle Sessions werden mit Datum, Start, Ende und Dauer gespeichert
- **Statistiken**: Diagramme für Zeit pro Tag und Stunden pro Kunstwerk
- **Datei-Verknüpfung**: Dateien können umbenannt und neu verknüpft werden (wie InDesign Links)
- **Zusammenführen**: Mehrere Kunstwerke zu einem verschmelzen
- **Manuelles Anlegen**: Kunstwerke auch ohne Datei-Verknüpfung erstellen

## Installation

### macOS
1. [Neueste Version herunterladen](../../releases/latest) → `.dmg` Datei
2. Doppelklick → App in Programme ziehen
3. Fertig

### Windows
1. [Neueste Version herunterladen](../../releases/latest) → `.zip` Datei
2. Entpacken → `TottisArschTracker.exe` starten
3. Fertig (keine Installation nötig)

## Projektstruktur

```
core/       → Shared C# Library (Models, DB, Services, ProcessWatcher)
mac/        → Native macOS App (SwiftUI)
windows/    → Native Windows App (WPF)
```

## Entwicklung

### macOS App
```bash
cd mac
swift build
swift run
```

### Windows App (Cross-Compile von macOS)
```bash
dotnet build windows
dotnet run --project windows
```

### Release bauen
```bash
# macOS
cd mac && swift build -c release

# Windows
dotnet publish windows -c Release -r win-x64 --self-contained -p:PublishSingleFile=true
```

## Datenbank

SQLite-Datei wird automatisch angelegt unter:
- **macOS**: `~/Library/Application Support/ArtTimeTracker/arttimetracker.db`
- **Windows**: `%LOCALAPPDATA%\ArtTimeTracker\arttimetracker.db`

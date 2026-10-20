# Eine neue Strecke erstellen

Die Strecke besteht aus einer JSON-Datei. Das Spiel liest diese Datei beim Start. Die Datei enthält den Namen, die Landschaft, die Länge, die Kurven, die Höhen und die Sprünge. Du brauchst keinen Programmcode zu ändern.

1. Kopiere `templates/strecke.json` in diesen Ordner.
2. Gib der Kopie einen eigenen Namen, zum Beispiel `04_bergfahrt.json`.
3. Ändere den Namen und die Beschreibung in der Datei.
4. Ändere die Kurven, die Höhen und die Sprünge.
5. Öffne `tools/macos/Strecken prüfen.command` im Projektordner mit einem Doppelklick.
6. Behebe die gemeldeten Fehler.
7. Starte das Spiel. Die neue Strecke erscheint in der Auswahl.

Die Zahl im Dateinamen bestimmt die Reihenfolge im Menü. Die Vorlage selbst erscheint nicht im Menü. Die Auswahl nennt ungültige Dateien und ihre Fehler. Gültige Strecken bleiben spielbar. Bei einem JSON-Fehler nennt die Meldung auch die Zeile. Wenn keine gültige Datei übrig bleibt, zeigt die Auswahl einen Hinweis.

Zum Entfernen verschiebst du die JSON-Datei aus diesem Ordner. Du kannst sie auch löschen. Starte das Spiel danach neu. Auch die mitgelieferten Strecken kannst du entfernen. Das Spiel braucht keinen bestimmten Dateinamen.

JSON ist ein Textformat mit festen Schreibregeln. Nutze einen Texteditor. Setze Texte in doppelte Anführungszeichen. Trenne Einträge mit Kommas. Hinter dem letzten Eintrag steht kein Komma. Kommentare sind in JSON nicht erlaubt.

## Die Werte

Alle Entfernungen beziehen sich auf den Fortschritt entlang der Strecke. Sie gelten in Metern. Die Breite beträgt sechs Meter. Höhen gelten über dem gemeinsamen Nullpunkt. Der Boden liegt drei Meter unter diesem Nullpunkt.

| Feld | Bedeutung |
|---|---|
| `format_version` | Die Version des Formats; aktuell `1`. Alte Dateien ohne dieses Feld gelten als Version 1. |
| `scenario` | Die Landschaft: `forest`, `alpine`, `canyon` oder `coast`. Ohne dieses Feld nutzt das Spiel den Wald. |
| `preview` | Optional: ein Bildpfad relativ zu diesem Ordner, etwa `previews/meine-strecke.png`. Ohne Bild nutzt das Spiel eine Landschaftsvorschau. |
| `name` | Der Name im Spiel |
| `description` | Eine kurze Beschreibung für die Auswahl |
| `length_m` | Die Länge; 200 bis 10000 ganze Meter |
| `curves` | Die Liste der Kurven in Fahrtrichtung |
| `heights` | Die Liste der Höhenpunkte in Fahrtrichtung |
| `jumps` | Die Liste der Sprünge in Fahrtrichtung; `[]` erlaubt eine Strecke ohne Sprung |

## Die Landschaft und das Vorschaubild

| Wert für `scenario` | Landschaft |
|---|---|
| `forest` | Nebelwald mit Tannen und Felsen |
| `alpine` | Alpenpass mit Schnee und Bergen |
| `canyon` | Felsenschlucht mit Sandstein und Felstürmen |
| `coast` | Regenküste mit Meer, Felsen und einem Leuchtturm |

Die Landschaft verändert das Aussehen. Sie verändert keine Fahrbefehle. Schnee und Regen folgen dem Auto.

Ein eigener Name steht im Feld `name`. Der Dateiname bestimmt die Reihenfolge in der Auswahl. Ein kurzer Name passt besser in die Liste.

Für ein eigenes Bild legst du eine PNG-, JPG- oder WebP-Datei unter `tracks/previews` ab. Trage den Pfad im Feld `preview` ein. Ein Bild im Querformat passt am besten. Nimm es direkt von deiner Strecke auf. Wenn du die Vorlage kopierst, brauchst du zunächst kein Bild.

Falls das Bild fehlt, bleibt die Strecke spielbar. Das Spiel zeigt eine Landschaftsvorschau und eine Meldung. Eine Landschaftsvorschau zeigt das Szenario. Sie zeigt nicht zwingend den Verlauf deiner Strecke.

Die vier mitgelieferten Bilder unter `previews` zeigen die tatsächlichen Strecken. Die Küstenfahrt nutzt den Verlauf der Ersten Fahrt mit einer anderen Landschaft.

## Die Kurven, Höhen und Sprünge

Jede Kurve enthält diese Werte:

| Feld | Bedeutung |
|---|---|
| `start_m`, `end_m` | Der Anfang und das Ende der Kurve |
| `turn_sign` | `-1` für links; `1` für rechts |
| `radius` | Der Kurvenradius; mindestens 20 Meter |
| `bank_degrees` | Die Neigung der Steilkurve; 0 bis 45 Grad. Ohne diesen Wert bleibt die Fahrbahn quer eben. |
| `checkpoint_m` | Der Startpunkt nach einem Fall |

Die Außenseite einer Steilkurve liegt höher. Das Spiel baut die Neigung am Anfang auf und nimmt sie am Ende zurück. Die Vorlage zeigt verschiedene Neigungen.

Lass mindestens 40 Meter zwischen Kurven. Der Startpunkt nach einem Fall muss hinter der vorherigen Kurve liegen. Lass mindestens 25 Meter bis zur nächsten Kurve. Für Sprache sind längere Geraden besser. Die Kurve muss länger als 24 Meter sein. Lass mindestens 20 Meter bis zum Ziel.

Jeder Höhenpunkt enthält `at_m` und `height_m`. Der erste Punkt liegt bei 0 Metern. Der letzte Punkt liegt am Ziel. Die Höhe muss zwischen 5 und 100 Metern liegen. Das Spiel verbindet die Punkte mit weichen Übergängen. Vermeide große Höhenunterschiede auf kurzen Abschnitten.

Jeder Sprung enthält `start_m`, `end_m` und `height_m`. Zwischen Anfang und Ende fehlt die Fahrbahn. Die Sprunglänge beträgt 15 bis 50 Meter. `height_m` bestimmt die zusätzliche Höhe des Flugbogens. Nutze Werte zwischen 2 und 12 Metern.

Lass vor einem Sprung mindestens 60 Meter ohne Kurve. Lass danach mindestens 90 Meter ohne Kurve. Zwischen Sprüngen müssen mindestens 60 Meter liegen. Nach dem letzten Sprung braucht die Strecke mindestens 60 Meter bis zum Ziel.

Der Flug folgt einem vorgegebenen Bogen. Dadurch erreicht das Auto die Landung bei jedem erlaubten Tempo. Die Richtung bleibt wirksam. Eine passende Korrektur richtet das Auto aus. Die Hilfe endet nach der Landung. Sie übernimmt keine spätere Kurve.

Die Dateiprüfung erkennt fehlende Felder, ungültige Zahlen, unbekannte Landschaften und fehlende Abstände. Sie meldet auch unbekannte Felder auf der obersten Ebene. Die Prüfung kontrolliert weder das Spielgefühl noch alle möglichen Baufehler. Sie erkennt keine Kreuzungen der Fahrbahn. Prüfe die Strecke deshalb auch im Spiel. Große Änderungen brauchen einen Fahrtest mit Sprache und mit zwei Tasten.

## Die Strecke prüfen

Für die Dateiprüfung genügt der Doppelklick auf `tools/macos/Strecken prüfen.command`. Das Fenster zeigt jede gültige Datei und alle Meldungen.

Die gleiche Prüfung im Projektordner:

```sh
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/check_tracks.gd
```

Zusätzliche Fahrtests im Projektordner:

```sh
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/run_track_tests.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/run_jump_scene_tests.gd
```

Die erste Prüfung liest alle Streckendateien. Sie prüft Fahrten mit 50, 79 und 101 km/h. Sie prüft auch Korrekturen vor dem Sprung und kurz vor der Landung. Die zweite Prüfung fährt die Strecken mit dem sichtbaren Fahrzeugmodell ab. Sie prüft zusätzlich 166 km/h mit kurzen Korrekturen in den Kurven.

Diese Prüfungen ersetzen keinen Spieltest. Prüfe besonders die Sicht auf die Landung und die Zeit bis zur nächsten Kurve.

## Speed hints for lower assist levels

Each curve and jump can contain a `speed_hint` object. Old tracks without it remain valid.

```json
"speed_hint": {
  "version": 1,
  "min_mps": 0,
  "max_mps": 58,
  "target_mps": 28,
  "status": "assisted_tested",
  "model": "lower_assist_v1"
}
```

All values use metres per second. `null` means that no tested bound is available.
The fields describe the element at its existing `start_m` and `end_m` positions.
`status` is `unverified`, `assisted_tested`, or `verified`. `model` identifies the rules used for the test.
The two lower levels use a confirmed `max_mps` for `lower_assist_v1` after a valid curve input.
The limit changes the help target. It preserves the player's target.
`target_mps` is an authored target, not a measured physical limit. `min_mps` reserves a future lower bound.
The current curve values describe tested help up to the game's speed limit. They do not describe unassisted tyre grip.

Current ramps use `position_based_v1`, `unverified`, and null speed values.
Do not enter a physical minimum for this model. The fixed flight path does not test it.
Future speed-dependent jumps need a new model and repeatable flight tests before they can use speed bounds.
The reader rejects negative values, non-finite values, reversed bounds, and targets outside the bounds.

## Räumliche Strecken mit Format 2

`06_stuntlabor.json` enthält die erste räumliche Strecke.
Ihre Elemente verwenden die gespeicherten Fahrformen aus `forms/stunt_v1.json`.
`entry_transform` setzt Lage und Drehung jedes Elements.
Die Drehung verwendet vier Werte: x, y, z und w eines Einheitsquaternions.
Ein Quaternion beschreibt hier die räumliche Ausrichtung ohne feste Oberseite.

`assist` enthält Mindesttempo, Höchsttempo, Zieltempo und Anfahrabstand.
Ein leeres Feld verwendet die Vorgaben aus `stunt_assist.gd`.
Diese Werte steuern die Hilfe. Sie beweisen keinen sicheren Bereich für beliebige Fahrzustände.
`landings` nennt die erlaubten Landeflächen sowie die Grenzen für Winkel und Aufpralltempo.
Die Fahrfläche liefert die tatsächliche Breite und Länge.

`styles.road` und `styles.scenery` wählen die Darstellung getrennt.
`report` nennt den Fahrbericht. Eine passende erfolgreiche Fahrt ist für beide Hilfestufen nötig.
Nach Änderungen an Fahrdaten oder Fahrberechnung erzeugt `tools/spatial/check_drives.gd` einen neuen Bericht.
Ein reiner Modelltausch braucht nur eine neue Modellprüfung.
Die vier alten Strecken verwenden weiterhin Format 1.

## Format 3: circuits from pieces

New tracks use format 3. A file lists a start height and a chain of pieces with parameters. The game builds the road, the pillars and the drive surface from them. Every format 3 track is a closed circuit: the last piece must end exactly where the first one starts.

`08_stunt_circuit.json` is the first example. The piece types, their parameters and limits are in [the plan](../docs/track-pieces-plan.md).

1. Write the pieces into a new JSON file with `"format_version": 3`.
2. Run `tools/check_tracks.gd`. An open circuit reports how far its end misses the start.
3. Write the drive report: `Godot --headless --path . --script tools/spatial/check_drives.gd -- --track res://tracks/<file>.json --output res://tracks/reports/<file>.json`.
4. Set `"report"` to that report. The menu only offers a track whose report matches the current file and code.

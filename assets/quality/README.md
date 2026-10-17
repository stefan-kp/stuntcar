# Kostenlose Modelle im Spiel

Dieser Ordner enthält die Quelldateien aus der Godot-Qualitätsprobe.
Das Spiel nutzt sie unabhängig vom separaten Projekt `quality_probe`.
Alle verwendeten Quelldateien kosten nichts.

## Auto

Quelle: [Car Concept, Khronos glTF Sample Assets](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/CarConcept).

Urheber: Eric Chadwick, Darmstadt Graphics Group GmbH, 2024.
Lizenz: [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/).
Das Modell basiert auf einem CC0-Entwurf von Unity Fan.
Die vollständigen Angaben stehen in `car/SOURCE.md`.
Der Lizenztext liegt in `car/CC-BY-4.0.txt`.
Die Angaben zu den ursprünglichen Khronos-Zeichen stehen in `car/KHRONOS-MARKS.txt`.

Änderungen im Spiel:

- Der Lack erhält eine orange Farbe, feine Metalldetails und eine klare Glanzschicht.
- Die Karosserie und das Dach tragen eine erzeugte Lackgrafik mit dunklen Rennstreifen und silbernen Akzenten.
- Die Grafik folgt gemeinsamen Bildkoordinaten über die einzelnen Karosserieteile hinweg.
- Die Scheiben erhalten eine angepasste Transparenz.
- Das Nummernschild erhält eine neutrale Oberfläche.
- Die Reifen und die Felgen erhalten angepasste Oberflächen.
- Das Spiel stellt die feinen Oberflächendetails für den Lack und das Reifenprofil wieder her.
- Es ergänzt die beim Import fehlende Größe der Texturmuster ausdrücklich.
- Die Felgen nutzen die kostenlose Metalltextur „Metal 032“ von ambientCG.
- Die übrigen zusätzlichen Normalenbilder und die mitgelieferte Abschattung bleiben deaktiviert.
- Godot berechnet die räumliche Abschattung in der Szene.
- Die Vorderräder stehen zu Beginn gerade.
- Vier zusätzliche Drehpunkte verbinden die Räder mit der vorhandenen Fahrbewegung.

Die ursprünglichen Modelldateien bleiben erhalten. Das Spiel ändert die Oberflächen beim Laden.

Die Felgentextur stammt von [Metal 032, ambientCG](https://ambientcg.com/view?id=Metal032).
Sie nutzt [CC0 1.0](https://docs.ambientcg.com/license/) und kostet nichts.
Das Spiel verwendet die Farbe, die Oberflächenstruktur und die Rauheit mit 2048 × 2048 Bildpunkten.
`car/metal/source.json` enthält die Downloadquelle und die Prüfsummen.
`tests/capture_car_materials.gd` zeigt das Auto mit dem Licht der Spielszene aus zwei Blickwinkeln.

Die Lackgrafik liegt in `car/livery/orange-stripes.png`.
Das integrierte Werkzeug zur Bildgenerierung erzeugte sie am 17. Oktober 2026.
`car/livery/prompt.txt` enthält die vollständige Beschreibung für die Bildgenerierung.
Die Grafik enthält nur die Farben. Das Spiel berechnet die Spiegelungen und die Glanzschicht.
Die ursprünglichen Dateien des Autos bleiben unverändert.

## Natur und Oberflächen

Diese Quellen verwenden [CC0](https://polyhaven.com/license):

| Quelle | Urheber |
|---|---|
| [Pine Sapling Small](https://polyhaven.com/a/pine_sapling_small) | Rob Tuytel und Rico Cilliers |
| [Asphalt Track](https://polyhaven.com/a/asphalt_track) | Dimitrios Savva |
| [Forest Floor](https://polyhaven.com/a/forest_floor) | eye-candy.xyz |
| [Kloofendal 48d Partly Cloudy](https://polyhaven.com/a/kloofendal_48d_partly_cloudy) | Greg Zaal |

Das Spiel verändert die Größe und die Drehung der Kiefern.
Die großen Kiefern sind vergrößerte Jungbäume.
Die Alpen nutzen jetzt die Tannen aus `assets/forest` mit einer Schneeschicht.
Die neuen Landschaften beschreibt `assets/landscapes/README.md`.
Der Waldboden erhält eine dunklere Farbe.
Der Asphalt folgt den Kurven, den Kuppen und den Steilkurven.

Die Datei `manifest.json` nennt die Downloadquellen und die Prüfsummen der Originaldateien.
Die Pfade in dieser Datei gelten relativ zu diesem Ordner.
Die Dateien `*-source.json` enthalten die Angaben von Poly Haven.

## Verwendung

Die Datei `scripts/quality_assets.gd` im Projekt erstellt die Modelle und Materialien für das Spiel.
Die Importdateien aktivieren kleinere Texturstufen für entfernte Oberflächen.
Die Kiefern verwenden die von Godot erzeugten vereinfachten Modelle für größere Entfernungen.
Das Spiel blendet weit entfernte Kiefern aus.

Das neue Auto erscheint auf allen vier Strecken.
Der Canyon und die Küste behalten ihre bisherigen Landschaftsmodelle.
Die vollständige Landschaft erreicht noch nicht die Qualität eines fertigen AAA-Rennspiels.

## Prüfung am 15. Oktober 2026

Die Spieltests meldeten 192 Prüfungen ohne Fehler.
Sie prüften die Landschaften, die Sprünge, die Steilkurven, die Tasten und die Streckenauswahl.
Eine zusätzliche Codeprüfung fand keinen wichtigen Fehler.

Eine kurze Messung nutzte den Apple M4 Pro bei 1280 × 800 Bildpunkten:

| Landschaft | Durchschnittliche Bilder pro Sekunde |
|---|---:|
| Wald | 90 |
| Alpen | 107 |
| Canyon | 147 |
| Küste | 147 |

Die Messung umfasst jeweils die erste Kurve. Sie garantiert keine Bildrate für jede Stelle der Strecke.
Die genauen Werte stehen in `docs/qualitaet-bildzeiten.json` im Projekt.

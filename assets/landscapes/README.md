# Wüste und Schneelandschaft

Das Spiel nutzt diese kostenlosen Quellen von Poly Haven.
Alle neuen Modelle und Oberflächen verwenden [CC0 1.0](https://polyhaven.com/license).
Die Prüfung der Lizenz erfolgte am 15. Oktober 2026.

| Quelle | Urheber |
|---|---|
| [Kloofendal 48d Partly Cloudy (Pure Sky)](https://polyhaven.com/a/kloofendal_48d_partly_cloudy_puresky) | Greg Zaal, Jarod Guest |
| [Namaqualand Boulder 02](https://polyhaven.com/a/namaqualand_boulder_02) | Greg Zaal, Rico Cilliers |
| [Namaqualand Boulder 03](https://polyhaven.com/a/namaqualand_boulder_03) | Jenelle van Heerden, Dario Barresi |
| [Quiver Tree 01](https://polyhaven.com/a/quiver_tree_01) | James Ray Cock, Dario Barresi, Rico Cilliers |
| [Rock 07](https://polyhaven.com/a/rock_07) | Jenelle van Heerden |
| [Sand 01](https://polyhaven.com/a/sand_01) | Rob Tuytel |
| [Shrub 02](https://polyhaven.com/a/shrub_02) | Rico Cilliers |
| [Snow 02](https://polyhaven.com/a/snow_02) | Rob Tuytel |

Die Wüste nutzt Sand, zwei Felsformen, Köcherbäume und niedrige Sträucher.
Das Spiel gibt den Sträuchern eine trockene Farbe.
Die Schneelandschaft nutzt Schnee, Felsen und die Tannen aus `assets/forest`.
Eine zusätzliche Oberfläche legt Schnee auf die Felsen und die Äste.
Beide Landschaften nutzen einen CC0-Himmel ohne Boden oder Bäume.
Die Fahrbahn und das Auto behalten ihre bisherigen Quellen und Lizenzen.

## Gelände

Das Spiel berechnet die Dünen und die Berge aus festen Zufallswerten.
Die Schneelandschaft enthält einzelne Gipfel mit breiten Hängen.
Die Oberflächen wechseln an steilen Hängen von Sand oder Schnee zu Fels.
Die Oberflächenbilder besitzen 2048 × 2048 Bildpunkte.
Die Modelle verwenden Bilder mit 1024 × 1024 Bildpunkten.
Der Boden fängt das Auto bei einem Fall auf.
Die Modelle halten Abstand zur gesamten Strecke, auch zu benachbarten Kurven.

## Quellen und Aufbereitung

`manifest.json` enthält die Downloadadressen, Größen und Prüfsummen der Quelldateien.
Die Dateien `*-source.json` enthalten die Angaben von Poly Haven.
`prepared/details.json` nennt die Anzahl der Dreiecke vor und nach der Aufbereitung.
Blender reduziert große Felsen auf etwa 7000 Dreiecke.
Der Köcherbaum enthält nach der Aufbereitung etwa 24000 Dreiecke.
Godot erzeugt weitere Detailstufen für größere Abstände.
Die Tannen verwenden die beiden vorhandenen Detailstufen des Waldes.

`tools/landscapes/fetch_sources.py` lädt die Quellen erneut.
`tools/landscapes/prepare_models.py` bereitet die Modelle mit Blender 4.5.1 auf.
Der erneute Download braucht eine Internetverbindung.
Das Spiel braucht keine Internetverbindung.

## Prüfung

`tests/run_biome_tests.gd` prüft den festen Boden und die freien Fahrbahnen.
`tests/run_landscape_tests.gd` prüft auch den Landschaftswechsel und das Wetter.
`tests/run_biome_fall_tests.gd` prüft einen echten Sturz und den Neustart in beiden Landschaften.
`tests/measure_biomes.gd` misst die Bildrate an zwölf Positionen je Strecke.
`tests/capture_biomes.gd` erstellt vier Spielbilder je Landschaft.
Das Programm aktualisiert auch die Vorschaubilder der beiden Strecken.

## Prüfergebnis vom 15. Oktober 2026

Die neun Prüfprogramme enthalten insgesamt 320 erfolgreiche Prüfungen.
Sie prüfen die Landschaften, die Modelle, die Strecken, die Auswahl und die Spielregeln.
Dazu kommen erfolgreiche Sturztests für Wald, Wüste und Schneelandschaft.
Die Tests bestätigen den Neustart und prüfen, dass das Auto den Boden nicht durchquert.
Die Prüfung der Strauchmodelle vergleicht die Form mit den gedrehten Originalmodellen.
Alle 35 heruntergeladenen Quelldateien stimmen mit den gespeicherten Prüfsummen überein.

Die Messwerte stehen in `docs/landschaften-bildzeiten.json`.
Die Messung verwendet zwölf Positionen je Strecke und 1280 × 800 Bildpunkte.
Sie misst den Apple M4 Pro mit dem Renderer Forward+.
Sie prüft keine anderen Geräte und keine besonders langen eigenen Strecken.
Die Tests melden eine vorhandene Exportwarnung zur Vorschauanzeige.
Diese Prüfung umfasst keinen Spieleexport.

## Zusätzlicher Schluchtabschnitt

Die Strecke „Canyon Study“ enthält 200 Meter mit neuen Felswänden, einem Tafelberg und einem befahrbaren Felsbogen.
Die Formen entstehen im Projekt mit Blender.
Die Oberfläche [Rock Face 03](https://polyhaven.com/a/rock_face_03) stammt von Dario Barresi und Rico Cilliers über Poly Haven.
Die Oberfläche nutzt CC0 1.0.
Die [Beschreibung](canyon/README.md) nennt die Dateien und die Prüfungen.
Die Datei `canyon/sources.json` enthält die Prüfsummen der Oberflächenbilder.
Der Abschnitt nutzt außerdem [Sandy Gravel 02](https://polyhaven.com/a/sandy_gravel_02) von Dario Barresi.
Die fotografierten Felsmodelle stammen von [Rock Face 02](https://polyhaven.com/a/rock_face_02) von Dario Barresi und Rico Cilliers.
Der Himmel stammt von [Rogland Sunset](https://polyhaven.com/a/rogland_sunset) von Greg Zaal.
Alle drei Quellen verwenden ebenfalls CC0 1.0.

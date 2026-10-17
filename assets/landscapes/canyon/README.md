# Felsschlucht: 200 Meter

Die Strecke „Canyon Study“ zeigt drei Felswandformen, einen Tafelberg und einen Felsbogen.
Die Strecke enthält eine breite Rechtskurve und keine Sprünge.
Der Felsbogen steht bei Meter 148.
Die neue Landschaft erscheint nur auf dieser Teststrecke.

## Quellen

Die Oberfläche stammt von [Rock Face 03](https://polyhaven.com/a/rock_face_03), Poly Haven.
Die Urheber sind Dario Barresi und Rico Cilliers.
Die Oberfläche nutzt CC0 1.0 und eine Auflösung von 4096 × 4096 Bildpunkten.
`sources.json` enthält die Prüfsummen und Dateigrößen.
Der Kies stammt von [Sandy Gravel 02](https://polyhaven.com/a/sandy_gravel_02), Dario Barresi.
Die Kiesoberfläche besitzt ebenfalls 4096 × 4096 Bildpunkte.
Die fotografierten Felsmodelle stammen von [Rock Face 02](https://polyhaven.com/a/rock_face_02), Dario Barresi und Rico Cilliers.
Diese Modelle nutzen Oberflächen mit 2048 × 2048 Bildpunkten.
Der Himmel stammt von [Rogland Sunset](https://polyhaven.com/a/rogland_sunset), Greg Zaal.
Alle drei Quellen verwenden CC0 1.0.
Die Dateien `gravel/source.json`, `sky/source.json` und `rock_face_02-source.json` enthalten die Quellen und Prüfsummen.
Die vorhandenen weiteren Felsen und Pflanzen behalten ihre bisherigen Quellen.

Die fünf neuen Formen entstehen im Projekt mit Blender.
Die Felswände und der Tafelberg besitzen ungleich verteilte tiefe Spalten und gebrochene Oberkanten.
Der Felsbogen besitzt kantigere Flächen und einzelne Ausbrüche an verschiedenen Seiten.
Diese Vertiefungen gehören zur Form; die vorhandenen Texturen bleiben unverändert.
`tools/canyon/build_models.py` erzeugt die Formen.
`tools/canyon/source/canyon_models.blend` enthält die bearbeitbaren Modelle.
Die GLB-Dateien enthalten die Form und die Bildkoordinaten.
Godot ergänzt das gemeinsame Felsmaterial mit waagerechten Farbschichten.
Die Blender-Quelldatei zeigt eine einfachere Vorschau dieses Materials.

## Darstellung

Die Teststrecke verwendet einen Schotterrand mit festem Boden.
Schmale Straßenmarkierungen und kleine Straßenschilder ersetzen die breiten Randstreifen und die großen Schilder.
Fotografierte Felsmodelle ergänzen die großen Felswände.
Die Felsoberflächen mischen versetzte Bildausschnitte, damit sich gleiche Muster weniger wiederholen.
Das Licht erzeugt lange Schatten und räumlichen Dunst.
Eine örtliche Spiegelung zeigt die Schlucht auf dem Autolack.
Staub bewegt sich mit dem Wind.
Die vorhandenen Effekte erzeugen weiterhin Reifenrauch beim Bremsen und Driften.
Die kleinen Steine verwenden zwei vereinfachte Modelle mit je 800 Dreiecken.

`tools/canyon/fetch_materials.py` lädt die Oberflächen und den Himmel erneut.
`tools/canyon/prepare_scree.py` erzeugt die vereinfachten Steine aus den vorhandenen Felsmodellen.
Das Felsmodell `rock_face_02.glb` stammt aus dem Blender-MCP-Import von Poly Haven.

## Prüfung

`tests/run_canyon_study_tests.gd` prüft die Fahrbahn, den Raum für die Fahrkamera und die Fahrt bis zum Ziel.
`tests/capture_canyon_study.gd` erstellt sechs Ansichten aus der Fahrkamera.
Der zusätzliche Parameter `-- --play` öffnet die Teststrecke im Spielmenü.
`tests/capture_canyon_drive.gd` fährt automatisch bis zum Ziel und misst die Bildzeiten.
`docs/canyon-study-performance.json` enthält die Messung ohne Filmaufnahme.
Die Messung gilt für 1280 × 800 Bildpunkte auf dem Apple M4 Pro.

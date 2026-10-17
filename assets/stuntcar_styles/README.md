# Austauschbare Streckendarstellungen

`neutral` und `contrast` verwenden dieselben neun gespeicherten Fahrformen.
Die Szenen übernehmen die vorhandenen Modelle aus `assets/stuntcar_kit`.
Neue Blender-Modelle sind dafür nicht nötig.

`catalog.json` ordnet jeder Form eine sichtbare Szene und deren Fahrflächen zu.
Die Umgebung besitzt eigene Einträge unter `scenery`.
Fahrbahn und Umgebung können verschiedene Stile verwenden.

Die Anleitung steht in `docs/blender-streckenmodelle.md`.
Die Prüfungen stehen in `tests/spatial/test_models.gd` und `test_model_swap.gd`.

# Streckenmodelle aus Blender austauschen

Die Fahrform und das sichtbare Modell sind getrennt. Ein Modelltausch verändert keine Fahrwerte.
Die laufende Blender-Arbeit gehört nicht zu dieser Änderung.

## Eine Fahrbahn ersetzen

1. Exportiere das Modell später als GLB in einen neuen Ordner unter `assets/stuntcar_styles`.
2. Verwende Meter als Einheit.
3. Wende die Skalierung vor dem Export an.
4. Verwende eine unveränderte Wurzel mit Skalierung 1 und ohne Drehung.
5. Übernimm die vorhandenen Anschlüsse `Entry` und `Exit`.
6. Verwende deren Lage und Drehung aus `tracks/forms/stunt_v1.json`.
7. Behalte die Namen der sichtbaren Fahrflächen bei.
8. Öffne das Projekt in Godot, damit Godot die GLB-Datei importiert.
9. Trage den importierten Szenenpfad in `assets/stuntcar_styles/catalog.json` ein.
10. Trage dort die Fahrflächen unter `surface_meshes` ein.
11. Behalte `form_id` und `form_version` bei, solange sich die Fahrform nicht verändert.
12. Führe `tests/spatial/test_models.gd` und `tests/spatial/test_model_swap.gd` aus.

Ein Eintrag hat etwa diese Werte:

```json
{
  "form_id": "straight_24",
  "form_version": 1,
  "scene_path": "res://assets/stuntcar_styles/mein_stil/straight_24.glb",
  "surface_meshes": ["Road"]
}
```

Der Schlüssel besteht aus dem Stil und der Form, zum Beispiel `mein_stil/straight_24`.
Die Strecke wählt den Stil über `styles.road`.

Die Anschlussprüfung erlaubt 1 mm Abstand und 0,1 Grad Winkelabweichung.
Die Prüfung der Fahrfläche erlaubt 2 cm Abweichung.
Sie verwendet die Dreiecke der gespeicherten Fahrform.
Sie prüft beide Ränder und die Mitte in Abständen von höchstens 25 cm.
Zusätzliche Prüfstellen liegen an den gespeicherten Formpunkten.
Gespiegelte Modelle gelten als ungültig.

Die Prüfung kontrolliert die gespeicherte Fahrform gegen die sichtbare Fläche.
Sie ersetzt keine Bildprüfung auf zusätzliche Dekoration über der Fahrbahn.
Prüfe deshalb die ganze Fahrt nach einem neuen Modellimport.

Godot entfernt mitgebrachte Kollisionsknoten aus der Darstellung.
Die gespeicherte Fahrform bestimmt weiterhin den Kontakt.
Ein fehlendes oder ungültiges Fahrbahnmodell erhält eine einfache Ersatzdarstellung.
Die Prüfung liefert dazu eine Fehlermeldung.

## Die Umgebung ersetzen

Die Strecke wählt die Umgebung getrennt über `styles.scenery`.
Der Abschnitt `scenery` im Modellkatalog enthält deren Szenenpfad.
`radius_m` und `height_m` begrenzen die Ausdehnung des Modells.
Die Wurzel bleibt unverändert. Die Unterkante liegt bei null.
Die vorhandenen Beispiele verwenden vier Meter Breite je Seite und sechs Meter Höhe.
Die Prüfung weist Modelle außerhalb dieser Grenzen zurück.
Die Aufstellung hält Abstand zur Fahrbahn.
Ein ungültiges Umgebungsmodell erscheint nicht.

## Eine Fahrform ändern

Eine andere Rampenform ist kein reiner Modelltausch.
Erhöhe dafür die Formversion. Aktualisiere die Fahrform und ihre Anschlüsse.
Prüfe die Strecke erneut. Erzeuge danach einen neuen Fahrbericht.
Der alte Bericht gilt nach einer Änderung der Fahrform oder Fahrberechnung nicht mehr.

## Zur vorherigen Darstellung zurückkehren

Bewahre die alte Modelldatei und ihren Katalogeintrag auf.
Stelle `scene_path` oder den gewählten Stil auf die alte Version zurück.
Führe die Modellprüfung erneut aus.
Bei unveränderten Fahrdaten bleibt der Fahrbericht gültig.

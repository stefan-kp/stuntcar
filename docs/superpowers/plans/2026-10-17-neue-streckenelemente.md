# Umsetzungsplan: Neue Streckenelemente mit sichtbaren Effekten

> **Für ausführende Agenten:** Verwende `superpowers:executing-plans` für die Umsetzung in dieser Unterhaltung. Verwende `superpowers:subagent-driven-development` nur nach Stefans Wahl. Bearbeite die Aufgaben einzeln. Die Kästchen erfassen den Fortschritt.

**Ziel:** Eine neue Teststrecke bietet glaubwürdige Sprünge und Loopings mit zwei unteren Hilfestufen, sichtbaren Effekten und austauschbaren Blender-Modellen.

**Aufbau:** Versionierte Fahrdaten bestimmen Verlauf, Kontakt und Bewegung. Ein getrenntes Modellverzeichnis bestimmt die Darstellung. Spiel und Fahrprüfung verwenden dieselbe Berechnung und dieselben Ereignisse.

**Technik:** Godot 4.5.1, GDScript, bestehende Physik-Engine, GLB für spätere Blender-Modelle, JSON für Daten und Berichte. Keine neue Bibliothek.

**Grundlage:** [Entwurf: Neue Streckenelemente und austauschbare Blender-Modelle](../specs/2026-10-17-neue-streckenelemente-design.md), einschließlich der bestätigten mittleren Physikstufe und der Effekte.

**Stand:** Der Plan liegt zur Prüfung vor. Die Umsetzung hat noch nicht begonnen. Die Kästchen melden keine bereits erledigte Entwicklungsarbeit.

## Verbindliche Grenzen

- „Sehr leicht“ und „Leicht“ bleiben die einzigen Stufen dieses Ausbaus.
- Die mittlere Physikstufe beschreibt den Umfang der Berechnung. Sie ist keine zusätzliche Hilfestufe im Spiel.
- Dateien mit `format_version: 1` behalten die bisherige Berechnung.
- Die neue Teststrecke verwendet `format_version: 2`.
- Spiel und Fahrprüfung verwenden denselben Bewegungsschritt mit 60 Schritten pro Sekunde.
- Eine Einheit entspricht einem Meter.
- Die erste Modellfamilie verwendet eine sechs Meter breite Fahrbahn.
- Die Anschlüsse heißen `Entry` und `Exit`.
- Anschlussfehler: höchstens 0,001 m und 0,1 Grad. Abweichung der sichtbaren Fahrfläche: höchstens 0,02 m an den Prüfstellen.
- Eine Kurveneingabe gilt höchstens für die zugeordnete Kurve. Sprünge und Loopings brauchen keinen neuen Befehl.
- Leise Rufe und erkannte Tempobefehle behalten die vorhandenen Regeln.
- Keine unsichtbare Zielkorrektur im Flug. Reifenbremsen wirken nur bei Bodenkontakt.
- Keine vollständige Reifensimulation, keine einzeln physikalisch berechneten Radaufhängungen und kein Wechsel zu Jolt oder PhysX.
- Ein ausgeschalteter Effekt verändert kein Fahrergebnis.
- Die Kamerabewegung bleibt ruhig. Der erste Ausbau ergänzt kein zufälliges Kamerazittern.
- Neue Spieltexte stehen in `locales/en.po`. Die Spieloberfläche bleibt englisch. Berichte für Stefan bleiben deutsch.
- Die Umsetzung verändert keine Modelle in der laufenden Blender-Sitzung.
- Fremde lokale Änderungen bleiben erhalten. Kein pauschales `git add .`. Kein Wechsel auf `main` und keine Veröffentlichung ohne Auftrag.

## Besondere Prüffälle

Diese fünf Fälle erhalten eigene Tests in den genannten Aufgaben:

1. Der Looping liegt nahe an seiner Einfahrt. Die Zuordnung darf den Fortschritt nicht auf einen falschen Abschnitt setzen. Aufgabe 2.
2. Ein importiertes Modell enthält eigene Flächen für Zusammenstöße oder falsche Anschlüsse. Es darf die Fahrt nicht verändern. Aufgabe 3.
3. Eine Landung liegt zwischen zwei Rechenschritten. Der Flug darf die Fläche nicht überspringen. Aufgabe 6.
4. Eine Pause oder Tonabschaltung liegt direkt vor einer Landung. Der nächste Bildaufbau darf keinen doppelten Ton auslösen. Aufgabe 11.
5. Ein alter Bericht liegt neben veränderten Fahrdaten. Die Anzeige darf dessen Tempoangaben nicht als gültig verwenden. Aufgabe 8.

## Ausgangsstand und Arbeitsweise

Der Plan bezieht sich auf den Branch `codex/neue-streckenelemente` nach dem Entwurfsstand `10b6c30`.
Andere lokale Dateien enthalten Arbeiten an Landschaften und Bildern.
Die Umsetzung prüft den aktuellen Stand vor dem ersten Eingriff erneut.
Sie verwendet den vorhandenen getrennten Arbeitsordner gemäß `superpowers:using-git-worktrees`.
Sie benötigt keinen weiteren Arbeitsordner und keinen Zugriff auf die laufende Blender-Sitzung.

Alle Dateipfade beziehen sich auf den Projektordner.
Die folgenden Programme liegen derzeit in der Hauptkopie. Die Umsetzung prüft ihre Verfügbarkeit.

```sh
export STUNTCAR_GODOT=/Users/stefan/Documents/railsapps/stuntcar/.tools/Godot.app/Contents/MacOS/Godot
export STUNTCAR_PYTHON=/Users/stefan/Documents/railsapps/stuntcar/.tools/voice-env/bin/python
```

Godot erhält immer `--path .` und eine Protokolldatei unter `/private/tmp`.
Szenentests verwenden eigene Einstellungen und künstliche Spracheingaben.
Sie verändern keine persönlichen Mikrofonprofile.
Die Umsetzung erzeugt benötigte UID-Dateien mit Godot.
Eine fehlende Testdatei oder ein Ladefehler gilt nicht als fachlich fehlschlagender Test.

Jede Aufgabe endet mit einem eigenen Commit der ausdrücklich genannten Dateien.
Ein fehlgeschlagener Ausgangstest erhält eine Ursachenprüfung vor weiteren Änderungen.
Der Ausbau bildet ein gemeinsames Teilprojekt: Verlauf, Fahrberechnung und Effekte hängen an denselben Schnittstellen.

## Dateiaufteilung

| Dateien | Verantwortung |
|---|---|
| Neu: `scripts/track/spatial/track_definition.gd`, `form_library.gd` | Format 2 prüfen und versionierte Formen laden. |
| Neu: `scripts/track/spatial/spatial_track.gd`, `surface_query.gd` | Räumlichen Verlauf und Kontakte abfragen. |
| Neu: `tracks/forms/stunt_v1.json` | Neun Formbeschreibungen aus dem vorhandenen Modellpaket. |
| Neu: `scripts/track/track_factory.gd` | Zwischen altem und neuem Streckenmodell wählen. |
| Vorhanden: `scripts/track/track_data.gd` | Den Katalog für beide Formate öffnen; die alte Bewegung unverändert lassen. |
| Neu: `scripts/track/visuals/model_catalog.gd`, `model_validator.gd`, `spatial_builder.gd` | Modelle auswählen, prüfen und entlang der Fahrdaten darstellen. |
| Neu: `assets/stuntcar_styles/catalog.json`, `neutral/`, `contrast/` | Zwei austauschbare Darstellungen derselben Formen. |
| Neu: `scripts/vehicle/spatial/drive_state.gd`, `surface_motion.gd`, `flight_motion.gd` | Gemeinsamen Zustand, Bodenkontakt und Flug berechnen. |
| Neu: `scripts/vehicle/spatial/stunt_assist.gd`, `profiles.json` | Begrenzte Hilfen für neue Elemente. |
| Neu: `scripts/vehicle/spatial_drive_model.gd`, `drive_model_factory.gd` | Das neue Fahrmodell an die vorhandene Eingabe und Anzeige anschließen. |
| Neu: `scripts/track/spatial/verification.gd`, `scripts/vehicle/spatial/drive_runner.gd` | Fahrberichte prüfen und Fahrten mit festgelegten Eingaben ausführen. |
| Neu: `scripts/vehicle/ride_feedback.gd`, `scripts/vehicle/tire_marks.gd` | Sichtbare Fahrzeugbewegung und begrenzte Reifenspuren. |
| Vorhanden: `scripts/main.gd`, `scripts/input/command_router.gd`, `scripts/ui/game_ui.gd` | Auswahl, Zustandswechsel, Eingabe und Hinweise verbinden. |
| Vorhanden: `scripts/vehicle/car_view.gd`, `stunt_effects.gd`, `scripts/audio/race_audio.gd`, `scripts/camera/follow_camera.gd` | Den neuen Zustand darstellen, vertonen und mit der Kamera verfolgen. |
| Neu: `tracks/06_stuntlabor.json`, `tracks/reports/06_stuntlabor.json` | Neue Strecke und belegte Fahrbereiche. Die Nummer 05 bleibt für die andere Streckenarbeit frei. |
| Neu: `tests/spatial/`, `tests/fixtures/spatial/`, `tools/spatial/` | Neue Prüfungen, kleine Prüfdaten und Prüfwerkzeuge. |

Die vorhandenen Landschaftsdateien bleiben im Zuständigkeitsbereich der parallelen Landschaftsarbeit.
Der neue Builder verwendet zuerst eigene einfache Landschaftsmodelle im Stilordner.
Die fertigen Landschaftsmodelle können später denselben Verzeichnisvertrag erfüllen.

## Feste Schnittstellen

Alle neuen GDScript-Dateien verwenden `preload` wie der bestehende Code. Globale Klassennamen sind nicht erforderlich.
Die folgenden Namen bezeichnen die jeweilige Datei, keine zusätzliche Bibliothek.

### Fahrdaten

`Frame` ist ein Dictionary mit `position: Vector3`, `basis: Basis`, `distance_m: float`, `element_id: String`, `local_m: float`.
Die Basis enthält rechts, oben und rückwärts als Spalten. Vorwärts entspricht `-basis.z`.
`Projection` ergänzt `Frame` um `lateral_m: float`, `normal_m: float`, `valid: bool`.

`TrackDefinition.validate(data: Dictionary, forms: Dictionary) -> Array[String]` liefert stabile Fehlercodes.
Ein Element enthält `id`, `kind`, `form_id`, `form_version`, `entry_transform`, `input`, `assist` und `visual_id`.
`entry_transform` speichert Position und Quaternion als Zahlenfelder. Skalierung ist nicht erlaubt.
`input` enthält `kind: none|turn`, `direction: -1|1` nur bei Kurven und `checkpoint_m`.
`landings` verbindet `launch_id` mit `target_ids`, `max_angle_degrees` und `max_impact_mps`.
Die erste Landerampe besitzt eine eigene Lage hinter der Lücke. Dort verlangt die Anschlussprüfung keinen direkten Kontakt mit der Absprungrampe.
`styles` enthält `road` und `scenery`. `report` enthält einen relativen Berichtspfad.
`FormLibrary.load_file(path: String) -> Dictionary` liefert `forms`, `errors` und `digest`.
`SpatialTrack.new(definition: Dictionary, forms: Dictionary)` erstellt die Strecke aus bereits geprüften Daten.
`SpatialTrack.sample(distance_m: float) -> Dictionary` liefert `Frame`.
`SpatialTrack.project_near(position: Vector3, element_id: String, local_m: float) -> Dictionary` liefert `Projection`.
`SpatialTrack.landing_candidates(element_id: String) -> Array[String]` liefert ausdrücklich erlaubte Landeflächen.
`SurfaceQuery.sweep(track, from: Vector3, to: Vector3, candidates: Array[String]) -> Dictionary` liefert einen Kontakt oder `{}`.
Ein Kontakt enthält `fraction`, `position`, `normal`, `element_id` und `local_m`.

### Zustand und Eingaben

`DriveState` enthält Position, Geschwindigkeit und Ausrichtung als `Vector3`, `Vector3` und `Basis`.
Weitere Felder sind `tick: int`, `attempt_id: int`, `element_id: String`, `local_m: float`, `distance_m: float` und `mode: String`.
`mode` ist `grounded`, `airborne`, `crashed` oder `finished`.
`speed_mps` ist der Betrag der Geschwindigkeit. `crashed` bezeichnet einen endgültigen Fehler, nicht jeden kurzzeitigen Kontaktverlust.
`DriveState.snapshot() -> Dictionary` liefert nur kopierbare Werte. Vektoren und Basis werden für JSON in Zahlenfelder umgewandelt.

`controls` enthält `target_speed_mps`, `turn_authorized` und `turn_sign`.
`assistance` enthält `target_speed_mps`, `accel_cap_mps2`, `brake_cap_mps2`, `hold_mps2`, `thrust_world_mps2` und `remaining_s`.
Normale Antriebs- und Bremsgrenzen liegen im neuen versionierten Profil. Sie beginnen mit 10 und 18 m/s² sowie 58 m/s Höchsttempo.
Diese Startwerte benötigen dieselbe Fahrprüfung wie die besonderen Hilfsgrenzen.

`SpatialDriveModel.new(track)` besitzt `state` und die gleichen Befehle wie das bisherige Fahrmodell.
Dazu gehören `step(delta)`, `reset(checkpoint_m)`, `set_assist_level(id)`, `request_turn(direction, strength, event_id)` und `request_assisted_turn(direction, unknown_call, event_id)`.
Es besitzt außerdem `keyboard_speed(direction, delta)`, `change_speed(direction, strength)`, `effective_target_speed()`, `refresh_assist()`, `input_window_m()` und `assist_state()`.
Die Signaturen und Standardwerte entsprechen `scripts/vehicle/drive_model.gd`.
Die räumliche Bewegung verwendet ausschließlich `state`. Kompatible Anzeigefelder leiten sich daraus ab.

`DriveRunner.run(track, profile: Dictionary, inputs: Array[Dictionary], max_ticks: int) -> Dictionary` verwendet dieses Modell.
Ein Eingabeeintrag enthält `tick`, `event_id`, `kind` und `value`.
`kind` ist `turn`, `call`, `faster`, `slower` oder `held_speed`.
Der Runner führt Eingaben vor dem zugeordneten Bewegungsschritt aus.

### Ereignisse und Darstellung

`SpatialDriveModel.take_motion_events() -> Array[Dictionary]` leert genau eine Ereignisliste.
Ein Ereignis enthält `id`, `attempt_id`, `tick`, `element_id`, `type`, `position`, `normal` und `magnitude`.
`type` ist `landing`, `boost_start`, `boost_end`, `hold_start`, `hold_end`, `contact_lost` oder `crash`.
Bei `landing` ist `magnitude` die Aufprallgeschwindigkeit senkrecht zur Fahrfläche in m/s.
Kennungen bestehen aus Versuch, Rechenschritt und laufender Nummer.

`SpatialDriveModel.feedback_state() -> Dictionary` enthält `grounded`, `accel_local`, `slip_mps`, `braking`, `boosting`, `surface_kind`, `wheel_contacts` und `paused`.
`wheel_contacts` sind vier abgeleitete Kontaktpunkte ohne eigene Radphysik.
Die Hauptszene verteilt dieselben Ereigniskopien an Darstellung und Ton. Kein Verbraucher leert die Liste ein zweites Mal.
Die bestehenden `take_assist_events()` bleiben für Kurvenhinweise getrennt bestehen.

## Aufgabe 1: Formbeschreibungen und Format 2

**Dateien:** Neu `scripts/track/spatial/track_definition.gd`, `form_library.gd`, `tracks/forms/stunt_v1.json`, `tools/spatial/extract_forms.gd`, `tests/spatial/test_definition.gd`, `tests/fixtures/spatial/straight.json`.

**Schnittstellen:** Erzeugt `TrackDefinition.validate` und `FormLibrary.load_file` aus dem Abschnitt „Fahrdaten“.

- [x] Erfasse vor der Änderung den Ausgangsstand mit `tests/run_track_tests.gd`, `tests/run_tests.gd` und `tests/assets/check_kit.gd`.
- [x] Schreibe `test_definition.gd` mit gültiger Gerade, doppelter Elementkennung, unbekannter Formversion, unendlicher Zahl und falschem Anschluss.
- [x] Prüfe ausdrücklich `validate(valid, forms).is_empty()` und Fehlercodes für jeden ungültigen Fall.
- [x] Führe den neuen Test aus und bestätige den fachlichen Fehler.
- [x] Implementiere den Lader für `format_version`, `name`, `description`, `scenario`, `styles`, `elements`, `landings` und `report`.
- [x] Extrahiere `centerline`, `up_vectors`, `Entry` und `Exit` einmalig aus den neun vorhandenen Streckenszenen.
- [x] Speichere die Fahrdaten unabhängig von den Szenen. Verwende Meter, explizite Versionsnummern und die Breite 6,0 m.
- [x] Prüfe die Anschlussgrenzen 0,001 m und 0,1 Grad sowie den Erhalt der Looping-Oberseite.
- [x] Speichere nur diese Aufgabe in einem Commit.

Ausführung: `"$STUNTCAR_GODOT" --headless --log-file /private/tmp/stuntcar-definition.log --path . --script tests/spatial/test_definition.gd`.
Erwartung nach der Umsetzung: Exitcode 0, keine Skriptfehler und null fehlgeschlagene Prüfungen.

## Aufgabe 2: Räumlicher Verlauf und Kontaktabfragen

**Dateien:** Neu `scripts/track/spatial/spatial_track.gd`, `surface_query.gd`, `tests/spatial/test_geometry.gd`, `tests/fixtures/spatial/loop.json`.

**Schnittstellen:** Verwendet die geprüften Daten aus Aufgabe 1. Erzeugt `sample`, `project_near`, `landing_candidates` und `sweep`.

- [x] Schreibe Tests für wirkliche Bogenlänge, orthogonale Richtungen, Anschlussstetigkeit und den höchsten Looping-Punkt.
- [x] Prüfe dort `frame.basis.y.dot(Vector3.UP) < -0.99` und `abs(frame.basis.determinant() - 1.0) < 0.00001`.
- [x] Ergänze `test_nearby_loop_does_not_skip_progress`: Ein Punkt nahe der Einfahrt bleibt seinem aktuellen Looping-Abschnitt zugeordnet.
- [x] Ergänze einen Kontakt, der genau zwischen Start und Ende eines Schritts liegt. Prüfe `0.0 < hit.fraction and hit.fraction < 1.0`.
- [x] Führe die Tests aus und bestätige die fehlenden Funktionen als Ursache.
- [x] Implementiere die Abfragen über vorab berechnete räumliche Abschnitte und deren Bogenlänge.
- [x] Interpoliere Ausrichtungen über Quaternionen mit gleicher Vorzeichenhälfte. Verwende keine getrennte Winkelinterpolation für Loopings.
- [x] Erzeuge die Fahrflächendreiecke aus derselben Formbeschreibung. Prüfe Sweeps gegen diese Dreiecke einschließlich Fahrbahnbreite.
- [x] Begrenze die Fortschrittssuche auf ein lokales Fenster und ausdrücklich erlaubte Nachbarelemente.
- [x] Bestätige alle Geometrieprüfungen und speichere den Commit.

Ausführung: `"$STUNTCAR_GODOT" --headless --log-file /private/tmp/stuntcar-geometry.log --path . --script tests/spatial/test_geometry.gd`.
Erwartung: Exitcode 0; kein Sprung zwischen räumlich benachbarten Looping-Abschnitten.

## Aufgabe 3: Austauschvertrag und zwei Modellzuordnungen

**Dateien:** Neu `scripts/track/visuals/model_catalog.gd`, `model_validator.gd`, `assets/stuntcar_styles/catalog.json`, `assets/stuntcar_styles/neutral/`, `assets/stuntcar_styles/contrast/`, `tests/spatial/test_models.gd`.

**Schnittstellen:** `ModelCatalog.resolve(style_id: String, form_id: String, form_version: int) -> Dictionary` liefert `scene_path`, `fallback`, `errors`. `ModelValidator.check_scene(root: Node3D, form: Dictionary) -> Dictionary` liefert Fehler und Messwerte.

- [x] Schreibe Tests für fehlende Datei, falsche Formversion, verschobenen Anschluss, falsche Oberseite und importierte Kollisionsknoten.
- [x] Ergänze `test_same_endpoints_wrong_middle`: Gleiche Endpunkte dürfen eine falsche Fahrfläche nicht freigeben.
- [x] Prüfe die Grenzen mit 0,0009/0,0011 m am Anschluss und 0,019/0,021 m an der Fahrfläche.
- [x] Führe den Test vor der Umsetzung aus.
- [x] Implementiere Einträge mit `id`, `model_version`, `scene_path`, `role`, `form_id`, `form_version`, `surface_meshes` und `fallback_id`.
- [x] Erstelle umgebende Godot-Szenen mit `Entry` und `Exit`; referenziere vorhandene Modelle, ohne deren Originaldateien zu überschreiben.
- [x] Prüfe importierte Gesamttransformationen einschließlich Achsen, positiver Einheits-Skalierung und einer möglichen Spiegelung. Weise unpassende Transformationen zurück.
- [x] Erstelle eine zweite Darstellung mit anderer Oberfläche und identischer Fahrform. Verwende dafür keine Blender-Sitzung.
- [x] Prüfe Ränder und Mitte alle 0,25 m sowie alle Formstützpunkte. Dokumentiere diese Stichprobe im Ergebnis.
- [x] Entferne oder deaktiviere importierte Kollisionsknoten vor dem Einfügen der sichtbaren Szene.
- [x] Bestätige Rückfall auf das passende Ersatzmodell und speichere den Commit.

Ausführung: `"$STUNTCAR_GODOT" --headless --log-file /private/tmp/stuntcar-models.log --path . --script tests/spatial/test_models.gd`.
Erwartung: Exitcode 0; jeder ungültige Modelleingang liefert einen Fehlercode und ein passendes Ersatzmodell.

## Aufgabe 4: Neue Strecke darstellen und alte Strecken erhalten

**Dateien:** Neu `scripts/track/track_factory.gd`, `scripts/track/visuals/spatial_builder.gd`, `tests/spatial/test_track_loading.gd`. Ändern `scripts/track/track_data.gd`, `tools/check_tracks.gd`, `locales/en.po`.

**Schnittstellen:** `TrackFactory.load_track(path: String) -> Dictionary` liefert `track`, `errors`, `format_version`. `SpatialBuilder.build(track, styles: Dictionary) -> void` verwendet Aufgaben 2 und 3.

- [x] Schreibe Tests für gemischte Kataloge, ungültige Versionen, fehlende Vorschau und eine weiterhin unveränderte Version-1-Strecke.
- [x] Prüfe, dass `TrackFactory.load_track(v1_path).track` das bisherige `TrackData` verwendet.
- [x] Führe die Tests vor dem Eingriff aus.
- [x] Ergänze im vorhandenen Katalog eine reine Versionsverzweigung. Verändere die Version-1-Prüfung und ihre Bewegungsdaten nicht.
- [x] Ergänze `format_version` in Katalogeinträgen. Halte `path`, `name`, `description`, `scenario`, `preview`, `length_m`, `curves` und `jumps` kompatibel.
- [x] Implementiere den neuen Builder mit den Fahrflächendreiecken aus Aufgabe 2 und den sichtbaren Modellen aus Aufgabe 3.
- [x] Stelle am neuen Builder die bestehende Eigenschaft `landscape` für die Hauptszene bereit. Verwende für neue Landschaften eine eigene Instanz.
- [x] Ergänze getrennte Straßen- und Landschaftsstile mit einfachen eigenen Landschaftsmodellen. Halte Fahr- und Landebereiche frei.
- [x] Prüfe Kollisionsebene 1 für autorisierte Fahrflächen und keine zusätzlichen Kollisionsflächen aus Darstellungen.
- [x] Führe `test_track_loading.gd`, `tests/run_catalog_tests.gd`, `tests/run_track_tests.gd` und `tools/check_tracks.gd` aus.
- [x] Speichere den Commit nach erfolgreicher Prüfung.

Neuer Test: `"$STUNTCAR_GODOT" --headless --log-file /private/tmp/stuntcar-loading.log --path . --script tests/spatial/test_track_loading.gd`.
Erwartung für alle genannten Prüfungen: Exitcode 0 und keine Skriptfehler.

## Aufgabe 5: Bewegung auf räumlichen Fahrflächen

**Dateien:** Neu `scripts/vehicle/spatial/drive_state.gd`, `surface_motion.gd`, `tests/spatial/test_surface_motion.gd`.

**Schnittstellen:** `SurfaceMotion.step(track, state, controls: Dictionary, assistance: Dictionary, dt: float) -> Dictionary` liefert Kontaktzustand und Messwerte. `DriveState.snapshot` entspricht dem gemeinsamen Vertrag.

- [x] Schreibe Tests für Stillstand, Beschleunigung, Hangabtrieb, Kuppe, Looping-Oberseite und seitliches Verlassen der Fahrbahn.
- [x] Prüfe bei gleicher Anfangsgeschwindigkeit: `uphill.speed_mps < level.speed_mps` ohne Antrieb oder Hilfe.
- [x] Prüfe Kontaktverlust bei unzureichender Haltekraft und den Erhalt der Geschwindigkeit am Übergang zum Flug.
- [x] Führe die neuen Tests aus.
- [x] Implementiere die normale Beschleunigung und die begrenzte seitliche Führung relativ zur örtlichen Fahrbahn.
- [x] Verwende für Format 2 die Spielschwerkraft `Vector3(0, -9.81, 0)`. Verändere keine Version-1-Konstante.
- [x] Berechne den benötigten normalen Kontakt pro Masseneinheit aus `v² * curvature.dot(up) - gravity.dot(up)`.
- [x] Erlaube negativen normalen Kontakt nur bis zur ausdrücklich verfügbaren Haltebeschleunigung. Überschreiten löst Kontaktverlust aus.
- [x] Begrenze Antrieb, Bremsung und seitliche Führung über übergebene Werte. Vermeide ein Zurücksetzen auf die Streckenmitte.
- [x] Bestätige die Tests einschließlich entgegengesetzter Fahrbahnoberseite und speichere den Commit.

Ausführung: `"$STUNTCAR_GODOT" --headless --log-file /private/tmp/stuntcar-surface.log --path . --script tests/spatial/test_surface_motion.gd`.
Erwartung: Exitcode 0; Lage, Geschwindigkeit und Kontakt bleiben nachvollziehbar.

## Aufgabe 6: Tempoabhängiger Flug und geprüfte Landung

**Dateien:** Neu `scripts/vehicle/spatial/flight_motion.gd`, `tests/spatial/test_flight.gd`, `tests/fixtures/spatial/jump.json`.

**Schnittstellen:** `FlightMotion.step(track, state, assistance: Dictionary, dt: float) -> Dictionary` liefert `landed`, `crashed` und `impact_mps`. Verwendet `SurfaceQuery.sweep`.

- [x] Schreibe Tests für zwei Absprungtempi, zu kurze Flugweite, zu große Flugweite, falsche Ausrichtung und einen gültigen Kontakt zwischen zwei Rechenschritten.
- [x] Prüfe `fast.landing_distance_m > slow.landing_distance_m` ohne Schub bei gleicher Rampe.
- [x] Prüfe, dass `slower` im Flug keine Reifenbremskraft erzeugt und eine verfehlte Landung kein `landing`-Ereignis erzeugt.
- [x] Führe die Tests vor der Umsetzung aus.
- [x] Übernimm am Absprung Position, Geschwindigkeit und Ausrichtung ohne Sprung in den Werten.
- [x] Integriere die konstante Schwerkraft mit `p += v*dt + 0.5*g*dt*dt` und anschließend `v += g*dt`.
- [x] Teile einen Schritt an Absprung oder Kontakt in die verbleibenden Zeitanteile. Begrenze wiederholte Übergänge pro Schritt mit einer Fehlermeldung statt einer Endlosschleife.
- [x] Prüfe Kontaktweg, Landefläche, Bewegungsrichtung, Ausrichtungsfehler und Aufprallgeschwindigkeit gegen die Landedaten.
- [x] Setze nur bei tatsächlichem gültigem Kontakt auf Bodenkontakt um. Übernimm den verbleibenden Bewegungsanteil.
- [x] Bestätige die Flugtests und speichere den Commit.

Ausführung: `"$STUNTCAR_GODOT" --headless --log-file /private/tmp/stuntcar-flight.log --path . --script tests/spatial/test_flight.gd`.
Erwartung: Exitcode 0; keine automatische Platzierung auf der Landerampe.

## Aufgabe 7: Begrenzte Hilfen und gemeinsames Fahrmodell

**Dateien:** Neu `scripts/vehicle/spatial/stunt_assist.gd`, `profiles.json`, `scripts/vehicle/spatial_drive_model.gd`, `tests/spatial/test_assists.gd`. Verwenden `scripts/vehicle/curve_assist.gd`.

**Schnittstellen:** `StuntAssist.evaluate(track, state, profile: Dictionary, requested_speed_mps: float) -> Dictionary` liefert Zieltempo, begrenzte Beschleunigungen und Restdauer. `SpatialDriveModel` verbindet Aufgaben 5 und 6 mit dem gemeinsamen Vertrag.

- [x] Schreibe Tests für beide Stufen, fehlende Kurvenfreigabe, falschen Ruf, leisen Ruf, Tempobefehl und wiederholte Ereigniskennung.
- [x] Ergänze Grenzen bei maximaler Hilfsdauer sowie unmittelbar davor und danach.
- [x] Prüfe, dass ein Looping keine folgende Kurve freigibt und ein Neustart alte Ereignisse verwirft.
- [x] Führe die Tests vor der Umsetzung aus.
- [x] Implementiere neue Profile getrennt vom bestehenden `assist_profile.gd`. Verwende endliche Zahlen und positive Grenzen.
- [x] Beginne die Abstimmung mit diesen ausdrücklich ungeprüften Startwerten: Hilfe für Beschleunigung 32/24 m/s², Bremsung 120/80 m/s², Halten 9,81/4,905 m/s² für Sehr leicht/Leicht.
- [x] Begrenze besondere Hilfe zunächst auf 4/2 Sekunden und einen Luftschub auf 8/4 m/s² während höchstens 0,5/0,25 Sekunden.
- [x] Erlaube die bestehende Kurvenführung nur nach gültiger Eingabe. Übernimm die bisherigen Grenzen 2,4 m Seitenabweichung und 20 Grad Richtungsabweichung als Startbedingungen.
- [x] Erhalte die Spieler-Tempoanforderung getrennt vom Hilfsziel. Ein dauerhaft gehaltener Befehl setzt kein Hilfsbudget zurück.
- [x] Erzeuge stabile Bewegungsereignisse und die vorhandenen Kurvenereignisse. Begrenze jede Ereignisliste auf 128 Einträge pro Schritt.
- [x] Bestätige alle neuen Hilfstests und die bestehenden Rufprofil- und Kurvenfreigabetests. Speichere den Commit.

Die Startwerte sind keine zugesagten Sicherheitsgrenzen. Aufgabe 12 prüft und versioniert die endgültigen Werte.
Ausführung: `"$STUNTCAR_GODOT" --headless --log-file /private/tmp/stuntcar-spatial-assists.log --path . --script tests/spatial/test_assists.gd`.
Erwartung: Exitcode 0; jede besondere Hilfe besitzt ein messbares Ende.

## Aufgabe 8: Gemeinsame Fahrprüfung und gültige Tempoangaben

**Dateien:** Neu `scripts/vehicle/spatial/drive_runner.gd`, `scripts/track/spatial/verification.gd`, `tools/spatial/check_drives.gd`, `tests/spatial/test_verification.gd`.

**Schnittstellen:** `DriveRunner.run` entspricht dem Vertrag. `Verification.digest(track, profile: Dictionary) -> String` kennzeichnet alle Fahrdaten. `Verification.speed_hint(report: Dictionary, digest: String, element_id: String, state: Dictionary) -> Dictionary` liefert einen gültigen Hinweis oder `{}`.

- [x] Schreibe Tests für gleiche Eingaben, veränderte Form, geändertes Profil, fremde Strecke und einen Anfahrzustand außerhalb des geprüften Bereichs.
- [x] Prüfe `speed_hint(old_report, changed_digest, id, state).is_empty()` und einen gültigen Hinweis bei unveränderten Daten.
- [x] Führe die neuen Tests aus.
- [x] Implementiere den Runner mit demselben Modell, derselben Ereignisreihenfolge und `dt = 1.0/60.0`.
- [x] Erstelle Prüfsummen aus kanonisch geordneten Fahrdaten, Formdaten, Kontaktflächen, Profilen, Rechenschritt und Fahrregelversion samt Quellprüfsummen.
- [x] Schließe reine Modellpfade, Materialien und Effektparameter aus der Fahrprüfsumme aus.
- [x] Schließe auch Berichtsinhalte aus der Fahrprüfsumme aus. Verhindere dadurch einen Kreis zwischen Bericht und seiner eigenen Prüfsumme.
- [x] Speichere Anfahrzustände, Eingaben, Zwischenzustände, Hilfen, Zeiten und Fehlergründe pro Fahrt.
- [x] Unterscheide statische Dateigültigkeit von Fahrfreigabe. Der Prüflauf darf ungeprüfte Strecken laden; das normale Menü gibt sie erst nach gültigem Bericht frei.
- [x] Kennzeichne nur geprüfte Stichproben als solche. Leite keine garantierten Zwischenwerte aus einer groben Temporeihe ab.
- [x] Bestätige die Tests und speichere den Commit.

Ausführung: `"$STUNTCAR_GODOT" --headless --log-file /private/tmp/stuntcar-verification.log --path . --script tests/spatial/test_verification.gd`.
Erwartung: Exitcode 0; geänderte Fahrdaten verwerfen die alten Tempoangaben.

## Aufgabe 9: Eingabe, Auswahl und Spielzustände verbinden

**Dateien:** Neu `scripts/vehicle/drive_model_factory.gd`, `tests/spatial/test_session.gd`. Ändern `scripts/main.gd`, `scripts/input/command_router.gd`, `scripts/ui/game_ui.gd`, `scripts/ui/track_selection.gd`, `locales/en.po`.

**Schnittstellen:** `DriveModelFactory.create(track)` wählt das alte oder neue Fahrmodell. `TrackFactory.load_track` ersetzt direkte Neukonstruktionen bei Start, Streckenwechsel und Einstellungen.

- [x] Schreibe Szenentests für Wechsel von Format 1 zu 2 und zurück, Pause, Neustart, gespeicherte Auswahl und fehlenden Bericht.
- [x] Prüfe die vorhandenen Anzeigefelder des neuen Modells gegen den tatsächlichen Zustand. Dazu gehören `position`, `speed_mps`, `distance_m`, `airborne`, `off_road`, `finished`, `elapsed_s`, `lateral`, `active_curve_id` und `assist_id`.
- [x] Prüfe außerdem die bisherigen Tempo-, Kurven- und Ereignismethoden über den echten `CommandRouter`.
- [x] Führe die Szenentests vor der Verbindung aus.
- [x] Implementiere abgeleitete Kompatibilitätsfelder in `SpatialDriveModel`. Bewahre Schreibzugriff für `hint_seconds` und die vorhandenen Einstellungswege.
- [x] Ergänze die von der Anzeige benötigten Streckenabfragen `next_curve`, `section_at`, `jump_at`, `speed_hint_at` und Katalogwerte am neuen Streckenmodell.
- [x] Übernimm dafür die vorhandenen Signaturen und Ergebnisfelder von `TrackData`. Leite Kurven, Sprünge und Kontrollpunkte aus den neuen Elementen ab.
- [x] Rufe die allgemeine Zahlenprüfung in der Hauptszene direkt über `TrackData.number` auf. Sie darf nicht vom gewählten Streckenformat abhängen.
- [x] Verwende vorhandene Kurvennummern für die Eingabe; ordne sie intern eindeutig den stabilen Elementkennungen zu.
- [x] Beziehe neue Tempohinweise ausschließlich aus `Verification.speed_hint`. Zeige unbekannte Werte verständlich an.
- [x] Lasse bei Format 2 das neue Modell auch den Absturz berechnen. Verhindere eine zweite Bewegung durch `CarView.fall` während desselben Schritts.
- [x] Ergänze im Zustand `FALLING` genau einen Bewegungsschritt für Format 2. Erhalte die bisherige Rückkehrfrist von 1,1 Sekunden und den Neustart am Kontrollpunkt.
- [x] Bestätige neue Szenentests, `tests/run_input_tests.gd`, `tests/run_selection_tests.gd`, `tests/run_voice_tests.gd` und `tests/test_localization_catalog.py`.
- [x] Speichere den Commit.

Ausführung: `"$STUNTCAR_GODOT" --headless --log-file /private/tmp/stuntcar-spatial-session.log --path . --script tests/spatial/test_session.gd`.
Erwartung: Exitcode 0; beide Streckenformate bleiben über dieselben Eingaben spielbar.

## Aufgabe 10: Räumliches Auto und ruhige Kamera

**Dateien:** Ändern `scripts/vehicle/car_view.gd`, `scripts/camera/follow_camera.gd`, `scripts/main.gd`. Neu `tests/spatial/test_camera.gd`, `tests/spatial/capture_loop.gd`.

**Schnittstellen:** `CarView.place_spatial(state: Dictionary) -> void`, `CarView.drive_spatial(previous: Dictionary, current: Dictionary, alpha: float) -> void`. `FollowCamera.follow_spatial(frame: Dictionary, target: Vector3, speed_mps: float, delta: float) -> void`.

- [x] Schreibe Tests für senkrechte Fahrt, umgekehrte Oberseite, Neustart und den Übergang vom Looping zur Geraden.
- [x] Prüfe endliche Kamerawerte und eine positive, annähernd eins große Basisdeterminante während der ganzen Durchfahrt.
- [x] Führe die neuen Tests aus.
- [x] Verwende die vollständige Basis für Fahrzeug und Kamera. Erhalte den bisherigen Darstellungsweg für Format 1.
- [x] Interpoliere nur die Anzeige zwischen zwei vollständigen Fahrzuständen. Ändere dadurch keine Fahrzustände.
- [x] Führe die Kameraausrichtung stetig entlang der Fahrbahn fort. Verwende keine feste Welt-Oberseite am senkrechten Abschnitt.
- [x] Halte die letzten gültigen Richtungen bei Stillstand. Setze sie beim Neustart ausdrücklich auf den neuen Startpunkt.
- [x] Bestätige die Tests und erstelle Bilder von Einfahrt, beiden senkrechten Abschnitten, Scheitel und Ausfahrt.
- [x] Prüfe die Bilder auf verdeckte Fahrbahn, falsche Fahrzeugoberseite und abgeschnittenes Auto. Speichere den Commit.

Ausführung: `"$STUNTCAR_GODOT" --headless --log-file /private/tmp/stuntcar-camera.log --path . --script tests/spatial/test_camera.gd`.
Bildprüfung: `"$STUNTCAR_GODOT" --log-file /private/tmp/stuntcar-loop-images.log --path . --script tests/spatial/capture_loop.gd`.
Erwartung: Tests bestehen; die Bildfolge zeigt eine stetige Drehung ohne plötzlichen Seitenwechsel.

## Aufgabe 11: Sichtbares Gewicht, Spuren und passende Geräusche

**Dateien:** Neu `scripts/vehicle/ride_feedback.gd`, `tire_marks.gd`, `tests/spatial/test_feedback.gd`, `tests/spatial/capture_feedback.gd`. Ändern `scripts/vehicle/car_view.gd`, `stunt_effects.gd`, `scripts/audio/race_audio.gd`, `scripts/main.gd`.

**Schnittstellen:** `RideFeedback.advance(state: Dictionary, events: Array[Dictionary], dt: float) -> Dictionary` liefert sichtbaren Versatz und Neigung. `TireMarks.advance(state: Dictionary, dt: float) -> void`. `RaceAudio.apply_motion_events(events: Array[Dictionary], session) -> void`.

- [x] Schreibe Tests für schwache und starke gültige Landungen, Bremsen, Beschleunigen, Gleiten und Flug ohne Reifenkontakt.
- [x] Prüfe `hard.compression_m > soft.compression_m`, `hard.compression_m <= 0.16` und `airborne.new_mark_count == 0`.
- [x] Ergänze Tests für doppelte Ereigniskennung, Pause vor Landung, Tonabschaltung, Neustart und einen langen Ablauf mit vielen Spuren.
- [x] Prüfe bei gleichen Eingaben `trace_with_effects == trace_without_effects`.
- [x] Führe die Tests vor der Umsetzung aus.
- [x] Implementiere eine gedämpfte sichtbare Federbewegung mit höchstens 0,16 m Versatz und höchstens 5 Grad zusätzlicher Neigung.
- [x] Leite Bremsneigung und seitliche Neigung aus `accel_local` ab. Halte die eigentliche Fahrzeugbasis unverändert.
- [x] Begrenze Reifenspuren auf 256 Abschnitte mit höchstens 12 Sekunden Lebensdauer. Verwende alte Plätze erneut.
- [x] Begrenze gleichzeitig sichtbare Partikel auf 128 pro Auto. Erzeuge Reifenrauch nur bei Bodenkontakt und Staub nur nach passender Landung.
- [x] Verteilt die Hauptszene ein Landungsereignis, verwenden Bild und Ton dieselbe Stärke. Unterdrücke dabei den alten zusätzlichen Landeton aus dem Zustandswechsel.
- [x] Verbrauche stummgeschaltete Ereignisse ohne Ton. Spiele sie nach dem Einschalten nicht nach. Halte Effektzeit und Ereignisverteilung während einer Pause an.
- [x] Erhalte die bestehenden Lautstärkeregler und die Absenkung der Fahrgeräusche bei Hinweisen. Ergänze kein Kamerazittern.
- [x] Bestätige neue Tests, `tests/run_audio_tests.gd`, `tests/run_engine_audio_tests.gd`, `tests/run_stunt_scene_tests.gd` und die Bildprüfung. Speichere den Commit.

Ausführung: `"$STUNTCAR_GODOT" --headless --log-file /private/tmp/stuntcar-feedback.log --path . --script tests/spatial/test_feedback.gd`.
Bildprüfung: `"$STUNTCAR_GODOT" --log-file /private/tmp/stuntcar-feedback-images.log --path . --script tests/spatial/capture_feedback.gd`.
Erwartung: Tests bestehen; Effekte erklären die Bewegung und verdecken keine Hinweise oder Landeflächen.

## Aufgabe 12: Teststrecke, Abstimmung und freigegebene Fahrbereiche

**Dateien:** Neu `tracks/06_stuntlabor.json`, `tracks/reports/06_stuntlabor.json`, `tests/spatial/test_full_drives.gd`, `tests/fixtures/spatial/input_cases.json`, `tests/spatial/legacy_routes.json`, `tests/helpers/legacy_routes.gd`. Ändern `scripts/vehicle/spatial/profiles.json`, `locales/en.po`, `tests/run_lower_assist_tracks_tests.gd`, `run_assist_bounds_tests.gd`, `run_assisted_drive_tests.gd`, `run_speed_hint_tests.gd`, `run_speed_bank_tests.gd`, `run_track_tests.gd`, `run_jump_scene_tests.gd` im Ordner `tests`.

**Schnittstellen:** Verwendet `TrackFactory`, `DriveRunner`, `Verification` und beide Modellstile. Erzeugt den geprüften Bericht samt endgültiger Profilversion.

- [x] Schreibe zuerst vollständige Fahrfälle mit Gerade, Kuppe, Steilkurve, Sprung, Landung, Looping und Folgekurve.
- [x] Verwende als erste Anordnung die vorhandenen Formen und eine Sprunglücke von 24 m. Behandle alle Anfahrwege als ungeprüfte Streckendaten.
- [x] Lege die Landefläche mit ihrer tatsächlichen Breite und Länge fest. Beginne mit höchstens 20 Grad Ausrichtungsfehler und 12 m/s normaler Aufprallgeschwindigkeit als ungeprüften Grenzwerten.
- [x] Führe die Gesamtfahrten aus und halte die konkreten Fehler fest.
- [x] Stimme Vorlauf, Abstand zwischen Elementen, Profile und Landebedingungen anhand der Messwerte ab. Vergrößere keine Grenze nur zur Unterdrückung eines Fehlers.
- [x] Prüfe beide Stufen mit Anfangstempo 0, 5, 14, 22, 35, 46 und 58 m/s sowie passender, später, falscher und fehlender Kurveneingabe.
- [x] Prüfe zusätzlich volle Beschleunigung, volle Bremsung und wechselnde Tempobefehle. Setze zwischen Elementen keinen Fahrzeugzustand zurück.
- [x] Prüfe jeden gefundenen Grenzwert mit ±0,1 m/s, ±0,01 m und ±einem Rechenschritt, soweit die jeweilige Größe zutrifft.
- [x] Vergleiche saubere und absichtlich gerettete Fahrten ab demselben Startzustand. Fordere `rescued.finished_time_s >= clean.finished_time_s` bei erfolgreichen Vergleichsfahrten.
- [x] Prüfe jede saubere Fahrt mit beiden Modellstilen und mit ausgeschalteten Effekten. Fordere gleiche Fahrzustände und Ereignisse.
- [x] Fixiere die vier bisherigen Strecken ausdrücklich in `legacy_routes.json`. Alte Fahrtests dürfen Format-2-Strecken nicht versehentlich mit dem alten Fahrmodell prüfen.
- [x] Verwende dazu `LegacyRoutes.catalog() -> Array[Dictionary]` aus dem neuen Testhelfer in allen oben genannten alten Fahrprüfungen.
- [x] Prüfe die exakten vier bisherigen Streckenpfade auf Vorhandensein. Ein fehlender Eintrag muss den Test fehlschlagen lassen.
- [x] Prüfe getrennt den gemischten Katalog über `test_track_loading.gd`. Die Begrenzung alter Fahrprüfungen darf neue Katalogfehler nicht verbergen.
- [x] Ergänze `--output` für den alten Matrixbericht. Schreibe neue Kontrollläufe nach `/private/tmp`, ohne alte Abnahmeberichte still zu ersetzen.
- [x] Erzeuge erst nach erfolgreicher Prüfung den neuen Bericht. Nenne getestete Zustände, Stichproben und nicht geprüfte Bereiche ausdrücklich.
- [x] Speichere Strecke, Bericht und endgültige Profile gemeinsam in einem Commit.

Ausführung: `"$STUNTCAR_GODOT" --headless --log-file /private/tmp/stuntcar-full-drives.log --path . --script tests/spatial/test_full_drives.gd`.
Bericht: `"$STUNTCAR_GODOT" --headless --log-file /private/tmp/stuntcar-spatial-report.log --path . --script tools/spatial/check_drives.gd -- --track res://tracks/06_stuntlabor.json --output res://tracks/reports/06_stuntlabor.json`.
Erwartung: Beide Stufen besitzen eine saubere vollständige Fahrt. Grenzfälle liefern die jeweils erwarteten Ergebnisse. Alle Vergleichsfahrten erfüllen ihre Kriterien.

## Aufgabe 13: Gesamtprüfung, Modellaustausch und Übergabe

**Dateien:** Neu `tools/spatial/run_checks.py`, `tests/spatial/test_model_swap.gd`, `docs/neue-streckenelemente-abnahme.md`, `docs/blender-streckenmodelle.md`, `assets/stuntcar_styles/README.md`. Ändern `tracks/README.md` und den vorliegenden Plan.

**Schnittstellen:** `run_checks.py` führt Godot-Tests einzeln mit Zeitgrenze aus und schreibt Protokolle unter `/private/tmp`. Kein eigener Fahrberechnungscode.

- [x] Schreibe `test_model_swap.gd` für zwei passende Zuordnungen, einen fehlenden Import, falsche Formversion und eingebaute fremde Kollisionsknoten.
- [x] Prüfe nach einem Austausch gleiche Fahrprüfsumme, gleiche Bewegung und einen erneuerten Darstellungsbericht.
- [x] Prüfe nach Formänderung eine andere Fahrprüfsumme und die Sperre des alten Berichts.
- [x] Führe die Tests aus und korrigiere ausschließlich nachgewiesene Fehler.
- [x] Erstelle den Prüfläufer mit 90 Sekunden Grenze je kleinem Test und 600 Sekunden für Gesamtfahrten. Fehlermeldungen von Godot gelten auch bei Exitcode 0 als Fehler.
- [x] Führe alle neuen Tests und alle vorhandenen eingecheckten `tests/run_*tests.gd` aus. Erfasse auch `run_scene_test.gd`, die Modellprüfung und die alte Fahrtenmatrix über alle vier bisherigen Strecken.
- [x] Prüfe bei `tests/run_landscape_tests.gd` den alten Landschaftsumfang über den Testhelfer. Erhalte dabei die vorhandenen lokalen Landschaftsänderungen.
- [x] Führe zusätzliche lokale Landschaftstests nur als getrennte Prüfung aus. Dokumentiere deren Stand, ohne fremde Dateien in den Commit zu übernehmen.
- [x] Führe die vorhandenen Python-Tests und die Sprachkatalogprüfung aus. Verwende getrennte Protokolle und Einstellungen.
- [x] Erfasse eine Bildfolge und einen kurzen Fahrmitschnitt mit weicher Landung, harter Landung, Looping und sichtbarer Rettung.
- [x] Prüfe einen 10-Minuten-Ablauf auf wachsende Spuren- oder Partikelzahlen. Nenne Gerät, Auflösung und gemessene Bildzeiten im Bericht.
- [x] Dokumentiere den Blender-Austausch mit GLB, Formversion, Anschlüssen, Flächenkennzeichnung, Importprüfung und Rückkehr zur alten Modellversion.
- [x] Dokumentiere tatsächliche Ergebnisse und offene Spielversuche. Behaupte keine Sprach- oder Komfortprüfung mit Menschen ohne einen solchen Versuch.
- [x] Lasse die gesamte Änderung vor der Übergabe unabhängig prüfen, gemäß `superpowers:requesting-code-review`. Behebe bestätigte Fehler und wiederhole die betroffenen Prüfungen.
- [x] Speichere die Abschlussdokumentation und zeige den geprüften Startweg des neuen Branches.

Ausführung: `"$STUNTCAR_PYTHON" tools/spatial/run_checks.py --output /private/tmp/stuntcar-spatial-checks`.
Python: `"$STUNTCAR_PYTHON" -m unittest discover -s voice/tests` und `"$STUNTCAR_PYTHON" tests/test_localization_catalog.py`.
Erwartung: Keine ungeklärten Fehler. Der Bericht unterscheidet automatische Tests, Bildprüfung und tatsächlich durchgeführte Spielversuche.

## Selbstprüfung des Plans

| Anforderung aus dem Entwurf | Aufgaben |
|---|---|
| Alte Strecken und Einstellungen erhalten | 4, 9, 12, 13 |
| Räumliche Form und eindeutige Zuordnung | 1, 2, 5 |
| Austauschbare Blender-Modelle und Ersatzmodelle | 3, 4, 13 |
| Tempoabhängiger Flug und gültige Landung | 5, 6, 12 |
| Endliche Hilfe und keine zusätzliche Kurvenfreigabe | 7, 9, 12 |
| Gemeinsame Berechnung und gültige Tempoangaben | 8, 9, 12 |
| Räumliches Auto und ruhige Kamera | 10, 13 |
| Sichtbares Gewicht, Spuren und Ton | 11, 13 |
| Gleiche Fahrt bei anderem Modell oder ausgeschalteten Effekten | 11, 12, 13 |
| Nachprüfbare Abnahme und Grenzen | 12, 13 |

Die Prüffälle aus dem Abschnitt „Besondere Prüffälle“ stehen in den Aufgaben 2, 3, 6, 8 und 11.
Die benannten Schnittstellen haben jeweils eine erzeugende Aufgabe.
Die Startwerte der neuen Physik und Hilfen bleiben bis Aufgabe 12 ausdrücklich ungeprüft.
Der erste Ausbau benutzt vorhandene Modelle und zwei einfache Darstellungen. Neue Blender-Arbeit ist keine Voraussetzung.

## Übergabe zur Umsetzung

Stefan erhält diesen Plan zusammen mit dem ergänzten Entwurf zur Prüfung.
Der bisherige Wunsch nach Arbeit in dieser Unterhaltung bleibt erhalten.
Empfehlung: Umsetzung Aufgabe für Aufgabe in dieser Unterhaltung, anschließend eine unabhängige Gesamtprüfung.
Die Aufgaben teilen viele Schnittstellen. Eine fortlaufende Umsetzung erleichtert deren Prüfung.
Die Erstellung des Plans startet noch keine Änderung am Spielcode.

## Ausführungsstand

Die Umsetzung und die unabhängige Prüfung sind abgeschlossen.
58 Spielprüfungen bestanden nach den Korrekturen.
Die Ergebnisse stehen in `docs/neue-streckenelemente-abnahme.md`.
Der Branch und der Arbeitsordner bleiben für den Spielversuch erhalten.

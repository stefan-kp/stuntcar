# Prüfstand der modularen Steuerung

Die automatische Abnahme besteht nach den Astra-Korrekturen am 17. Oktober 2026 mit 32 von 32 Aufträgen.
Die Prüfungen verwenden Godot 4.5.1 unter macOS.
Die Sprachprüfungen verwenden `.tools/voice-env/bin/python` und das vorhandene englische Sprachmodell.
Der globale Python-Aufruf enthielt zuerst kein Vosk. Die vorhandene Sprachumgebung löste diesen Umgebungsfehler.

| Auftrag | Ergebnis |
|---|---|
| `tools/spatial/check_drives.gd` | very_easy: finished at 619.31 m, 32.80 s; easy: finished at 619.31 m, 32.78 s |
| `tests/control/run_contract_tests.gd` | CONTROL: 14 checks, 0 failures |
| `tests/control/run_control_verification_tests.gd` | CONTROL: 6 checks, 0 failures |
| `tests/control/run_controller_tests.gd` | CONTROL: 32 checks, 0 failures |
| `tests/control/run_direction_tests.gd` | CONTROL: 44 checks, 0 failures |
| `tests/control/run_hint_rules_tests.gd` | CONTROL: 14 checks, 0 failures |
| `tests/control/run_hint_view_tests.gd` | CONTROL: 11 checks, 0 failures |
| `tests/control/run_portability_tests.gd` | CONTROL: 11 checks, 0 failures |
| `tests/control/run_session_control_tests.gd` | CONTROL: 10 checks, 0 failures |
| `tests/control/run_source_tests.gd` | CONTROL: 18 checks, 0 failures |
| `tests/control/run_stuntcar_port_tests.gd` | CONTROL: 24 checks, 0 failures |
| `tests/run_input_tests.gd` | EINGABEPRÜFUNGEN: 12, FEHLER: 0 |
| `tests/run_keyboard_speed_tests.gd` | KEYBOARD SPEED: 27 checks, 0 failures |
| `tests/run_voice_bridge_tests.gd` | SPRACHVERBINDUNG: 18 Prüfungen, 0 Fehler |
| `tests/run_voice_scene_tests.gd` | SPRACHE IM SPIEL: 10 Prüfungen, 0 Fehler |
| `tests/run_voice_assist_tests.gd` | RUFHILFE: 41 Prüfungen, 0 Fehler |
| `tests/run_curve_assist_tests.gd` | KURVENHILFE: 26 Bedingungen, 0 Fehler |
| `tests/run_assisted_drive_tests.gd` | UNTERE FAHRHILFE: 45 Bedingungen, 0 Fehler |
| `tests/run_assist_selection_tests.gd` | STUFENWAHL: 11 Bedingungen, 0 Fehler |
| `tests/run_assist_feedback_tests.gd` | HILFSANZEIGE: 9 Bedingungen, 0 Fehler |
| `tests/run_assist_limits_tests.gd` | HILFSKRAEFTE: 0 Fehler |
| `tests/spatial/test_assists.gd` | SPATIAL: 14 checks, 0 failures |
| `tests/spatial/test_surface_motion.gd` | SPATIAL: 7 checks, 0 failures |
| `tests/spatial/test_flight.gd` | SPATIAL: 10 checks, 0 failures |
| `tests/spatial/test_boundaries.gd` | SPATIAL: 11 checks, 0 failures |
| `tests/spatial/test_full_drives.gd` | SPATIAL: 81 checks, 0 failures |
| `tests/spatial/test_verification.gd` | SPATIAL: 10 checks, 0 failures |
| `tests/run_scene_test.gd` | SPIELPRÜFUNG: FINISHED bei 939.740470195968 m; Zeit: 42.5166666666655 s; Fehler: 0 |
| `tests/run_stunt_scene_tests.gd` | STUNTS IM SPIEL: 11 Prüfungen, 0 Fehler |
| `tests/run_i18n_tests.gd` | ÜBERSETZUNGEN: 949 Prüfungen, 0 Fehler |
| `python3 tests/test_localization_catalog.py` | Ran 3 tests in 0.016s; OK |
| `.tools/voice-env/bin/python -m unittest voice.tests.test_protocol voice.tests.test_call_detector voice.tests.test_feedback voice.tests.test_microphone` | Ran 36 tests in 5.481s; OK |

Die normale Fahrt im Stuntlabor und ihre Wiederholung erreichen auf beiden Hilfestufen das Ziel.
Die wiederholten Berichte stimmen einschließlich Eingaben und Hilfsverbrauch überein.
Die vollständige Fahrmatrix enthält weiterhin alle Anfangstempi und Eingabefälle.

Die Sichtprüfung enthält die echte Anzeige für eine passende Kurve, eine falsche Richtung und einen ungeprüften Sprung.
Die Bilder liegen unter `docs/control-review/2026-10-17/`.
Die falsche Richtung zeigt links als gewählte Richtung vor einer Rechtskurve.
Der ungeprüfte Sprung zeigt keine erfundene Mindestgeschwindigkeit.

Eine menschliche Sprachprobe und eine Windows-Probe stehen noch aus.
Astra fand vier wichtige Fehler im Stand `26a8e00`.
Die Korrekturen und ihre gezielten Prüfungen stehen unter `2026-10-17-steuerung-umsetzung-astra.md`.
Nach den Korrekturen besteht die gesamte automatische Abnahme erneut.
Die maschinenlesbaren Ergebnisse liegen unter `docs/control-review/2026-10-17/acceptance.json`.
Vier vollständige Fahrten mit Darstellung erreichen das Ziel.
Die automatische Bildprobe trennt zufällige Betriebssystem-Fokuswechsel von der Fahrprüfung.
Die separate Fokusprüfung der echten Hauptszene bleibt aktiv.

## Entscheidungen während der Umsetzung

- Ruling: Die Hilfsskripte erkennen nur englische Task-Überschriften. Aufgabenblätter werden unverändert aus den deutschen Abschnitten extrahiert. Kein Produktunterschied; Risiko bei falscher Extraktion ist ein ausgelassener Schritt.
- Ruling: Die temporären Prüfdateien liegen im getrennten Arbeitsstand. Ein Sandboxfehler im Hilfsskript wurde durch Abbruch und freigegebene Dateizugriffe behoben. Kein Produktunterschied.
- Ruling: Öffentliche Aktionslisten verwenden Array statt Array[Dictionary], damit JSON-Arrays ohne verdeckte Konvertierung funktionieren; jedes Element wird ausdrücklich validiert. Risiko: fehlende Validierung, deshalb Grenztests.
- Task 2: RED fehlende Auswahl/Reihenfolge, danach zusätzliche RED-Pausenfälle. Ruling: begin_session mit unveränderter Sitzungskennung setzt die Pause zurück, erhält aber die verarbeiteten Kennungen; nur eine neue Sitzung leert diese. Verhindert alte Eingaben nach Fortsetzung; Risiko bei falscher Anbindung ist ausbleibende Fortsetzung.
- Task 3: RED fehlende Adapter. Ruling: VoiceSource.call kollidiert mit Object.call in Godot; der Adapter heißt activate_call. Keine Verhaltensänderung; Risiko sind veraltete Aufrufer, deshalb Quellen- und Integrationstests. Tastenzuweisungen akzeptieren Array und werden intern typisiert; GDScript.new konvertiert untypisierte Arrays nicht automatisch.
- Ruling Aufgabe 9: Die Vollfahrt-Faelle faster und alternate bleiben erhalten. Ihr Kriterium prueft nun den Vorrang des ausdruecklichen Pedals. Ein dauerhaftes Gas darf wegen des neuen Vertrags die Stunthilfe zum Bremsen unterbinden und scheitern. Die regulaeren Fahrten verlangen weiterhin den Zieleinlauf.
- Ruling Aufgabe 9: Die bestehende Vollfahrtmatrix deckte einen Fehler der geplanten Zehn-Sekunden-Grenze auf. Bei 46/58 m/s oeffnet das Fenster sehr frueh. Die vorhandene Tempohilfe senkt danach die Geschwindigkeit. Der Lenkwunsch endete vor der ersten Kurve. Die passende Vormerkung erhaelt deshalb eine endliche Obergrenze von 30 Sekunden. Kurvenende, Gegenbefehl, Pause und Quellenverlust beenden sie vorher. Manuelle falsche Eingaben behalten 500 ms. Die schweren Faelle bleiben unveraendert.

- Die Spielanbindung bestätigt die Enden aller Mitglieder. Sie meldet frühere Enden über `active_members`.
  Sonst könnte eine beendete Kurvenhilfe eine neue Rufauswahl blockieren.
  Die neue Liste verlangt vollständige Angaben von einer Spielanbindung, die sie anbietet.
- Die Anbindung erhält den neuesten gleichgerichteten Lenkwunsch beim Ende einer älteren Quelle.
  Die zusätzliche Prüfung weist den früheren Fehler nach und besteht nach der Korrektur.

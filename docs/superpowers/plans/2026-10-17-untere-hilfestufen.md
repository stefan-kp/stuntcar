# Umsetzungsplan: Sehr leicht und Leicht

> **Für ausführende Agenten:** Nutze `superpowers:executing-plans` oder nach Stefans Wahl `superpowers:subagent-driven-development`. Arbeite die Aufgaben einzeln ab. Die Kästchen erfassen den Fortschritt.

**Ziel:** Die bestehenden Strecken bieten zwei zugängliche Hilfestufen mit leisen Rufen, sicheren Kurven und verständlicher Rückmeldung.

**Architektur:** Ein eigener Regelteil verwaltet die Freigabe genau einer Kurve. Das vorhandene Fahrmodell berechnet die Bewegung und die begrenzte Tempohilfe. Ein unabhängiges Rufprofil ermöglicht leise Laute ohne laute Kalibrierungsprobe.

**Technik:** Godot 4.5.1, GDScript, Python ab 3.11, vorhandene lokale Spracherkennung mit Vosk. Keine zusätzliche Bibliothek erforderlich.

**Grundlage:** [Entwurf vom 17. Oktober 2026](../specs/2026-10-17-hilfestufen-und-streckenpruefung-design.md), insbesondere Abschnitte 4 bis 6.

**Stand:** Stefan beauftragte diesen Plan nach der Besprechung des Entwurfs. Der Plan liegt zur Prüfung vor. Die Umsetzung hat noch nicht begonnen.

## Verbindliche Grenzen

- „Mittel“ und „Schwer“ bleiben spätere Erweiterungen. Das Menü bietet zunächst nur die beiden fertigen unteren Stufen an.
- Eine angenommene Eingabe gilt höchstens für die zugeordnete Kurve. Die nächste Kurve braucht eine neue Eingabe.
- Die Lautstärke bestimmt dort keinen Lenkeinschlag.
- Ein leiser, vom Raumgeräusch unterscheidbarer Laut muss auf „Sehr leicht“ genügen.
- Das Spiel darf weder lautes Sprechen noch drei verschiedene Lautstärken voraussetzen.
- Erkanntes `faster` oder `slower` verändert das Zieltempo. Es gibt keine Kurve frei.
- Volles Beschleunigen darf die angenommene Kurve nicht nachträglich unrettbar machen.
- Das bisherige Sprungmodell bleibt in diesem Schritt erhalten.
- Keine neuen Strecken, Abzweigungen, Loopings, Mimik, Sprungknöpfe oder allgemeinen Streckensimulatoren.
- Keine neuen Mindest- oder Höchsttempi für Sprünge. Keine Behauptung einer gemessenen Sprachverzögerung.
- Alle Berichte für Stefan verwenden kurze deutsche Sätze. Die Spieloberfläche bleibt gemäß `locales/README.md` englisch.
- Die vorhandenen Tastenzuordnungen, Streckendateien und gespeicherten Einstellungen bleiben nutzbar.
- Die Umsetzung verändert keine fremden lokalen Änderungen. Sie veröffentlicht nichts ohne weiteren Auftrag.

## Besondere Prüffälle

Diese fünf Fälle erhalten eigene Tests in den unten genannten Aufgaben:

1. Ein Ruf endet nach einem Neustart oder einer Pause. Er darf keine neue Fahrt lenken. Aufgaben 4 und 5.
2. Ein Decoder teilt einen Dauerlaut in mehrere Ergebnisse. Er darf dadurch keine weiteren Kurven freigeben. Aufgabe 4.
3. Ein Spieler bremst bis zum Stillstand und beschleunigt anschließend stark. Die aktuelle Freigabe darf keine Folgekurve übernehmen. Aufgaben 1, 2 und 8.
4. Eine gespeicherte Rufübung stammt von einem anderen Mikrofon. Die Rufhilfe bleibt aus; erkannte Wörter und Tasten bleiben nutzbar. Aufgaben 3 und 6.
5. Sprung- und Kurvenhinweis überlappen nach einer Landung. Die Kurveneingabe darf nicht verschwinden. Aufgaben 5 und 7.

## Arbeitsstand und Ausführung

Die Planung prüfte den Arbeitsstand nach Commit `494d18e` lesend.
Andere lokale Änderungen betreffen unter anderem Landschaften, Bilder und die README-Datei.
Vor der Umsetzung prüft der ausführende Agent den dann aktuellen Stand erneut.
Er verwendet einen passenden Arbeitsbaum gemäß `superpowers:using-git-worktrees`. Er verwirft keine vorhandenen Änderungen.

Alle Dateipfade in diesem Plan beziehen sich auf den Projektordner.
Die folgenden Laufzeiten existieren derzeit in der Hauptkopie des Projekts:

```sh
export STUNTCAR_GODOT=/Users/stefan/Documents/railsapps/stuntcar/.tools/Godot.app/Contents/MacOS/Godot
export STUNTCAR_PYTHON=/Users/stefan/Documents/railsapps/stuntcar/.tools/voice-env/bin/python
```

Die Umsetzung prüft diese Pfade vor Gebrauch. Godot verwendet mit `--path .` den jeweiligen Arbeitsbaum.
Szenentests verwenden eine eigene Einstellungsdatei unter dem temporären Ordner. Sie verändern keine persönlichen Mikrofonprofile.
Tests ohne echtes Mikrofon verwenden die vorhandenen Testgeräte und künstliche Eingabepakete.
Ein echter Sprachversuch braucht zusätzlich die zum Arbeitsbaum passende lokale Sprachlaufzeit gemäß `voice_runtime.gd`.
Die Umsetzung richtet diese lokale Laufzeit bei Bedarf über die vorhandenen Werkzeuge ein. Sie ändert dafür keine Produktionspfade.

Jede Aufgabe folgt diesem Ablauf: fehlschlagenden Test ergänzen, Fehler nachweisen, Änderung durchführen, Test bestehen lassen, eigenen Commit erstellen.
Ein fehlendes Programm oder eine fehlende Testdatei zählt nicht als erfolgreicher Nachweis eines fachlich fehlschlagenden Tests.
Jeder Commit enthält nur die Dateien der jeweiligen Aufgabe. Die Umsetzung verwendet kein pauschales `git add .`.

## Dateiaufteilung und feste Schnittstellen

| Datei | Verantwortung |
|---|---|
| Neu: `scripts/vehicle/assist_profile.gd` | Zwei gültige Hilfsprofile, endliche Startparameter und deren Prüfung. |
| Neu: `scripts/vehicle/curve_assist.gd` | Eingabebereich, Freigabe und Ende genau einer Kurve. Keine Anzeige und kein Mikrofonzugriff. |
| Vorhanden: `scripts/vehicle/drive_model.gd` | Tatsächliche Bewegung, Kurvenrettung, Tempohilfe und Schlingern. |
| Neu: `scripts/input/call_profile.gd` | Persönliches Profil aus Raumgeräusch und angenehm leisen Lauten. |
| Neu: `scripts/input/call_practice.gd` | Zustände der Rufübung, getrennt von der bisherigen Lautstärkeübung. |
| Neu: `voice/call_detector.py` | Abgrenzung eines Rufes im unveränderten Mikrofonsignal. |
| Vorhanden: `voice/streaming.py`, `voice/recognizer.py`, `scripts/input/voice_bridge.gd` | Transport des Rufprofils und eindeutiger Eingabeereignisse. |
| Vorhanden: `scripts/input/command_router.gd`, `scripts/main.gd` | Stufenwahl, Eingabeverteilung, Einstellungen und Zustandswechsel. |
| Neu: `scripts/ui/call_practice_panel.gd` | Zugängliche Rufübung mit vorhandenen Bedienelementen. |
| Vorhanden: `scripts/ui/game_ui.gd`, `scripts/ui/voice_compass.gd` | Stufenwahl und Rückmeldung aus dem Fahrmodell. |
| Vorhanden: `scripts/vehicle/car_view.gd`, `scripts/vehicle/stunt_effects.gd`, `scripts/audio/race_audio.gd` | Sichtbare und hörbare Wirkung der tatsächlichen Bewegung. |
| Vorhanden: `locales/en.po` | Alle neuen Texte der Spieloberfläche. |
| Neu: `tests/helpers/assist_test_tools.gd` | Wiederholbare Fahrtests ohne Bildausgabe. Kein eigenständiges Fahrmodell. |

Die Umsetzung erzeugt erforderliche Godot-UID-Dateien mit Godot. Sie erfindet keine UID-Werte.

### Gemeinsame Datensätze

`assist_id` hat ausschließlich die Werte `very_easy` und `easy`.
`curve_id` ist die vorhandene Kurvennummer. Eine zusätzliche `opportunity_id` kennzeichnet den konkreten Versuch.
Ein Neustart erzeugt neue Gelegenheitskennungen. Eine bloße Pause erhält die Freigabe, verwirft aber alte Eingabepakete.

`CurveAssist.snapshot() -> Dictionary` liefert diese festen Felder:

```text
curve_id: int; opportunity_id: int; phase: String; authorized: bool;
turn_sign: int; opened_at_s: float; expires_at_s: float;
accepted_phase: String; closed_reason: String
```

`phase` ist `closed`, `early`, `clean`, `late`, `rescue` oder `active`.
`accepted_phase` hält den Zeitpunkt der ersten gültigen Freigabe fest. Wiederholungen verbessern ihn nicht.
`closed_reason` unterscheidet `not_open`, `expired`, `outside_support`, `missed`, `completed` und `reset`.

`DriveModel.assist_state() -> Dictionary` ergänzt `snapshot()` um:

```text
assist_id: String; player_target_mps: float; assist_target_mps: float;
assist_speed_active: bool; motion: String; assist_reason: String
```

`motion` ist `normal`, `sway`, `late_turn`, `rescue_turn` oder `recovery`.
`assist_target_mps` enthält nur bei `assist_speed_active == true` ein wirksames Hilfsziel.
`target_speed_mps` bleibt der gespeicherte Wunsch des Spielers.

`DriveModel.take_assist_events() -> Array[Dictionary]` leert eine begrenzte Ereignisliste.
Jedes Ereignis enthält `type`, `curve_id`, `opportunity_id`, `elapsed_s` und `reason`.
Für einen Tempoeingriff enthält es zusätzlich Spielerziel, Hilfsziel und tatsächliches Tempo.
Tests, Anzeige und spätere Prüfprogramme lesen dieselben Zustände. Sie berechnen keine zweite Kurvenregel.

## Aufgabe 1: Hilfsprofile und einzelne Kurvenfreigaben

**Dateien:** Neu `scripts/vehicle/assist_profile.gd`, `scripts/vehicle/curve_assist.gd`, `tests/run_curve_assist_tests.gd`.

**Schnittstellen:**

- `AssistProfile.for_id(id: String) -> Dictionary`; ungültige Kennungen ergeben das Profil `very_easy`.
- `AssistProfile.validate(profile: Dictionary) -> String`; eine leere Zeichenfolge bedeutet gültig.
- `CurveAssist.reset(attempt_id: int) -> void`.
- `CurveAssist.update(curve: Dictionary, state: Dictionary, profile: Dictionary) -> void`.
- `CurveAssist.request(direction: int, unknown_call: bool, event_id: String) -> bool`.
- `CurveAssist.snapshot() -> Dictionary` gemäß gemeinsamem Datensatz.

`state` enthält `distance_m`, `speed_mps`, `target_speed_mps`, `elapsed_s`, `hint_seconds`, `lateral`, `gap`, `heading_error_rad`, `off_road` und `finished`.
Der Regelteil merkt sich verarbeitete Ereignisse nur innerhalb des aktuellen Versuchs und mit fester Obergrenze.
`AssistProfile` definiert `late_lateral_m`, `accept_lateral_m`, `accept_heading_rad`, `sway_limit_m` und die Zeitgrenzen aus der folgenden Tabelle.
Die dynamischen Grenzen heißen `max_turn_rate_rad_s`, `max_assist_accel_mps2`, `max_assist_brake_mps2` und `recovery_seconds`.
Aufgabe 2 legt deren erste endliche Werte fest. Aufgabe 8 dokumentiert die endgültigen Werte nach den Fahrprüfungen.

- [ ] Ergänze den Test `one_input_never_authorizes_second_curve`. Er gibt die erste Kurve frei und schließt sie ab.

  ```gdscript
  check(first.authorized, "Die erste Kurve besitzt eine Freigabe.")
  check(not second.authorized, "Die zweite Kurve braucht eine neue Eingabe.")
  check(first.opportunity_id != second.opportunity_id, "Jede Gelegenheit besitzt eine eigene Kennung.")
  ```

- [ ] Ergänze Tests für richtige Richtung, falsche Richtung, unbekannten Ruf und wiederholte Ereigniskennung auf beiden Stufen.
- [ ] Ergänze Tests unmittelbar vor, auf und nach jeder Abschnittsgrenze. Prüfe auch Stillstand, Pause und Ablauf.
- [ ] Führe `"$STUNTCAR_GODOT" --headless --path . --script tests/run_curve_assist_tests.gd` aus. Weise die fehlenden Regeln mit fehlgeschlagenen Bedingungen nach.
- [ ] Implementiere die Schnittstellen mit folgenden vorläufigen Parametern.

| Parameter | Startentscheidung für die Umsetzung |
|---|---|
| Öffnung | Die vorhandene Vorlaufwahl bleibt 3, 5 oder 8 Sekunden. Die erste Öffnung bleibt gespeichert. |
| Referenztempo | Bei Öffnung das Maximum aus tatsächlichem Tempo, Zieltempo und vorhandenem `CRUISE_SPEED` speichern. |
| Früh und passend | `early` endet eine Referenzsekunde vor dem Kurvenanfang. `clean` endet am Kurvenanfang. |
| Spät und sehr spät | `late` gilt nach dem Kurvenanfang bis 0,75 Meter seitlichem Abstand. Danach gilt `rescue`. |
| Annahmegrenze | Vorläufig höchstens 2,4 Meter seitlicher Abstand und Projektionsabstand; höchstens 60 Grad Richtungsabweichung. |
| Zeitgrenze | Öffnungszeit plus `max(10.0, 2.0 * hint_seconds)` Sekunden Spielzeit. |
| Ende | Die erste erreichte Zeit-, Positions- oder Zustandsgrenze schließt eine ungenutzte Gelegenheit endgültig. |

Diese Werte sind Entwurfswerte für die ersten Tests. Sie sind keine gemessenen Rettungsgrenzen.
Aufgabe 8 prüft und ersetzt ungeeignete Werte. Beide Stufen erhalten zunächst dieselben Zeitbereiche.
Die Reihenfolge der Abschnitte läuft nur vorwärts. Eine neue Berechnung des Vorlaufs öffnet keine abgeschlossene Gelegenheit.
An einer Abschnittsgrenze gilt der folgende Abschnitt. Die Annahmegrenze selbst zählt bereits als geschlossen.
Die Annahmegrenzen gelten vor der Freigabe. Nach der Freigabe bestimmt Aufgabe 2 die sichere Bewegung.

- [ ] Prüfe, dass eine falsche Richtung auf „Leicht“ eine vorhandene Freigabe nicht löscht. Prüfe einen weiteren richtigen Befehl nach einer zunächst falschen Eingabe.
- [ ] Wiederhole den Test. Erwarte null fehlgeschlagene Bedingungen und Prozessende mit Code 0.
- [ ] Speichere diese Aufgabe als eigenen Commit: `Hilfsprofile und einzelne Kurvenfreigaben ergänzen`.

## Aufgabe 2: Kurvenfahrt, Tempohilfe und sichere Bewegung

**Dateien:** Ändern `scripts/vehicle/drive_model.gd`; ergänzen `tests/helpers/assist_test_tools.gd`, `tests/run_assisted_drive_tests.gd`.

**Eingang:** Profile und `CurveAssist` aus Aufgabe 1.

**Ausgang:**

- `DriveModel.set_assist_level(id: String) -> void`; Aufruf nur beim Start oder Neustart.
- `DriveModel.request_assisted_turn(direction: int, unknown_call: bool, event_id: String) -> bool` erhält die eindeutige Eingabekennung.
- `DriveModel.assist_state() -> Dictionary` und `take_assist_events() -> Array[Dictionary]`.
- Die vorhandenen Methoden `request_turn`, `change_speed`, `keyboard_speed`, `step` und `reset` behalten ihre Aufrufformen.
- `AssistTestTools.drive(track_path: String, assist_id: String, initial: Dictionary, commands: Array[Dictionary], max_steps: int) -> Dictionary`.

Der Testhelfer verwendet ausschließlich `DriveModel.step(1.0 / 60.0)`.
Ein Testbefehl enthält den Schrittindex sowie Richtung und Art des Befehls.
Das Ergebnis enthält `finished`, `off_road`, `trace`, `events` und `elapsed_s`. `trace` enthält die tatsächlichen Fahrzeugzustände je Schritt.
Der Helfer darf zusätzlich am gewünschten Kurvenende stoppen. Ein Kurventest verwechselt damit nicht die nächste, absichtlich unfreigegebene Kurve mit einem Fehler.
Die Testausschnitte zeigen die entscheidenden Bedingungen. Jede Testdatei legt die dafür benannten Fahrten und Zustände selbst an.

- [ ] Ergänze `no_input_keeps_heading` und `one_valid_input_finishes_curve`. Prüfe beide Stufen und die vorhandenen persönlichen Lautstärkewerte.

  ```gdscript
  check(no_input.off_road, "Ohne Eingabe verpasst das Auto die Kurve.")
  check(is_equal_approx(start_heading, end_heading), "Ohne Eingabe bleibt die Fahrtrichtung gleich.")
  check(not accepted.off_road, "Eine gültige Eingabe genügt für die Kurve.")
  check(quiet.trace == loud.trace, "Die Lautstärke verändert die Lenkung nicht.")
  ```

- [ ] Ergänze Vergleichsfahrten für frühe, passende, späte und sehr späte Eingaben. Prüfe `accepted_phase`, Bewegung und tatsächliche Fahrzeit.
- [ ] Ergänze `full_throttle_after_authorization` mit normaler Höchstgeschwindigkeit und vorhandenem Turbo. Prüfe auch wechselnde Gas- und Bremsbefehle.
- [ ] Führe `"$STUNTCAR_GODOT" --headless --path . --script tests/run_assisted_drive_tests.gd` aus. Weise die bisher fehlende stufenabhängige Bewegung nach.
- [ ] Binde `CurveAssist` in `step` ein. Aktualisiere die Gelegenheit vor einer Anfrage auch bei einem frisch zurückgesetzten Modell.
- [ ] Lasse `request_turn` für direkte Aufrufe eine neue lokale Ereigniskennung erzeugen. Leite danach an `request_assisted_turn` weiter.
- [ ] Entferne den Einfluss von `turn_strength` auf die Kurvenführung der unteren Stufen. Eine gültige Eingabe bestimmt die Führung bis zum Kurvenende.
- [ ] Verwende für sämtliche Lenkaktionen dieser Stufen die normale Stärke. Das gilt auch für die vorhandene Landekorrektur.
- [ ] Trenne Spielerziel und Hilfsziel. Tempobefehle verändern weiterhin `target_speed_mps`; eine Hilfe verändert diesen Wert nicht heimlich.
- [ ] Implementiere die Kurvenführung über begrenzte Richtungsänderung und tatsächliche Bewegung. Verwende keine seitliche Versetzung auf die Ideallinie.
- [ ] Begrenze eine aktive saubere Fahrt und das spätere Schlingern zunächst auf einen seitlichen Zielbereich von höchstens 1,8 Metern.
- [ ] Lasse eine verspätete Annahme außerhalb dieses Zielbereichs stetig zurückführen. Bis dahin darf der tatsächliche Abstand die Annahmegrenze nicht weiter überschreiten.
- [ ] Ergänze endliche Hilfsgrenzen im Profil für Richtungsänderung, Beschleunigung, Bremsung und Erholung. Beginne mit den vorhandenen Kräften und erhöhe sie nur mit einem fehlgeschlagenen Rettungstest als Anlass.
- [ ] Behandle eine nicht rettbare Eingabe vor der Freigabe eindeutig. Nach einer Freigabe darf ein erlaubter Tempobefehl die zugesagte Sicherheit nicht entziehen.
- [ ] Beende die Freigabe am Kurvenende. Verhindere, dass der Blickpunkt der Führung bereits in die nächste Kurve reicht.
- [ ] Erhalte den bisherigen positionsabhängigen Flug und die gesonderte, richtige Landekorrektur. Eine Landekorrektur darf eine gleichzeitige Kurvenfreigabe nicht verbrauchen.
- [ ] Wiederhole die Tests. Prüfe zusätzlich, dass eine Vollbremsung auf einer Geraden weiterhin bis zum Stillstand führt.
- [ ] Speichere diese Aufgabe als eigenen Commit: `Sichere Kurvenfahrt für beide unteren Stufen ergänzen`.

**Zeitverlust:** Späte Eingaben verursachen eine wirkliche Bremsphase oder eine begrenzte Erholungsphase.
Eine bloße Ergebnisstrafe genügt nicht. Wiederholte Richtungseingaben setzen den ursprünglichen Zeitpunkt nicht zurück.
Ein dauerhaft gehaltener Bremsbefehl verändert das Spielerziel auch während der Hilfe.
Nach der zeitlich begrenzten Hilfe gilt dieses Spielerziel wieder. Dieselbe Ursache startet keine endlose Folge von Rettungen.
Die zusätzliche Regel „jede Rettung bleibt insgesamt langsamer“ bleibt eine Entwurfsentscheidung zur Planprüfung.
Die Umsetzung prüft sie zunächst anhand vergleichbarer Fahrten. Sie behauptet keinen Beweis für alle denkbaren Befehlsfolgen.

## Aufgabe 3: Persönliches Rufprofil ohne laute Probe

**Dateien:** Neu `scripts/input/call_profile.gd`, `scripts/input/call_practice.gd`, `tests/run_call_profile_tests.gd`.

**Schnittstellen:**

- `CallProfile.fit(noise: Array[float], calls: Array[Dictionary], device: String) -> Dictionary`.
- `CallProfile.validate(data: Dictionary, device: String) -> String`.
- `CallPractice.begin(device: String) -> void`.
- `CallPractice.receive(level: Dictionary, delta: float) -> void`.
- `CallPractice.profile_data() -> Dictionary`; liefert nur ein erfolgreich abgeschlossenes Profil.
- `CallPractice.reset() -> void`; verwirft die unvollständige Probe, nicht das zuvor gespeicherte Profil.

Das Rufprofil enthält `version`, `device`, `on_rms`, `off_rms`, `min_call_s`, `max_call_s` und `release_s`.
`fit` liefert `{profile: Dictionary, error: String}`. Bei einem Fehler bleibt `profile` leer.
Eine Rufprobe in `calls` enthält `rms_samples: Array[float]`, `duration_s: float` und `clipped: bool`.
`level` enthält `rms: float` und `clipped: bool`. Die Übung sammelt diese Werte unabhängig von erkannten Wörtern.
`rms` bezeichnet einen berechneten Signalpegel. Die Zahlen dienen der Erkennung, nicht dem Lenkeinschlag.
`CallPractice.phase` durchläuft `noise`, `call`, `pause`, `done` oder `retry`.

- [ ] Ergänze Tests für drei angenehm leise Proben, gleiche Stimme bei anderer Mikrofonverstärkung, zu starke Raumgeräusche und einen falschen Gerätenamen.

  ```gdscript
  check(CallProfile.validate(quiet_profile, device).is_empty(), "Das leise Rufprofil ist gültig.")
  check(not CallProfile.validate(quiet_profile, other_device).is_empty(), "Ein anderes Mikrofon braucht eine eigene Probe.")
  check(quiet_profile.on_rms > quiet_profile.off_rms, "Getrennte Grenzen verhindern ständiges Umschalten.")
  ```

- [ ] Führe `"$STUNTCAR_GODOT" --headless --path . --script tests/run_call_profile_tests.gd` aus. Weise fehlende Profilberechnung und Fehlerbehandlung nach.
- [ ] Erfasse zunächst zwei Sekunden Raumgeräusch. Erfasse danach drei getrennte Laute in angenehmer Lautstärke.
- [ ] Trenne während der Probe Signal und Pause zunächst anhand des gemessenen Raumgeräuschs. Verwende dafür den vorläufigen relativen Faktor 2.
- [ ] Berechne `N` als 95. Perzentil des Raumgeräuschs. Berechne `C` als kleinsten mittleren Pegel der drei Laute.
- [ ] Weise die Probe zurück, wenn `C <= 2 * N` oder einer der Laute übersteuert. Das ist ein vorläufiger relativer Qualitätswert.
- [ ] Setze zunächst `on_rms = N + 0.5 * (C - N)` und `off_rms = N + 0.25 * (C - N)`.
- [ ] Verwende als erste Dauern 0,15 Sekunden Mindestdauer, 3 Sekunden Höchstdauer und 0,3 Sekunden Pause. Prüfe diese Werte in Aufgabe 9 mit echten leisen Lauten.
- [ ] Weise leere Proben, negative Werte, nicht endliche Werte und vertauschte Grenzen zurück. Prüfe die technische obere Signalgrenze aus `VoiceCalibration`.
- [ ] Erhalte das letzte gültige Rufprofil bei einem Abbruch. Übernimm kein altes Drei-Lautstärken-Profil als angeblich geprüfte Rufhilfe.
- [ ] Wiederhole den Test und speichere diese Aufgabe als eigenen Commit: `Persönliches Profil für leise Rufe ergänzen`.

Die neue Probe verwendet keine feste Mindestlautstärke wie den bisherigen Wert 180.
Der relative Abstand zum Raumgeräusch entscheidet. Ein unzureichendes Ergebnis fordert keine lautere Stimme.
Die Rückmeldung bietet eine neue Probe nach einer anderen Mikrofonposition oder weniger Raumgeräusch an.

## Aufgabe 4: Leise Laute, Befehlsvorrang und eindeutige Ereignisse

**Dateien:** Neu `voice/call_detector.py`, `voice/tests/test_call_detector.py`; ändern `voice/streaming.py`, `voice/recognizer.py`, `scripts/input/voice_bridge.gd`.
**Tests:** `voice/tests/test_modes.py`, `voice/tests/test_feedback.py`, `voice/tests/test_command_peak.py`, `tests/run_voice_bridge_tests.gd`.

**Schnittstellen:**

- `CallDetector.configure(profile: dict) -> None`.
- `CallDetector.reset() -> None`.
- `CallDetector.feed(pcm: bytes, opportunity_id: int, has_command: bool) -> dict | None`.
- `VoiceBridge.configure_call(profile: Dictionary, opportunity_id: int) -> void`.
- Bestehende `take_commands()` und `take_feedback_events()` liefern weiterhin Ereignisse.

Ein neues Rufereignis enthält `call_id`, `opportunity_id`, `peak_rms`, `speech_seconds` und `has_command`.
Es trägt weiterhin `epoch` und `seq`. Erkannte Wörter erhalten zusätzlich eine eindeutige `event_id`.
`call_id` bleibt über künstliche Decodergrenzen hinweg gleich. Ein neuer Ruf braucht eine echte Pause.
Ruf- und Wortkennungen zählen innerhalb einer Eingabegeneration fortlaufend. Ein bloßes Decoderende setzt diese Zähler nicht zurück.
Die Gelegenheitskennung `-1` bedeutet, dass keine Ruflenkung zulässig ist.

- [ ] Ergänze Python-Tests für ein leises Signal unter dem bisherigen Wert 180, einen Dauerlaut, ein wiederholtes Endergebnis und Raumgeräusch.

  ```python
  self.assertEqual(len(quiet_call_events), 1)
  self.assertEqual(continuous_call_events, [])
  self.assertEqual(noise_events, [])
  self.assertEqual(speed_command_fallbacks, [])
  ```

- [ ] Ergänze `test_decoder_endpoint_does_not_release_call`. Prüfe beide vorhandenen Erkennungsarten `direct` und `checked`.
- [ ] Führe `"$STUNTCAR_PYTHON" -m unittest discover -s voice/tests -p 'test_call_detector.py'` aus. Weise die fehlende Erkennung leiser Rufe nach.
- [ ] Ergänze die Nachricht `type: call_context` mit Profil und `opportunity_id`. Übertrage sie bei Profil- oder Gelegenheitswechsel.
- [ ] Verarbeite diese Nachricht in `Connection.poll`, ohne den Wortdecoder zurückzusetzen. Ein echter Wechsel von `epoch` setzt beide Erkennungen zurück.
- [ ] Gib unveränderte Audiodaten an den Rufdetektor, bevor die bisherige Wortverarbeitung leise Signale abweist.
- [ ] Halte ein erkanntes Wort bis zum echten Rufende als `has_command` fest. Verwerfe dann die unbekannte Rufhilfe für diese Äußerung.
- [ ] Verarbeite endgültige Wortergebnisse vor einer möglichen unbekannten Rufhilfe desselben Rufes. Ein später eintreffendes Wort darf keine bereits ausgelöste Hilfe duplizieren.
- [ ] Verwirf einen zu langen Ruf bis zur nächsten echten Pause. Teile ihn nicht in mehrere kurze Rufe.
- [ ] Halte die erste gültige Gelegenheitskennung eines Rufes bis zu dessen Ende fest. Ein längerer Ruf darf nicht zur Folgekurve wechseln.
- [ ] Binde einen unbekannten Ruf nur an eine Gelegenheit, die während seines Signals aktiv war. Verwende dazu die vom Spiel übertragene Kennung.
- [ ] Verhindere eine rückwirkende Bindung bereits gepufferter Audiodaten. Verwende im Python-Prozess den vorhandenen Erfassungszeitpunkt und den Empfang des neuen Rufkontexts.
- [ ] Prüfe die Gelegenheit zusätzlich bei der Annahme im Spiel. Ein altes Rufende darf nach Pause, Neustart oder Kurvenende nicht wirken.
- [ ] Ergänze Brückentests für falsche Kennungen, ungültige Profile, doppelte Pakete und begrenzte Warteschlangen.
- [ ] Führe die Python-Tests aus diesem Aufgabenblock und `tests/run_voice_bridge_tests.gd` aus. Erwarte keine fehlgeschlagene Bedingung.
- [ ] Speichere diese Aufgabe als eigenen Commit: `Leise Rufereignisse sicher zur Fahrt übertragen`.

Die Gelegenheitskennung beschreibt die Zuordnung. Sie misst keine Gesamtverzögerung der Sprache.
Die Erkennungssoftware kann einen falsch erkannten Tempobefehl nicht als solchen erkennen. Der erkannte Tempobefehl behält deshalb Vorrang.
Die Umsetzung speichert keine neuen Mikrofonaufnahmen. Künstliche Signale und vorhandene Testaufnahmen reichen für die automatischen Tests.

## Aufgabe 5: Stufenwahl, Eingaben und gespeicherte Einstellungen

**Dateien:** Ändern `scripts/input/command_router.gd`, `scripts/main.gd`, `scripts/ui/game_ui.gd`, `locales/en.po`.
**Tests:** Neu `tests/run_assist_selection_tests.gd`; ändern `tests/run_input_tests.gd`, `tests/run_voice_assist_tests.gd`, `tests/run_selection_tests.gd`.

**Eingang:** Fahrmodell aus Aufgabe 2, Rufprofil aus Aufgabe 3, Eingabeereignisse aus Aufgabe 4.
**Ausgang:** `CommandRouter.selected_assist_id: String`, `set_selected_assist(id: String) -> bool` und `submit_call(packet: Dictionary, microphone: String) -> bool`.

- [ ] Ergänze Tests für genau zwei auswählbare Stufen, fehlende Einstellungen, ungültige Werte und einen Stufenwechsel während einer Pause.

  ```gdscript
  check(session.selected_assist_id == "very_easy", "Ohne gespeicherte Wahl gilt Sehr leicht.")
  check(model.assist_state().assist_id == before, "Die aktuelle Fahrt behält ihre Stufe.")
  session.restart()
  check(model.assist_state().assist_id == session.selected_assist_id, "Ein Neustart übernimmt die neue Wahl.")
  ```

- [ ] Führe `"$STUNTCAR_GODOT" --headless --path . --script tests/run_assist_selection_tests.gd` aus. Weise die fehlende Auswahl nach.
- [ ] Ergänze einen Eintrag für die Hilfestufe in den Einstellungen. Verwende die sichtbaren Namen `Very easy` und `Easy` aus dem Textkatalog.
- [ ] Speichere die Wahl unter `game/assist_level`. Behalte den bestehenden Benutzerordner und alle anderen Einstellungswerte bei.
- [ ] Speichere das Rufprofil unter `input/call_profile`. Prüfe es beim Laden gegen das tatsächlich gemeldete Mikrofon vor seiner Nutzung.
- [ ] Übertrage die ausgewählte Stufe erst beim nächsten Start oder Neustart an das Modell. Eine Pause zeigt den Unterschied zwischen aktueller und nächster Stufe.
- [ ] Ersetze die bisherige allgemeine unbekannte Ruflenkung durch `submit_call`. Diese Methode wirkt nur auf `very_easy` und nur bei gültiger Gelegenheit.
- [ ] Übergib gültige Rufe mit `unknown_call == true` an `request_assisted_turn`. Übergib erkannte Richtungswörter mit ihrer Wortkennung und `unknown_call == false`.
- [ ] Lasse `submit_voice` erkannte Tempobefehle unverändert als Tempobefehle behandeln. Richtungsbefehle verwenden die stufenabhängige Kurvenregel.
- [ ] Prüfe Tastendruck, Loslassen, Tastenecho, gleichzeitige Richtungstasten und eigene Tastenzuordnungen. Gas und Bremse bleiben dauerhaft bedienbar.
- [ ] Verwirf alte Eingaben bei Pause, Neustart, Streckenwechsel und Mikrofonverlust. Erhalte bei einer Pause nur die bereits angenommene Kurvenfreigabe.
- [ ] Prüfe den Übergang von einer Landekorrektur zu einer Kurve. Eine gültige Kurveneingabe muss ihre Kennung behalten.
- [ ] Wiederhole die Tests dieses Aufgabenblocks. Speichere die Aufgabe als eigenen Commit: `Untere Hilfestufen auswählbar und dauerhaft speichern`.

## Aufgabe 6: Eine eigene Übung für leise Rufe

**Dateien:** Neu `scripts/ui/call_practice_panel.gd`, `tests/run_call_practice_scene_tests.gd`; ändern `scripts/input/command_router.gd`, `scripts/main.gd`, `scripts/ui/game_ui.gd`, `locales/en.po`.

**Eingang:** `CallPractice` und `CallProfile` aus Aufgabe 3 sowie die unveränderten Signalpegel aus der Sprachbrücke.
**Ausgang:** Eigener Zustand `CALL_PRACTICE`; `CallPracticePanel.render(session, voice_ready: bool, voice_status: String) -> void`.

- [ ] Ergänze einen Szenentest, der die Rufübung ohne gültiges Drei-Lautstärken-Profil vollständig durchläuft.
- [ ] Prüfe Abbruch, fehlendes Mikrofon, Gerätewechsel, Wiederholung und Rückkehr zur Fahrt. Die Übung darf selbst keine Kurve freigeben.
- [ ] Führe `"$STUNTCAR_GODOT" --headless --path . --script tests/run_call_practice_scene_tests.gd` aus. Weise den fehlenden Ablauf nach.
- [ ] Ergänze einen eigenen Eintrag für die Rufübung. Behalte die vorhandene Wort- und Lautstärkeübung als getrennten Ablauf bei.
- [ ] Zeige zuerst die Probe des Raumgeräuschs. Zeige danach jeweils die Aufforderung zu einem angenehm leisen Laut und einer Pause.
- [ ] Nutze die vorhandene Pegelanzeige mit einer Skala aus dem Rufprofil. Verwende keine Aufforderung zu einer höchsten Lautstärke.
- [ ] Speichere ein neues Profil erst nach drei gültigen Proben. Zeige anschließend eine Bestätigung und eine einfache erneute Probe.
- [ ] Erlaube dieselbe Bedienung mit Maus, vorhandenen Menütasten und erkannten Menübefehlen. Ein unbekannter Ruf bestätigt keinen Menüeintrag.
- [ ] Verwende vollständige Textschlüssel im Katalog. Ergänze für schwache Trennung vom Geräusch einen Hinweis auf Mikrofonposition und Raumgeräusch.
- [ ] Wiederhole den Szenentest und die vorhandenen Tests für Sprachübung und Kalibrierung. Speichere diese Aufgabe als eigenen Commit: `Zugängliche Übung für leise Rufe ergänzen`.

## Aufgabe 7: Kurvenhinweise und sicheres Schlingern

**Dateien:** Ändern `scripts/ui/game_ui.gd`, `scripts/ui/voice_compass.gd`, `scripts/main.gd`, `scripts/vehicle/drive_model.gd`, `scripts/vehicle/car_view.gd`, `scripts/vehicle/stunt_effects.gd`, `scripts/audio/race_audio.gd`, `locales/en.po`.
**Tests:** Neu `tests/run_assist_feedback_tests.gd`; ändern `tests/run_stunt_feel_tests.gd`, `tests/run_stunt_scene_tests.gd`.

**Eingang:** `assist_state()` und `take_assist_events()` aus Aufgabe 2.
**Ausgang:** Hinweise, Ton und Effekte aus demselben Modellzustand. Keine neue öffentliche Fahrregel.

- [ ] Ergänze Tests für vorgemerkte Eingabe, saubere Fahrt, späte Eingabe, Rettung und verpasste Kurve.
- [ ] Prüfe, dass der Sprunghinweis einen aktuellen Kurvenhinweis nach der Landung nicht verdeckt.
- [ ] Ergänze eine Fahrt mit starkem Gas in der freigegebenen Kurve. Prüfe eine begrenzte seitliche Bewegung und das sichere Kurvenende.

  ```gdscript
  check(not run.off_road, "Das Schlingern führt nicht zum Absturz.")
  check(max_lateral <= profile.sway_limit_m, "Das Schlingern bleibt innerhalb seiner Grenze.")
  check(next_curve.authorized == false, "Der Effekt übernimmt keine weitere Kurve.")
  ```

- [ ] Führe `"$STUNTCAR_GODOT" --headless --path . --script tests/run_assist_feedback_tests.gd` aus. Weise die fehlende Rückmeldung nach.
- [ ] Ersetze die unabhängige Fensterberechnung in der Anzeige durch `assist_state()`.
- [ ] Lasse das Öffnungsereignis genau einen Hinweis auslösen. Zeige den letzten Rettungsabschnitt sichtbar an.
- [ ] Zeige erkannte Richtung und angewendete Kurvenrichtung getrennt, wenn „Sehr leicht“ eine falsche Richtung ausgleicht.
- [ ] Zeige auf den unteren Stufen keine Lautstärkebalken als angebliche Lenkstärke. Die Pegelanzeige darf weiterhin den Mikrofoneingang zeigen.
- [ ] Löse auf `very_easy` bei starkem Beschleunigen innerhalb einer freigegebenen Kurve einen begrenzten Schlingerimpuls aus.
- [ ] Verwende zunächst einen einmaligen Impuls pro Kurve. `sway_limit_m` darf den sicheren Zielbereich aus Aufgabe 2 nicht überschreiten.
- [ ] Berechne die seitliche Bewegung im Fahrmodell. Leite Karosseriedrehung, Gegenlenken der Vorderräder und Rauch aus dieser Bewegung ab.
- [ ] Unterdrücke den Schlingerimpuls während einer echten Rettung, in der Luft und ohne Kurvenfreigabe.
- [ ] Unterscheide Spielerziel, tatsächliches Tempo und Hilfseingriff in der Anzeige. Sichere Schauwirkung löst keine zusätzliche Zeitstrafe aus.
- [ ] Halte die Kamera gut lesbar. Ergänze kein zufälliges starkes Kamerawackeln.
- [ ] Prüfe Pause und Neustart für alle Effekte. Speichere diese Aufgabe nach erfolgreichen Tests als eigenen Commit: `Klare Kurvenhinweise und sicheres Schlingern ergänzen`.

## Aufgabe 8: Alle bestehenden Strecken und Grenzfälle prüfen

**Dateien:** Neu `tests/run_lower_assist_tracks_tests.gd`, `docs/untere-hilfestufen-testresultate.json`; ändern `scripts/vehicle/assist_profile.gd` und betroffene vorhandene Tests.

**Eingang:** Alle bisherigen Aufgaben und `TrackData.catalog()`.
**Ausgang:** Wiederholbarer Fahrtest und Bericht über tatsächlich geprüfte Kombinationen.

- [ ] Ergänze eine Testmatrix über alle Katalogstrecken, beide Stufen und die Vorlaufwerte 3, 5 und 8 Sekunden.
- [ ] Verwende vorhandene Referenztempi 0, 14, 22, 28 und 46 Meter pro Sekunde. Prüfe zusätzlich den vorhandenen Turbo bis 58 Meter pro Sekunde.
- [ ] Prüfe bei Tempo 0 zuerst den Stillstand und anschließend einen Anfahrbefehl. Eine absichtlich angehaltene Fahrt muss nicht ohne Gas das Ziel erreichen.
- [ ] Ergänze Zwischenwerte in Schritten von 5 Metern pro Sekunde innerhalb des vorhandenen Bereichs. Diese Werte sind Testeingaben, keine empfohlenen Sprungtempi.
- [ ] Prüfe jede Kurve an den Abschnittsgrenzen und jeweils einen Simulationsschritt davor und danach.
- [ ] Prüfe volle Beschleunigung, starke Bremsung und wechselnde Tempobefehle nach einer gültigen Freigabe.
- [ ] Prüfe Zustände innerhalb der Annahmegrenze mit seitlichem Abstand und Richtungsabweichung. Ein Zustand außerhalb der Grenze muss eine klare Ablehnung liefern.
- [ ] Führe `"$STUNTCAR_GODOT" --headless --path . --script tests/run_lower_assist_tracks_tests.gd` aus. Erhalte einen Bericht auch bei einer fehlgeschlagenen Fahrt.
- [ ] Passe nur die Profilwerte an, deren Rettungstest fehlschlägt. Prüfe jede Anpassung erneut auf allen betroffenen Kurven.
- [ ] Verringere vor der Freigabe nötigenfalls eine ungeeignete Annahmegrenze. Entziehe nach der Freigabe keine bereits zugesagte Hilfe.
- [ ] Prüfe ganze Fahrten ohne Neustart zwischen Elementen. Vergleiche saubere und gerettete Fahrten bis hinter die Erholungsphase und bis zum Ziel.
- [ ] Überarbeite alte Erwartungen zu falscher Richtung, Lautstärkelenkung und Pflichtkorrekturen ausdrücklich nach Stufe. Lösche keine fehlgeschlagenen Tests ohne fachliche Begründung.
- [ ] Führe die unten genannten Bestandsprüfungen aus. Trenne neue Fehler von bereits vorhandenen Fehlern anhand der Ausgangsprüfung.
- [ ] Schreibe endgültige Parameter, getestete Bedingungen, Fehler und Grenzen in den Bericht. Speichere die Aufgabe als eigenen Commit: `Untere Hilfestufen auf bestehenden Strecken absichern`.

Der Bericht nennt Quellstand, Profilversion, Strecke, Stufe, Eingabezeitpunkte, Anfangszustände und Schrittweite.
Er nennt außerdem die kleinsten Abstände zur Absturzgrenze und die Anzahl zusätzlicher Korrekturen.
Eine erfolgreiche untere Kurvenhilfe braucht nach der Freigabe null weitere Lenkbefehle.
Die Prüfung nennt ungeprüfte Kombinationen ausdrücklich. Sie ist kein allgemeiner Streckensimulator und kein Vollständigkeitsbeweis.

### Bestandsprüfungen

Die Umsetzung erfasst diese Ergebnisse einmal vor der ersten Änderung und erneut nach Aufgabe 8.

```sh
"$STUNTCAR_PYTHON" -m unittest discover -s voice/tests
"$STUNTCAR_PYTHON" tests/test_localization_catalog.py
"$STUNTCAR_GODOT" --headless --path . --script tools/check_tracks.gd
```

Für die folgenden Godot-Dateien gilt jeweils dieser Aufruf:

```sh
"$STUNTCAR_GODOT" --headless --path . --script tests/run_tests.gd
```

Die Umsetzung ersetzt dabei nur den letzten Dateinamen:

```text
run_tests.gd
run_input_tests.gd
run_voice_tests.gd
run_voice_bridge_tests.gd
run_voice_assist_tests.gd
run_voice_calibration_tests.gd
run_voice_calibration_scene_tests.gd
run_voice_practice_tests.gd
run_voice_practice_scene_tests.gd
run_voice_practice_cues_tests.gd
run_voice_strength_tests.gd
run_voice_auto_range_tests.gd
run_voice_compass_tests.gd
run_keyboard_speed_tests.gd
run_speed_bank_tests.gd
run_track_tests.gd
run_jump_scene_tests.gd
run_stunt_feel_tests.gd
run_stunt_scene_tests.gd
run_selection_tests.gd
run_i18n_tests.gd
```

Erfolg bedeutet null fehlgeschlagene Bedingungen und Prozessende mit Code 0.
Fehlende Sprachmodelle oder Laufzeiten stehen als Einschränkung im Bericht. Sie zählen nicht als bestandene Prüfung.

## Aufgabe 9: Spielversuche und Abschluss der ersten Ausbaustufe

**Dateien:** Ändern `README.md`, `docs/voice-stunts.md`; neu `docs/untere-hilfestufen-abnahme.md`.
Die README-Datei enthält derzeit fremde Änderungen. Die Umsetzung ergänzt nur die betroffenen Absätze und erhält deren übrigen Inhalt.

**Eingang:** Erfolgreiche automatische Prüfungen aus Aufgabe 8.
**Ausgang:** Verständliche Beschreibung und Bericht über tatsächliche Spielversuche.

- [ ] Beschreibe in den Spielhinweisen den Unterschied zwischen „Sehr leicht“ und „Leicht“.
- [ ] Beschreibe die leise Rufübung, die Tempobefehle und die notwendige neue Eingabe vor jeder Kurve.
- [ ] Kennzeichne die weiterhin vorgegebene Sprungbahn. Behaupte keine geprüfte Mindestgeschwindigkeit für Sprünge.
- [ ] Erprobe beide Stufen mit Tastatur und Sprache auf den vorhandenen Strecken.
- [ ] Erprobe leise Laute in angenehmer Lautstärke ohne vorherige laute Probe. Prüfe Raumgeräusch, längere Laute und normale Sprechpausen.
- [ ] Erprobe volle Beschleunigung in einer freigegebenen Kurve. Prüfe, ob Schlingern, Hilfe und nächster Kurvenhinweis verständlich bleiben.
- [ ] Erfasse Personen, Geräte und Bedingungen nur entsprechend den tatsächlich durchgeführten Versuchen. Bewerte keine ungetestete Zielgruppe als erfolgreich geprüft.
- [ ] Halte noch offene Erprobungen ausdrücklich fest, falls Stefan oder andere Testpersonen dafür noch nicht verfügbar sind.
- [ ] Prüfe den Textkatalog und die geänderten Dokumente. Wiederhole Fahrtests nur nach Änderungen an Regeln oder Parametern.
- [ ] Speichere die Dokumentation als eigenen Commit: `Untere Hilfestufen und ihre Erprobung dokumentieren`.

Die technische Umsetzung und die menschliche Erprobung erhalten getrennte Ergebnisse.
Ein Agent darf eine erfolgreiche Mikrofonprobe oder einen Spielversuch nicht aus künstlichen Eingaben ableiten.
Die erste Ausbaustufe gilt erst nach den erforderlichen Spielversuchen als vollständig erprobt.

## Selbstprüfung des Plans

| Vorgabe aus dem Entwurf | Aufgabe |
|---|---|
| Genau zwei untere Stufen; Auswahl speichern | 1, 5 |
| Eine Eingabe pro Kurve; keine automatische Folgekurve | 1, 2, 4, 8 |
| Sehr leicht gleicht Richtung aus; Leicht verlangt richtige Richtung | 1, 5 |
| Leise Laute ohne laute Kalibrierung | 3, 4, 6, 9 |
| Endliche Eingabebereiche und keine Rettung nach Absturz | 1, 2, 8 |
| Tempobefehle behalten ihre Bedeutung | 2, 4, 5 |
| Sichere Kurve trotz voller Beschleunigung | 2, 7, 8 |
| Sichtbare Wirkung ohne Pflicht zu schnellen Korrekturen | 2, 7, 9 |
| Dauergeräusch und Tastendauer übernehmen keine Folgekurve | 1, 4, 5 |
| Pause, Neustart, Gerätewechsel und Landung | 4, 5, 6, 7 |
| Bestehende Sprungbahn und Streckendateien bleiben erhalten | 2, 8, 9 |

Die Selbstprüfung kontrolliert zusätzlich Schnittstellennamen, Aufgabenabhängigkeiten und alle neuen Testdateien.
Die Planung führte keine Spieltests aus. Die Testbefehle beschreiben die spätere Umsetzung.

## Übergabe zur späteren Umsetzung

Die Aufgaben folgen der Reihenfolge 1 bis 9. Mehrere Aufgaben verändern dieselben Dateien und brauchen dieselben Schnittstellen.
Ich empfehle deshalb die Umsetzung in dieser Unterhaltung mit `superpowers:executing-plans`.
Eine unabhängige Abschlussprüfung folgt vor der Übergabe der fertigen Änderung.
Alternativ kann Stefan einzelne Aufgaben durch getrennte Agenten mit einer Prüfung nach jeder Aufgabe ausführen lassen.
Dieser Plan startet keine Umsetzung. Stefan prüft zuerst den Plan und wählt danach die Ausführung.

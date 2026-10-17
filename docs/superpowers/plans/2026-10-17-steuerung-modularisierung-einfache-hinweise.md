# Umsetzungsplan für die gemeinsame Steuerung und einfache Hinweise

> Für ausführende Agenten: Nutze `superpowers:executing-plans` für die Umsetzung in dieser Sitzung. Bei ausdrücklich gewählter Arbeit mit Unteragenten nutze `superpowers:subagent-driven-development`. Arbeite die Aufgaben einzeln ab. Die Kontrollkästchen dokumentieren den Fortschritt.

**Ziel:** Ein wiederverwendbares Steuerungsmodul verbindet Tasten und vorhandene Sprachbefehle mit beiden Fahrmodellen und einfachen, ehrlichen Spielhinweisen.

**Aufbau:** Der gemeinsame Kern kennt Eingaben, Aktionen, Hilfestufen und Ausführungsbestätigungen. Die Stuntcar-Anbindung kennt Kurven, Tempo, Fahrhilfen und die tatsächliche Wirkung. Eine Anzeige stellt die Hinweise dar und löst selbst keine Aktion aus.

**Technik:** Godot 4.5.1, GDScript, vorhandene Wörterbücher als Nachrichten, vorhandene Python-Sprachverbindung. Keine neue Laufzeit und keine neue Bibliothek.

**Grundlage:** [Entwurf](../specs/2026-10-17-gemeinsame-steuerungsschnittstelle-design.md), insbesondere Abschnitte 2 bis 14 und 20. [Astra-Review](../reviews/2026-10-17-steuerungskonzept-astra.md). Ausgangsstand: `9bf9879`.

**Status:** Plan zur Prüfung durch Stefan. Noch keine Umsetzung. Dieser Auftrag erstellt nur dieses Dokument.

## Umfang der ersten Lieferung

Die Lieferung setzt die vorbereitende Trennung und den ersten nutzbaren gemeinsamen Steuerungsweg um.
Sie enthält einen kleinen Regelkern, den die vorhandene Rufhilfe verwenden kann.
Sie benötigt keine Vorausberechnung.

Enthalten sind:

- Ein Godot-Modul ohne Wissen über Stuntcar.
- Ein gemeinsamer Eingang für die bisherigen Fahrbefehle aus Tasten und Sprache.
- Ein unveränderter Weg für Menüs, Übungen, Pause und Einstellungen.
- Eine tatsächliche ausdrückliche Richtung in beiden Fahrmodellen.
- Beginn, Verlängerung und Ende gehaltener Tempoeingaben.
- Einzelaktionen und gemeinsame Anweisungen mit mehreren Aktionen im Vertrag.
- Einfache Richtungs- und Tempohinweise mit ihrer jeweiligen Grundlage.
- Die vorhandene absichtliche Rufhilfe auf „Sehr leicht“.
- Ein kleines zweites Spielmodell als Gegenprobe für die Wiederverwendung.

Nicht enthalten sind:

- Vorausberechnungen, Referenzfahrten, Suche nach ganzen Fahrten und neue automatische Levelprüfung.
- Neue automatische Tempoergänzungen aus einer unbewiesenen Tempogrenze.
- Frei wählbare Bremsstärken wie `amount: 0.3`, die das heutige Modell nicht anbietet.
- Neue Spracherkennung, gesprochene Kombinationsphrasen oder Gestenerkennung.
- Eine neue sichtbare Hilfestufe „Direkt“.
- Veröffentlichung eines Pakets, Änderungen an Landschaften oder ein neues vollständiges Spiel.

Der Vertrag unterstützt ausdrückliche Kombinationen bereits in dieser Lieferung.
Die bestehende Spracherkennung liefert zunächst weiter einzelne Befehle.
Eine spätere Kombinationsphrase muss bis zu ihrem vollständigen Ende warten. Sie erhält einen eigenen Auftrag.
Zwei getrennte Nachrichten werden nicht nachträglich zu einer gemeinsamen Anweisung.

Die bisherigen physischen Fahrhilfen dürfen erhalten bleiben, soweit sie ausdrücklichen Aktionen nicht widersprechen.
Die Anbindung führt sie im aktiven Hilfsprofil auf.
Neue Tempoergänzungen durch den Auswahlkern bleiben in Stuntcar zunächst ausgeschaltet.
Die allgemeine Auswahl solcher Ergänzungen erhält dennoch Vertragstests mit einer kleinen Spielanbindung.

## Globale Vorgaben

- „Eine erkannte Anweisung nach links bleibt eine Anweisung nach links.“
- „Eine schlechte Bewertung allein darf die Anweisung nicht aufheben.“
- „Eine abgelehnte ausdrückliche Anweisung wird nicht nachträglich zu `activate`.“
- „Ein Hilfsfenster allein erlaubt keine neue Aktion.“
- „Eine unbekannte Grenze ist weder null noch eine allgemeine Freigabe.“
- Für Nachrichten gilt `schema_version: 1`. Für das Regelprofil gilt `stuntcar_rules_v1`.
- Die vorhandenen Hilfestufen heißen `very_easy` und `easy`.
- Hinweise verwenden `assessment_method: rules_only` und `horizon_ms: 0`.
- `unknown` verwendet `utility: null`. Nutzen, Aktionsstärke und Erkennungssicherheit bleiben getrennt.
- Kombinationen starten gemeinsam oder gar nicht. Eine Bewertung verändert keine Fahrt.
- Das Modul erhält keine Abhängigkeit von `scripts/vehicle`, `scripts/track`, Mikrofonen oder Stuntcar-Textschlüsseln.
- Alle Berichte an Stefan verwenden kurze deutsche Sätze.
- Die Spieloberfläche bleibt englisch. Neue Texte stehen in `locales/en.po`.
- Bestehende Einstellungen, Tastenbelegungen und der gespeicherte Godot-Datenordner bleiben erhalten.
- Unverwandte Landschaftsänderungen bleiben außerhalb der Commits dieses Plans.
- Die Umsetzung benötigt einen isolierten Arbeitsstand. Nutze dafür erst bei Ausführung die Fähigkeit `superpowers:using-git-worktrees`.
- Kein Zwischenschritt mit alter Richtungskorrektur gilt als fertige vertragskonforme Lieferung.

## Besondere Prüffälle

Diese fünf Fälle gehören ausdrücklich zu den jeweiligen Aufgaben:

| Fall | Erwartung | Aufgabe |
|---|---|---|
| Eine alte Verlängerung trifft nach einem Gegenbefehl oder nach `end` ein. | Die beendete Aktion bleibt beendet. | 2 und 5 |
| Eine Quelle fällt zwischen zwei Physikschritten aus. | Ihre gehaltenen Aktionen enden. Andere Quellen behalten ihre eigenen Enden. | 3 und 7 |
| Der Spieler hält zwei Tasten, die dieselbe Aktion auslösen, und lässt nur eine los. | Die andere Taste bleibt wirksam. | 3 und 7 |
| Ein Hinweis und ein neuer Hilfszustand stammen aus verschiedenen Spielschritten. | Vor einer Ergänzung gilt die aktuelle Lage. Die ausdrückliche Aktion geht nicht verloren. | 5 und 6 |
| Ein neues Fahrmodell macht den gespeicherten Bericht ungültig. | Das Spiel verlangt einen neu erzeugten Bericht. Kein Test umgeht die Freigabe. | 4 und 9 |

## Dateigrenzen und Zuständigkeiten

Neue Dateien sind geplante Ergebnisse. Sie existieren bei Erstellung dieses Plans noch nicht.

| Datei | Verantwortung |
|---|---|
| `addons/accessible_controls/core/contract.gd` | Nachrichten, Kataloge und Antworten prüfen. |
| `addons/accessible_controls/core/input_source.gd` | Eindeutige Eingabekennungen und fortlaufende Änderungen erzeugen. |
| `addons/accessible_controls/core/input_ledger.gd` | Doppelte, alte, beendete und ersetzte Eingaben behandeln. |
| `addons/accessible_controls/core/selector.gd` | Eine passende Aktion nach Anweisung und Hilfsprofil auswählen. |
| `addons/accessible_controls/core/controller.gd` | Eingaben sammeln und den Vertrag mit einer Spielanbindung abwickeln. |
| `addons/accessible_controls/core/game_port.gd` | Die öffentliche Grenze zur Spielanbindung festlegen. |
| `addons/accessible_controls/README.md` | Einbindung, Ablauf und Grenzen des Moduls erklären. |
| `scripts/control/stuntcar_actions.gd` | Den ehrlichen Aktionskatalog und die Übersetzung in Fahrzeugbefehle liefern. |
| `scripts/control/stuntcar_port.gd` | Ausführung, aktive Mitglieder, Fristen und aktuellen Spielkontext verwalten. |
| `scripts/control/stuntcar_hints.gd` | Richtungs- und Tempohinweise aus bestehenden Daten erzeugen. |
| `scripts/control/stuntcar_rules.gd` | Die einfachen Vorschläge bewerten. |
| `scripts/control/keyboard_source.gd` | Stuntcar-Tasten in gemeinsame Anweisungen übersetzen. |
| `scripts/control/voice_source.gd` | Vorhandene Fahrwörter und gültige Rufsignale übersetzen. |
| `scripts/ui/hint_presenter.gd` | Hinweis und Bestätigung als vorhandene Texte darstellen. |
| `tests/control/fixtures.gd` | Vollständige Testnachrichten und Testkataloge erzeugen. |
| `tests/control/fake_game_port.gd` | Aufrufe und Ausführungen für die Kerntests erfassen. |
| `tests/control/platform_port.gd` | Ein kleines zweites Spielmodell mit Bewegung und Sprung bereitstellen. |

`command_router.gd` bleibt für Spielzustand, Menüs, Einstellungen und Versuche zuständig.
Er delegiert Fahrbefehle künftig an den gemeinsamen Steuerungsweg.
`voice_bridge.gd` behält Prozessstart, Verbindung, Reihenfolge der Transportnachrichten und Zustandswechsel der Sprachverbindung.
Das Modul startet weder Python noch ein Mikrofon.
Ein Editor-Plugin, eine automatische Registrierung und ein globales Objekt sind nicht erforderlich.

## Gemeinsame technische Entscheidungen

### Schnittstellen des Moduls

Alle folgenden Klassen erweitern `RefCounted`. Die Typen bezeichnen GDScript-Typen.

| Klasse | Methoden |
|---|---|
| `Contract` | `static validate_catalog(catalog: Dictionary) -> Array[String]`; `static validate_intent(intent: Dictionary, catalog: Dictionary) -> Array[String]`; `static validate_assessment(answer: Dictionary, catalog: Dictionary) -> Array[String]`. |
| `InputSource` | `_init(source_id: String)`; `begin(session_id: String, kind: String, actions: Array[Dictionary], now_ms: int, ttl_ms: int, opportunity_id = null) -> Dictionary`; `update(control_id: String, actions: Array[Dictionary], now_ms: int, ttl_ms: int) -> Dictionary`; `end(control_id: String, now_ms: int, ttl_ms: int) -> Dictionary`; `reset() -> void`. |
| `InputLedger` | `reset(session_id: String) -> void`; `accept(intent: Dictionary, now_ms: int) -> Dictionary`; `retire(control_id: String) -> void`; `retire_members(control_id: String, action_ids: Array[String]) -> void`; `retire_source(source_id: String) -> void`. |
| `Selector` | `static choose(intent: Dictionary, answer: Dictionary, profile: Dictionary) -> Dictionary`. |
| `GamePort` | `describe_actions() -> Dictionary`; `assess(request: Dictionary) -> Dictionary`; `apply(decision: Dictionary, now_ms: int) -> Dictionary`; `cancel(request: Dictionary, now_ms: int) -> Dictionary`. |
| `Controller` | `_init(port, profile: Dictionary)`; `begin_session(session_id: String) -> void`; `submit(intent: Dictionary) -> void`; `step(now_ms: int) -> Array[Dictionary]`; `read_hints(now_ms: int) -> Array[Dictionary]`; `suspend(reason: String, now_ms: int) -> void`; `lose_source(source_id: String, now_ms: int) -> void`. |

`GamePort` bietet keine eigene Bewegung. Nicht überschriebene Methoden liefern einen begründeten Fehler.
`Controller` erhält den Katalog von `describe_actions` und prüft dessen Fassung.
`cancel` erhält `session_id`, `scope` und `reason`. `scope` ist `execution`, `source` oder `session`.
Die beiden ersten Formen verlangen zusätzlich `execution_id` oder `source_id`.
Diese lokalen Sammelabbrüche nutzen dieselbe Aufgabe `cancel`. Sie erzeugen keine zusätzliche Spielaktion.
`step` arbeitet nur Eingaben ab. Es bewegt das Spielmodell nicht.
`read_hints` fragt dieselbe Spielanbindung ohne Eingabe ab. Es ruft niemals `apply` auf.
Das übergebene Profil enthält `profile_id`, `allow_additions` und `allow_activate`. Der Kern prüft diese Angaben statt Stuntcar-Stufennamen.
`assess` erhält `session_id`, `now_ms`, `profile`, `intent` und `query_only`. Bei einer reinen Hinweisabfrage ist `intent: null` und `query_only: true`.
Eine Entscheidung enthält Sitzung, ursprüngliche Anweisung, ausgewählte Aktionen und die Bewertungsreferenz mit Revision und Spielschritt.
Die Anbindung vergleicht `profile_id` mit ihrem tatsächlich aktiven Hilfsprofil. Ein Unterschied erlaubt keine Ergänzung oder Rufauswahl.
`Selector.choose` liefert `selected`, `explicit_only`, `no_action` oder `rejected` sowie die unveränderten gewählten Aktionen.
`InputLedger.accept` liefert `accepted`, `duplicate`, `stale` oder `rejected` mit Grund.
Ein neuer Gegenbefehl beendet nur die widersprechenden Mitglieder. Er beendet nicht automatisch andere Mitglieder derselben älteren Anweisung.
`retire_members` verhindert, dass eine alte Verlängerung diese ersetzten Mitglieder wieder startet.

Die Steuerung besitzt Eingabeschlange, Eingabereihenfolge und Zuordnung von Eingaben zu Ausführungen.
`InputLedger` unterscheidet Sitzung, Quelle und `control_id`. Eine Quelle darf keine fremde Eingabe verlängern oder beenden.
`Controller.step` prüft alle Anweisungen eines Spielschritts vor ihrem Start auf gegensätzliche Gruppen.
Eine betroffene gemeinsame Anweisung startet vollständig nicht. Sie darf keinen unbemerkten Teilstart erzeugen.
Die Spielanbindung besitzt die tatsächlich aktiven Aktionen, deren Enden und deren Wirkung im Modell.
Ein Abbruch der ganzen Sitzung löscht auch gespeicherte Lenkaufträge und aktive Hilfe.
Er löscht nicht still das zuvor ausdrücklich gespeicherte Zieltempo. Das Modell bleibt während der Pause stehen.
Eine Bestätigung nennt `execution_id` und das bestätigte Ende jedes Mitglieds.
Der generische Kern berechnet die Auswahl nach einer unveränderten Ausgangslage. Die Anbindung prüft diese Lage beim Start erneut.
Die Steuerung darf ein Ende anfordern. Sie berechnet keine eigene Fahrzeugwirkung.

### Erste Stuntcar-Aktionen

| Kennung | Art | Tatsächliche Wirkung |
|---|---|---|
| `turn_left`, `turn_right` | Impuls | Speichert einen gerichteten Lenkwunsch für das aktuelle Kurvenfenster. Er wirkt ab dem Kurvenbeginn und endet am Fensterende. Ohne passendes Fenster wirkt eine kurze manuelle Lenkung. |
| `speed_up`, `speed_down` | Impuls | Nutzt `change_speed` mit der vorhandenen Bedeutung des Parameters `strength`. Das gespeicherte Zieltempo darf danach bestehen bleiben. |
| `pedal_up`, `pedal_down` | Begrenzt, haltbar | Nutzt während der bestätigten Dauer `keyboard_speed` mit Richtung +1 oder −1. Das Ende beendet die Eingabe, nicht das gespeicherte Zieltempo. |

Die Ausschlussgruppen heißen `steering` und `speed`.
Ein Richtungsimpuls darf keine entgegengesetzte Kurvenfreigabe erzeugen.
Ein neuer Richtungsimpuls ersetzt den gespeicherten älteren Lenkwunsch.
Ein physisch nicht unterstützter Eingriff im Flug erhält eine begründete Nichtverfügbarkeit.
Stuntcar bietet keinen frei auslösbaren `jump` und keine scheinbare Bremsstärke `amount` an.

Für die erste Umsetzung gelten diese ausdrücklich vorgeschlagenen Betriebswerte:

- Allgemeine Eingabefrist: 250 Millisekunden ab Erfassung durch die Godot-Eingabeanbindung.
- Frische Tastenzustände: spätestens nach jeweils 50 Millisekunden.
- Bestätigte Pedaldauer: 150 Millisekunden, mit `max_update_gap_ms: 150` und `max_duration_ms: 150`.
- Manuelle Lenkung ohne Kurvenfenster: 500 Millisekunden.
- Gespeicherter Lenkwunsch: spätestens nach zehn Sekunden oder früher am Ende seines Kurvenfensters beenden.
- Die bestehende Dauer der frühen, passenden und späten Kurvenhilfe bleibt sonst unverändert.

Diese Werte sind Planentscheidungen. Der Entwurf gab dafür noch keine vollständigen Betriebswerte vor.
Die Spielanbindung begrenzt eine Verlängerung zusätzlich durch ihre bestätigte Dauer und das Hilfsfenster.
Eine einmalige Pedalaktion über mehr als 150 Millisekunden bietet dieser erste Katalog nicht an.
Die bewusste gehaltene Taste verlängert ihre Aktion regelmäßig. Ein längerer einzelner Zeitbefehl benötigt später eine eigene Katalogbedeutung.
Die Zeitquelle ist `main.control_clock: Callable`. `main.control_now_ms() -> int` liest diese Funktion.
Im Spiel liefert sie die seit Sitzungsbeginn vergangene stetige Zeit aus `Time.get_ticks_msec()`.
Tests setzen dieselbe Zeit ausdrücklich. Sie warten nicht auf echte Zeit.

Bei Sprachbefehlen bezeichnet die Erfassung den Empfang des fertig erkannten Ereignisses in Godot.
Sie bezeichnet nicht den Beginn des aufgenommenen Tons.
Die bestehende Prüfung von `epoch`, Transportnummer und Rufkontext bleibt deshalb zusätzlich bestehen.
Diese Lieferung verspricht keine neue Grenze für die Verzögerung der Spracherkennung.

## Aufgabe 1 Den Modulvertrag mit einer unabhängigen Spielanbindung festlegen

**Dateien:** Neu: `addons/accessible_controls/core/{contract,input_source,game_port}.gd`, `tests/control/{fixtures,fake_game_port}.gd`, `tests/control/run_contract_tests.gd`.

**Eingang:** Der Vertrag aus den Abschnitten 3 bis 6 des Entwurfs.

**Ergebnis:** Die oben festgelegten Methoden von `Contract`, `InputSource` und `GamePort`.
Die Testhilfe liefert `catalog() -> Dictionary`, `intent(overrides: Dictionary = {}) -> Dictionary`, `assessment(proposal_overrides: Dictionary = {}, frame_overrides: Dictionary = {}) -> Dictionary` und `profile(id: String) -> Dictionary`.
`assessment` ändert mit dem ersten Argument den ersten Vorschlag und mit dem zweiten Argument den Rahmen.
Der Testkatalog beschreibt die benutzten Testaktionen einschließlich einer tatsächlich unterstützten Bremse. Er ist nicht der Stuntcar-Katalog.
Jede Hilfe liefert vollständige Daten nach Vertragsfassung 1. Keine Hilfe verweist auf Stuntcar.

- [ ] Schreibe fehlerschlagende Fälle `test_bad_version`, `test_unknown_action`, `test_nonfinite_utility`, `test_unknown_has_null_utility` und `test_source_revisions`.

```gdscript
check(not Contract.validate_intent(F.intent({"schema_version": 2}), F.catalog()).is_empty(), "Unbekannte Fassung ablehnen")
check(not Contract.validate_assessment(F.assessment({"utility": INF}), F.catalog()).is_empty(), "Unendlicher Nutzen ist ungültig")
check(source.update(id, actions, 50, 250).control_revision == 2, "Eine Änderung erhält die nächste Nummer")
```

- [ ] Starte `.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/control/run_contract_tests.gd`. Erwartung vor der Umsetzung: fehlende Moduldateien oder konkrete fehlgeschlagene Bedingungen.
- [ ] Implementiere die drei Klassen und die Testhilfe. Nutze benannte Konstanten für erlaubte Arten, Phasen und Fassungen. Prüfe Einheiten und Parameter nach dem übergebenen Katalog.
- [ ] Ergänze `test_atomic_request_shape`: Zwei Mitglieder derselben Ausschlussgruppe sind widersprüchlich. Unterschiedliche Gruppen bleiben als eine Anweisung erhalten.
- [ ] Führe denselben Prüflauf erneut aus. Erwartung: Rückgabewert 0 und keine fehlgeschlagene Bedingung.
- [ ] Sichere nur die Dateien dieser Aufgabe mit dem Commit `feat: add reusable control contract`.

## Aufgabe 2 Auswahl und Eingabereihenfolge im gemeinsamen Kern umsetzen

**Dateien:** Neu: `addons/accessible_controls/core/{input_ledger,selector,controller}.gd`, `tests/control/run_controller_tests.gd`. Ergänzen: `tests/control/{fixtures,fake_game_port}.gd`.

**Eingang:** Die Methoden aus Aufgabe 1. `FakeGamePort` speichert `applied`, `cancelled` und die Zahl der Aufrufe.

**Ergebnis:** Die festgelegten Methoden von `InputLedger`, `Selector` und `Controller`. Die Steuerung führt höchstens einen bewussten Eingabeversuch je `event_id` aus.
Ein interner Versuch nach `stale` verwendet dieselbe Eingabe, ohne einen zweiten Eingang zu erzeugen.

- [ ] Schreibe die Fälle `test_explicit_left_beats_better_right`, `test_easy_addition`, `test_direct_has_no_addition`, `test_activate_only_very_easy`, `test_unknown_is_not_zero` und `test_missing_rating_uses_explicit_only`.

```gdscript
var choice = Selector.choose(left_intent, right_better_answer, F.profile("very_easy"))
check(choice.actions[0].action_id == "turn_left", "Die ausdrückliche Richtung bleibt erhalten")
check(Selector.choose(call_intent, answer, F.profile("easy")).status == "no_action", "Leicht erlaubt keine freie Rufauswahl")
```

- [ ] Ergänze `test_old_revision_after_newer_update`, `test_update_after_end`, `test_update_after_replacement`, `test_opposite_keeps_other_member` und `test_same_step_opposites`. Nutze ausdrücklich Revision 3 vor Revision 2 sowie ein späteres `end` mit Revision 4.
- [ ] Ergänze `test_open_without_addition_vs_crashed_addition`. Die offene Originalaktion erhält `unknown`. Die Absturzergänzung erhält −0,9. Erwartung: `explicit_only`; beim Ruf `no_action`.
- [ ] Starte `.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/control/run_controller_tests.gd`. Belege den Fehler vor der Umsetzung.
- [ ] Implementiere Reihenfolge, Auswahl und die interne Neuauswertung nach `stale`. Nach einer zweiten Lageänderung folgt die ausdrückliche Anweisung ohne Ergänzung. Ein `activate` startet dann nichts.
- [ ] Ergänze `test_conflicting_pair_has_no_partial_start`: Ein Konflikt beim Lenken darf die Bremse derselben gemeinsamen Anweisung nicht einzeln starten.
- [ ] Ergänze `test_duplicate_impulse`, `test_expired_event`, `test_foreign_session`, `test_suspend_cancels_all`, `test_read_hints_never_applies` und `test_cancel_one_source`. Die pausierte Eingabe darf nach Fortsetzung nicht erneut wirken.
- [ ] Wiederhole den Prüflauf. Erwartung: Rückgabewert 0. Sichere den Commit `feat: select control actions without overriding player intent`.

## Aufgabe 3 Tasten und vorhandene Sprachbefehle übersetzen

**Dateien:** Neu: `scripts/control/{keyboard_source,voice_source}.gd`, `tests/control/run_source_tests.gd`. Vorhandene Grundlage: `scripts/input/{keyboard_controls,voice_bridge,call_profile,voice_strength}.gd`.

**Eingang:** `InputSource` aus Aufgabe 1. Die vorhandenen Tastenbelegungen und bereits geprüften Sprachpakete.

**Ergebnis:** `KeyboardSource.capture(code: int, pressed: bool, now_ms: int) -> Array[Dictionary]`, `refresh(now_ms: int) -> Array[Dictionary]`, `reset(require_release: bool = true) -> void`.
`VoiceSource.command(packet: Dictionary, now_ms: int) -> Dictionary` und `call(packet: Dictionary, context: Dictionary, now_ms: int) -> Dictionary`.
Beide Quellen erhalten die Sitzung und den Katalog bei `configure(session_id: String, catalog: Dictionary) -> void`.
`KeyboardSource._init(bindings: Array[int])` erhält die gespeicherten Tasten.
`KeyboardSource.rebind(bindings: Array[int], now_ms: int) -> Array[Dictionary]` beendet ihre bisherigen gehaltenen Eingaben und übernimmt die neue Belegung.
`reset` verlangt das Loslassen, behält aber die laufenden Kennungszähler derselben Sitzung.
`InputSource` setzt Sitzung, Quelle und eine fortlaufende Nummer in jede neue Kennung. Eine Pause darf keine alte Kennung erneut verwenden.

- [ ] Schreibe die Fälle `test_key_repeat_is_not_new_impulse`, `test_arrow_alias_keeps_its_own_control`, `test_release_one_of_two_same_action_keys` und `test_refresh_after_50_ms`.
- [ ] Schreibe `test_voice_maps_exact_strength`, `test_menu_word_is_not_drive_action`, `test_rejected_word_never_becomes_call` und `test_call_requires_matching_device_and_window`.
- [ ] Starte `.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/control/run_source_tests.gd`. Belege den Fehler.
- [ ] Implementiere die Übersetzung. Lenkung verwendet weiterhin die bewusste Druckkante als Impuls. Pedale erhalten je physischer Taste eine eigene `control_id` und Verlängerung.
- [ ] Übernimm die Rufprüfung aus `CommandRouter.submit_call`: passendes Gerät, gültiges Profil, Dauer, Pegel, `has_command: false`, Sitzung und Hilfsfenster. Ändere ihre vorhandenen Schwellen nicht.
- [ ] Ergänze `test_source_loss_stops_refresh`, `test_keys_held_before_pause_need_release` und `test_pause_does_not_reuse_control_id`. Ein Quellreset verlangt vor einem neuen Tastendruck das Loslassen der bereits gehaltenen Taste.
- [ ] Wiederhole den Godot-Lauf. Führe außerdem `python3 -m unittest voice.tests.test_protocol voice.tests.test_call_detector` aus. Beide müssen mit Rückgabewert 0 enden.
- [ ] Sichere den Commit `refactor: normalize keyboard and voice driving input`. Schalte die neuen Quellen noch nicht in `main.gd` ein.

## Aufgabe 4 Die ausdrückliche Richtung in beiden Fahrmodellen erhalten

**Dateien:** Ändern: `scripts/vehicle/{drive_model,spatial_drive_model,curve_assist,assist_profile}.gd`, `scripts/vehicle/spatial/surface_motion.gd`. Neu: `tests/control/run_direction_tests.gd`. Anpassen: `tests/run_{curve_assist,assisted_drive,assist_selection,assist_feedback,keyboard_speed,voice_assist}_tests.gd`, `tests/spatial/test_assists.gd`, `tests/spatial/full_drive_cases.gd` und `tracks/reports/06_stuntlabor.json`.

**Eingang:** Der gerichtete Lenkwunsch aus dem Katalog. Die bestehenden Hilfsfenster bleiben die Zeitgrundlage der Führungshilfe.

**Ergebnis:** Beide Modelle bieten `set_steering_request(direction: int, expires_at_s: float) -> bool` und `clear_steering_request() -> void`.
`request_turn` bleibt zunächst eine Weiterleitung für bestehende Aufrufer. Es darf die Richtung nicht mehr ändern.

- [ ] Schreibe `test_left_and_right_on_both_profiles` für beide Modelle. Starte auf einer ebenen Geraden mit 22 Metern je Sekunde. Prüfe die tatsächliche Änderung nach 30 Schritten mit 1/60 Sekunde.
- [ ] Schreibe `test_wrong_curve_input_is_not_corrected`, `test_correct_curve_keeps_guidance`, `test_new_opposite_replaces_old` und `test_direction_outside_window_is_manual`.
- [ ] Starte `.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/control/run_direction_tests.gd`. Die heutige Richtungsumdeutung muss mindestens einen Fall scheitern lassen.
- [ ] Trenne in `CurveAssist` die Hilfsberechtigung von der ausdrücklichen Richtung. Nur eine passende gewählte Richtung darf die Kurvenführung aktivieren. Eine falsche Richtung bleibt ein ausführbarer manueller Lenkwunsch.
- [ ] Ergänze `requested_direction` und sein Ende in beiden Modellen. Setze beide Werte beim Modellreset zurück. Erhöhe `AssistProfile.VERSION` auf 2 und liefere die aktuelle Profilfassung im Antwortkontext. Vor einer passenden Kurve darf der Katalog den Wunsch speichern. Während der Kurve wirkt die gewählte Richtung. Ein Gegenbefehl ersetzt den gespeicherten Wunsch.
- [ ] Nutze für die manuelle Bewegung zunächst `manual_turn_rate_rad_s: deg_to_rad(65.0)` als eigenen Profilwert. Das ist der bereits vorhandene Wert für die manuelle Sprungkorrektur im bisherigen Modell. Er ist ein Anfangswert für die neue Abnahme.
- [ ] Im bisherigen Modell verändert die manuelle Richtung den Kurs mit diesem Wert und dem vorhandenen Faktor für rollende Lenkung. Die automatische Führung darf dabei keinen entgegengesetzten Kurs setzen.
- [ ] Im räumlichen Modell erhält `Surface.step` die gewählte Richtung zusätzlich zur Führung. Ohne passende Führung wirkt eine gerichtete Seitenbeschleunigung `direction × min(80, forward_speed × manual_turn_rate_rad_s)`. Behalte Schwerkraft und Krümmung bei. Nutze die bisherige Spurführung nur bei passender Richtung oder ohne ausdrücklichen Lenkwunsch auf einer Geraden.
- [ ] Passe die bisherigen Prüfungen der falschen Richtung an. Reguläre Vollfahrten senden künftig die richtige Richtung auf beiden Hilfestufen. Falsche Richtungen erhalten eigene Fälle ohne verlangten Zieleinlauf.
- [ ] Wiederhole die neue Richtungsprüfung und `tests/run_assisted_drive_tests.gd` sowie `tests/spatial/test_surface_motion.gd`. Kein Test darf nur `last_command` prüfen.
- [ ] Erzeuge den vorhandenen Stunt-Bericht mit `tools/spatial/check_drives.gd` neu. Nutze die Anweisung unter Aufgabe 9. Die alte Prüfsumme darf nicht weiter gelten.
- [ ] Sichere den Commit `fix: preserve explicit steering direction in both drive models`. Dieser Zwischenstand ist noch keine Freigabe des gesamten Moduls.

## Aufgabe 5 Die tatsächliche Ausführung an den gemeinsamen Vertrag anbinden

**Dateien:** Neu: `scripts/control/{stuntcar_actions,stuntcar_port}.gd`, `tests/control/run_stuntcar_port_tests.gd`. Ergänzen: die beiden Fahrmodelle aus Aufgabe 4.

**Eingang:** `GamePort` und die Bestätigungsformen aus Aufgabe 1. Die gerichteten Modellmethoden aus Aufgabe 4.

**Ergebnis:** `StuntcarPort._init(model)` implementiert die vier Methoden von `GamePort`.
Zusätzlich bietet es `advance(delta: float, now_ms: int) -> void`, `reset(session_id: String) -> void` und `context(now_ms: int) -> Dictionary`.
Beide Fahrmodelle erhalten `set_active_pedal(direction: int) -> void`. Der Wert ist −1, 0 oder +1 und startet selbst keine Tempoaktion.
`StuntcarActions.catalog() -> Dictionary` beschreibt die oben festgelegten sechs Aktionen samt Fassungen.
`StuntcarActions.control_profile(model) -> Dictionary` liefert `profile_id` aus Stufe und aktueller Profilfassung.
Bei `very_easy` sind beide Erlaubnisse wahr. Bei `easy` ist nur `allow_additions` wahr.
Der spätere reine Direktbetrieb verwendet beide Werte als falsch und bleibt in dieser Lieferung eine Vertragsprobe.

- [ ] Schreibe `test_catalog_describes_target_changes`, `test_no_fake_jump_or_brake_amount`, `test_all_or_nothing_start`, `test_duplicate_apply` und `test_stale_apply_has_no_effect`.
- [ ] Schreibe `test_members_have_separate_ends`, `test_pedal_timeout`, `test_end_keeps_stored_target`, `test_opposite_retires_old_member` und `test_cancel_only_matching_execution`.
- [ ] Starte `.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/control/run_stuntcar_port_tests.gd`. Belege den Fehler.
- [ ] Implementiere zuerst eine vollständige Vorprüfung der Kombination. Erst danach ändere das Modell oder den Bestand aktiver Mitglieder. Ein fehlgeschlagenes Mitglied darf keine Teilwirkung hinterlassen.
- [ ] `apply` speichert Impulse höchstens einmal. Es merkt `stale` nicht als ausgeführten Impuls. Eine zulässige interne Wiederholung kann dieselbe Eingabe deshalb noch ausführen.
- [ ] `advance` beendet fällige Mitglieder, setzt `set_active_pedal` auch bei neutralem Pedal und nutzt `keyboard_speed` höchstens einmal je Modellschritt. Zwei Quellen derselben Pedalrichtung verdoppeln die Wirkung nicht. Entgegengesetzte Pedale desselben Schritts erzeugen keine neue Tempowirkung.
- [ ] Erhalte aktive ausdrückliche Pedale gegenüber automatischen Tempoeingriffen. Ein gehaltener Bremsbefehl darf keine automatische Beschleunigung zur Sprungvorbereitung auslösen. Ein gehaltener Gasbefehl darf keine ergänzte Gegenbremse erhalten.
- [ ] Ergänze `test_explicit_brake_blocks_launch_acceleration` und `test_explicit_gas_blocks_extra_brake` in beiden Modellen. Natürliche Beschleunigung durch ein Gefälle gilt dabei nicht als neue Hilfe.
- [ ] Wiederhole den Prüflauf. Erwartung: Rückgabewert 0. Sichere den Commit `feat: execute control actions through the Stuntcar port`.

## Aufgabe 6 Einfache Hinweise und eine kleine Regelbewertung erzeugen

**Dateien:** Neu: `scripts/control/{stuntcar_hints,stuntcar_rules}.gd`, `tests/control/run_hint_rules_tests.gd`. Ergänzen: `scripts/control/stuntcar_port.gd`.

**Eingang:** Bestehende `turn_sign`-Daten, Kurvenfenster, `speed_hint_at`, `verified_speed_hint` und `StuntAssist.limits`. Keine neue Physikberechnung.

**Ergebnis:** `StuntcarHints.read(model, now_ms: int) -> Array[Dictionary]` erzeugt reine Hinweisdaten.
Die Sitzung aktualisiert das Modell und seinen Kontext vor der Abfrage. Die Hinweisabfrage erneuert keine Freigabe und verbraucht keine Hilfe.
`StuntcarRules.assess(model, request: Dictionary, hints: Array[Dictionary], now_ms: int) -> Dictionary` liefert Vertragsfassung 1 und `stuntcar_rules_v1`.

- [ ] Schreibe `test_reading_hints_never_moves_car`, `test_curve_direction_matches_sign`, `test_unknown_speed_is_null` und `test_assist_target_is_not_safe_maximum`.
- [ ] Schreibe `test_tested_sample_requires_matching_condition`, `test_disjoint_ranges_stay_separate`, `test_stale_hint_conditions_are_rechecked` und `test_no_input_never_applies_hint`.
- [ ] Starte `.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/control/run_hint_rules_tests.gd`. Belege den Fehler.
- [ ] Implementiere die Richtung aus denselben Kurvendaten wie die Schilder. Bezeichne feste Hilfswerte ausdrücklich als empfohlenes Hilfstempo. Übernimm geprüfte Einzelwerte nur bei passender Bedingung und Prüfsumme.
- [ ] Liefere unbekannte Minima und Maxima als `null`. Verbinde keine Einzelproben zu einem Bereich. Leite aus einem alten `assisted_tested`-Wert keine stärkere Aussage als dessen bestehenden Prüfbericht ab.
- [ ] Bewerte die passende Richtung mit +0,6 und die bekannte Gegenrichtung mit −0,8. Ohne passende Grundlage gilt `unknown`. Eine belegte fehlende Tempoanforderung darf den passenden Richtungswert auf −0,4 senken.
- [ ] Die allgemeine Regelprüfung unterstützt den Entwurfswert +0,8 für eine tatsächlich belegte passende Kombination. Stuntcar erzeugt in dieser Lieferung keine neue automatische Tempoergänzung. Eine ausdrückliche Kombination bleibt unabhängig davon ausführbar.
- [ ] `StuntcarPort.assess` delegiert hierher. `apply` prüft die erforderlichen aktuellen Bedingungen unmittelbar vor jeder Ergänzung erneut. Eine gleiche Revision allein genügt nicht.
- [ ] Prüfe zusätzlich `test_requested_bad_action_stays_available` und `test_explicit_pair_is_checked_as_pair`. Die Bewertung addiert keine Einzelwerte.
- [ ] Wiederhole den Prüflauf. Sichere den Commit `feat: provide rule-based direction and speed hints`.

## Aufgabe 7 Den neuen Steuerungsweg in die Spielsitzung einsetzen

**Dateien:** Ändern: `scripts/main.gd`, `scripts/input/command_router.gd`. Neu: `tests/control/run_session_control_tests.gd`. Anpassen: `tests/run_input_tests.gd`, `tests/run_keyboard_speed_tests.gd`, `tests/run_voice_assist_tests.gd`, `tests/run_voice_scene_tests.gd`, `tests/run_voice_bridge_tests.gd`.

**Eingang:** Controller aus Aufgabe 2, Quellen aus Aufgabe 3 und Stuntcar-Anbindung aus Aufgabe 5.

**Ergebnis:** Nur dieser Weg führt Fahraktionen aus: Quelle → gemeinsame Anweisung → Controller → Stuntcar-Anbindung → Modell.
Menüs und Übungen bleiben beim vorhandenen Router.

- [ ] Schreibe `test_menu_start_does_not_also_steer`, `test_no_double_keyboard_pedal`, `test_voice_and_key_use_same_action` und `test_pause_needs_fresh_key_press`.
- [ ] Ergänze `test_disconnect_releases_voice_actions`, `test_focus_loss_releases_keys`, `test_model_swap_creates_new_session` und `test_checkpoint_retry_retires_old_input`.
- [ ] Starte `.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/control/run_session_control_tests.gd`. Belege den Fehler.
- [ ] Erzeuge Port, Quellen und Controller beim Modellwechsel gemeinsam. Jede reguläre neue Fahrt und jeder Wiederholungsversuch bekommt eine neue Sitzung. Ein geändertes aktives Hilfsprofil erzeugt ebenfalls einen neuen Controller.
- [ ] Setze zuerst das Modell regulär zurück. Erzeuge den Controller mit `StuntcarActions.control_profile(model)`. Rufe danach `port.reset(session_id)`, `controller.begin_session(session_id)` und `source.configure(session_id, catalog)` je Quelle auf. Bewahre das gespeicherte Hinweisintervall von 3, 5 oder 8 Sekunden.
- [ ] Führe die physische Tastenliste auch in Menüs fort, ohne deren Fahranweisungen weiterzugeben. Ein Starttastendruck muss vor dem Quellreset als gehalten bekannt sein.
- [ ] Bearbeite Fahrereignisse vor dem Modellschritt. Die Reihenfolge lautet: Kontext aktualisieren, Eingaben sammeln, `controller.step(now_ms)`, `port.advance(delta, now_ms)`, `session.step(delta)`.
- [ ] Entferne den direkten `model.keyboard_speed`-Aufruf aus `main.gd`. Entferne direkte Fahraktionen aus `CommandRouter.submit_voice`, `submit_call` und dem Fahrzweig von `press`. Kompatibilitätsmethoden dürfen nur noch denselben Controller nutzen.
- [ ] Bei Pause, Fokusverlust, Quellenverlust und Modellwechsel verwerfe Warteschlangen und beende die betroffenen Ausführungen. Ein Aufruf im Menü darf die nachfolgende Fahrt nicht zusätzlich lenken.
- [ ] Passe die vorhandenen Tests auf die injizierte Uhr an. Lösche keine Prüfung der echten Tastenfreigabe, der gespeicherten Belegung oder des Mikrofonausfalls.
- [ ] Wiederhole die neue Sitzungsprüfung sowie `tests/run_input_tests.gd`, `tests/run_keyboard_speed_tests.gd` und `tests/run_voice_assist_tests.gd` mit dem Godot-Aufruf aus Aufgabe 1.
- [ ] Sichere den Commit `refactor: route driving input through the shared controller`.

## Aufgabe 8 Anzeige und bestehende Hinweistöne aus einer Grundlage versorgen

**Dateien:** Neu: `scripts/ui/hint_presenter.gd`, `tests/control/run_hint_view_tests.gd`. Ändern: `scripts/ui/game_ui.gd`, `scripts/main.gd`, `locales/en.po`, `tests/run_assist_feedback_tests.gd`. Nur bei notwendiger Ereignisanbindung ändern: `scripts/audio/race_audio.gd`.

**Eingang:** Hinweise aus Aufgabe 6 und tatsächliche Ausführungsbestätigungen aus Aufgabe 7.

**Ergebnis:** `HintPresenter.present(hints: Array[Dictionary], confirmation: Dictionary, state: String) -> Dictionary` liefert `title`, `detail` und `hint_id`.
`session.control_hints` und `session.control_confirmation` enthalten die zuletzt gültigen Daten. Die Anzeige verändert sie nicht.
Nach dem Modellschritt aktualisiert die Sitzung `control_hints` mit `controller.read_hints(now_ms)`.
Die Sitzung erhält `control_confirmation` aus dem letzten Ergebnis von `controller.step`.

- [ ] Schreibe `test_selected_direction_comes_from_confirmation`, `test_target_speed_uses_recommended_label`, `test_missing_bounds_do_not_show_zero` und `test_render_has_no_apply_effect`.
- [ ] Schreibe `test_one_tone_per_hint_window` und `test_pause_and_model_swap_clear_hint`. Viele gleiche Bilder dürfen keine neuen Töne auslösen.
- [ ] Starte `.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/control/run_hint_view_tests.gd`. Belege den Fehler.
- [ ] Ersetze in `game_ui.gd` die eigenständige Ermittlung von Kurvenrichtung und Tempogrenzen durch den Presenter. Die Anzeige darf einen linken Befehl nicht mehr mit der rechten Streckenrichtung als ausgeführt bestätigen.
- [ ] Verwende vorhandene Textschlüssel, soweit deren Aussage stimmt. Ergänze andernfalls vollständige englische Texte in `locales/en.po`, etwa für empfohlenes Tempo und fehlende Tempogrundlage. Keine Zahlen als sicheren Bereich bezeichnen, wenn nur ein Hilfsziel vorliegt.
- [ ] Behalte den bisherigen Hinweis-Klang. Er wird einmal je neuem gültigem `hint_id` im laufenden Spiel ausgelöst. Baue keine neue Sprachausgabe ein.
- [ ] Prüfe die Anzeige in einer normalen Kurve, bei falscher Richtung und bei einem ungeprüften Sprung visuell. Sichere Bilder als Prüfnachweis. Nutze eine gesonderte Einstellungsdatei.
- [ ] Wiederhole die neue Anzeigeprüfung, `tests/run_assist_feedback_tests.gd`, `tests/run_i18n_tests.gd` und `python3 tests/test_localization_catalog.py`. Erwartung jeweils: Rückgabewert 0.
- [ ] Sichere den Commit `refactor: display shared hints and actual action confirmations`.

## Aufgabe 9 Prüfberichte an den neuen Steuerungsweg binden

**Dateien:** Ändern: `scripts/track/spatial/verification.gd`, `scripts/vehicle/spatial/drive_runner.gd`, `tools/spatial/check_drives.gd`, `tests/spatial/{test_verification,test_full_drives,full_drive_cases}.gd`, `tracks/reports/06_stuntlabor.json`. Neu: `tests/control/run_control_verification_tests.gd`.

**Eingang:** Der tatsächlich integrierte Steuerungsweg und die vorhandenen Prüfberichte.

**Ergebnis:** Die Berichte erfassen die neue Aktionswirkung und die erforderlichen Steuerungsdateien. Die vorhandene Freigabe bleibt wirksam.
Ein Bericht benennt weiterhin nur einzelne geprüfte Zustände und reguläre Fahrten.

- [ ] Schreibe `test_control_change_invalidates_digest`, `test_wrong_direction_is_not_replayed_as_correct` und `test_recorded_controls_replay_same_result`.
- [ ] Starte `.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/control/run_control_verification_tests.gd`. Belege den Fehler.
- [ ] Erweitere `Verification.SOURCES` um die neuen tatsächlich wirksamen Kern-, Quellen- und Anbindungsdateien. Erhöhe die Fassung der erfassten Regeln. Lass die Berichtsdatei selbst außerhalb ihrer eigenen Prüfsumme.
- [ ] Stelle den Fahrprüfer auf dieselben normalisierten Anweisungen und dieselbe Ausführung wie das Spiel um. Bewahre die alten aufgezeichneten Eingabearten durch eine ausdrückliche Übersetzung. Setze keine Position oder Geschwindigkeit während einer Fahrt direkt.
- [ ] Führe den folgenden vorhandenen Auftrag mit dem überarbeiteten Prüfer aus:

```sh
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/spatial/check_drives.gd -- --track res://tracks/06_stuntlabor.json --output res://tracks/reports/06_stuntlabor.json
```

- [ ] Verlange für beide Hilfestufen eine reguläre Fahrt und deren Wiederholung. Übernimm keinen erfolgreichen Altbericht mit falscher Prüfsumme.
- [ ] Starte danach `tests/spatial/test_verification.gd`, `tests/spatial/test_full_drives.gd`, `tests/control/run_session_control_tests.gd` und `tests/run_stunt_scene_tests.gd` über den bekannten Godot-Aufruf.
- [ ] Wiederhole die neu erzeugte Fahrt ein zweites Mal. Prüfe Ergebnis, Eingabefolge und Hilfsverbrauch. Entferne keinen zuvor festgelegten schwierigen Fall aus der Liste.
- [ ] Sichere den Commit `test: bind Stuntcar verification to the shared control path`.

Ein Zwischenlauf aus Aufgabe 4 nutzt denselben Auftrag nach der dortigen Modelländerung.
Nach späteren Änderungen an erfassten Steuerungsdateien muss dieser Auftrag erneut laufen.
Ein zeitweilig veralteter Bericht ist kein Grund, `Verification.playable` abzuschwächen.

## Aufgabe 10 Wiederverwendung und Freigabe der ersten Lieferung prüfen

**Dateien:** Neu: `tests/control/{platform_port,run_portability_tests}.gd`, `addons/accessible_controls/README.md`, `docs/control-integration.md`. Ergänzen: `docs/prototype-test.md` und `docs/windows-testing.md`.

**Eingang:** Der unveränderte allgemeine Kern aus den Aufgaben 1 und 2.

**Ergebnis:** Ein zweites kleines Spielmodell nutzt `move_left`, `move_right` und einen echten `jump` ohne Stuntcar-Begriffe im Kern.
Die Einbindung lässt sich allein anhand der Dokumentation nachvollziehen.

- [ ] Schreibe `test_second_game_uses_same_controller`, `test_no_vehicle_import_in_addon`, `test_jump_has_one_effect` und `test_second_game_explicit_bad_move_is_preserved`.
- [ ] Starte `.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/control/run_portability_tests.gd`. Belege den Fehler.
- [ ] Implementiere nur das kleine Modell als Testanbindung: horizontale Position, Bodenkontakt und Sprungimpuls. Kein Level, kein Menü, kein neues Produkt. `jump` darf nur bei Bodenkontakt beginnen.
- [ ] Dokumentiere Katalog, Quellen, Zeitbasis, vier Spielmethoden, gehaltene Aktionen, Hilfestufen und Hinweise. Zeige eine Einzelaktion und eine gemeinsame Anweisung. Kennzeichne die noch fehlenden Sprachkombinationen und Gesten.
- [ ] Führe alle zehn neuen Prüfeinstiege unter `tests/control` einzeln aus. Jeder muss mit Rückgabewert 0 enden. Die zehn Einstiege sind Vertrags-, Controller-, Quellen-, Richtungs-, Anbindungs-, Regel-, Sitzungs-, Anzeige-, Verifikations- und Wiederverwendungsprüfung.
- [ ] Führe zusätzlich die unten genannte bestehende Abnahme aus. Wiederhole nur nach neuen Änderungen oder einem festgestellten Fehler.
- [ ] Prüfe manuell beide Hilfestufen mit Tasten und vorhandenem Sprachmodell. Prüfe Links, Rechts, absichtlichen Ruf, falsche Richtung, Bremsen, Pause, Fortsetzung und Quellenverlust.
- [ ] Prüfe eine reguläre Fahrt im bisherigen Modell und eine Fahrt im Stuntlabor mit Darstellung. Eine gewünschte falsche Richtung muss sichtbar erhalten bleiben. Ein unerwünschter Absturz ersetzt keine Prüfung der Bedienbarkeit.
- [ ] Erfasse Prüfstand, Befunde und verbleibende Grenzen in `docs/control-integration.md`. Eine fehlende menschliche Sprachprobe oder Windows-Probe bleibt offen und erhält keine erfundene Bestätigung.
- [ ] Sichere den Commit `docs: verify reusable controls and document first integration`. Danach folgt ein Review des gesamten Umbaus vor einer Freigabe.

## Bestehende Abnahme nach dem Umbau

Nutze `.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script <Datei>` für jede genannte Godot-Datei.
Unter einem anderen Betriebssystem nutze dieselbe Godot-Fassung mit ihrem lokalen Programmpfad.

| Bereich | Bestehende Prüfeinstiege |
|---|---|
| Eingaben | `tests/run_input_tests.gd`, `tests/run_keyboard_speed_tests.gd`, `tests/run_voice_bridge_tests.gd`, `tests/run_voice_scene_tests.gd`, `tests/run_voice_assist_tests.gd` |
| Fahrhilfe | `tests/run_curve_assist_tests.gd`, `tests/run_assisted_drive_tests.gd`, `tests/run_assist_selection_tests.gd`, `tests/run_assist_feedback_tests.gd`, `tests/run_assist_limits_tests.gd` |
| Räumliches Modell | `tests/spatial/test_assists.gd`, `tests/spatial/test_surface_motion.gd`, `tests/spatial/test_flight.gd`, `tests/spatial/test_boundaries.gd`, `tests/spatial/test_full_drives.gd`, `tests/spatial/test_verification.gd` |
| Szene und Texte | `tests/run_scene_test.gd`, `tests/run_stunt_scene_tests.gd`, `tests/run_i18n_tests.gd`, `python3 tests/test_localization_catalog.py` |
| Sprachgrundlage | `python3 -m unittest voice.tests.test_protocol voice.tests.test_call_detector voice.tests.test_feedback voice.tests.test_microphone` |

Erfolg bedeutet jeweils Rückgabewert 0 und keine fehlgeschlagene Bedingung.
Der bekannte Godot-Fehler beim Lesen der macOS-Systemzertifikate ersetzt keine Auswertung des Prüfergebnisses.
Prüfungen, die noch eine heimliche Richtungskorrektur verlangen, müssen nach Aufgabe 4 ihre neue Bedeutung prüfen.
Andere unveränderte Fehler gehören mit Ausgangsstand und tatsächlicher Ursache in den Bericht.

## Zuordnung zum Entwurf

| Anforderung | Aufgaben oder ausdrückliche Grenze |
|---|---|
| Vertrag, ehrlicher Katalog und allgemeine Eingaben | 1, 3, 5 |
| Auswahl nach Hilfestufe und ausdrückliche Vorgaben | 2, 6 |
| Richtungswirkung statt bloßer Kurvenfreigabe | 4 |
| Gehaltene Eingaben, Reihenfolge und getrennte Enden | 2, 3, 5, 7 |
| Gemeinsame Ausführung einer Anweisung | 1, 2, 5 |
| Einfache Hinweise und gültige Grundlage | 6, 8 |
| Pause, Quellenverlust, Neustart und Aktualität | 2, 5, 7 |
| Beide vorhandenen Fahrmodelle und Wiederverwendung | 4, 5, 9, 10 |
| Neue gesprochene Kombinationsphrase | Eigener späterer Auftrag. Der Kern und die Spielanbindung unterstützen ihre spätere gemeinsame Anweisung bereits. |
| Neue automatische Tempoergänzungen | Eigene spätere Freigabe nach belegter Grundlage und getrennten Bedienversuchen. |
| Vorausberechnung und allgemeine Levelprüfung | Abschnitte 15 bis 19 des Entwurfs bleiben außerhalb dieser Lieferung. |

## Abschluss der Planung und nächste Entscheidung

Der Plan verlangt zehn nacheinander prüfbare Aufgaben.
Die ersten sechs Aufgaben schaffen Kern, Quellen, echte Aktionswirkung, Spielanbindung und einfache Regeln.
Die Aufgaben 7 bis 10 verbinden diese Teile mit dem Spiel und prüfen die tatsächliche Wiederverwendung.
Kein Zwischenschritt allein bestätigt die ganze barrierefreie Steuerung.

Für die spätere Ausführung empfehle ich die Umsetzung in dieser Sitzung mit einem abschließenden unabhängigen Review.
Die Aufgaben teilen viele Schnittstellen und ändern denselben Eingabeweg.
Eine Ausführung mit getrennten Unteragenten je Aufgabe ist ebenfalls möglich, benötigt aber zusätzliche Übergaben und Reviews.
Stefan prüft zuerst den Plan und wählt den Ausführungsweg. Bis dahin bleibt die Spielsteuerung unverändert.

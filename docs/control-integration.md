# Erste Einbindung der gemeinsamen Steuerung

Stand: 17. Oktober 2026. Grundlage: Commit `d386185` und der freigegebene Umsetzungsplan.
Die Umsetzung liegt im Zweig `codex/control-modular-hints`.

## Aufbau

| Teil | Datei | Aufgabe |
|---|---|---|
| Allgemeiner Kern | `addons/accessible_controls/core/` | Prüft Anweisungen und wählt erlaubte Aktionen. |
| Tastaturquelle | `scripts/control/keyboard_source.gd` | Übersetzt Tasten und verlängert Pedale. |
| Sprachquelle | `scripts/control/voice_source.gd` | Übersetzt bestehende Wörter und kalibrierte Rufe. |
| Spielkatalog | `scripts/control/stuntcar_actions.gd` | Beschreibt sechs echte Spielaktionen. |
| Spielanbindung | `scripts/control/stuntcar_port.gd` | Prüft Kombinationen und verwaltet ihre Enden. |
| Hinweise und Regeln | `scripts/control/stuntcar_hints.gd`, `stuntcar_rules.gd` | Liefern reine Daten aus bestehenden Streckenregeln. |
| Anzeige | `scripts/ui/hint_presenter.gd` | Verbindet Hinweise mit tatsächlichen Bestätigungen. |

Menüs und Übungen bleiben beim bisherigen Router.
Fahraktionen nutzen den Weg Quelle → Anweisung → Controller → Spielanbindung → Fahrmodell.
Die Sitzung ersetzt alle Steuerungsteile bei einer neuen Fahrt, einem Wiederholungsversuch oder einem Modellwechsel.

## Reihenfolge und Zeit

Die Sitzung aktualisiert den Spielzustand und erfasst die Eingaben.
Danach folgen `controller.step`, `port.advance` und der Modellschritt.
Erst danach fragt die Sitzung die Hinweise für die Anzeige ab.
`main.control_clock` liefert eine stetige Zeit. Tests setzen diese Uhr ausdrücklich.

| Grenze | Wert |
|---|---|
| Gültigkeit einer neuen Anweisung | 250 ms |
| Verlängerung einer gehaltenen Taste | Alle 50 ms |
| Bestätigte Pedaldauer | Höchstens 150 ms je Verlängerung |
| Manuelle Lenkung ohne passende Kurvenhilfe | 500 ms |
| Passender gespeicherter Lenkwunsch | Höchstens 30 s, endet vorher am Kurvenende |

Der Plan nannte zuerst zehn Sekunden für den gespeicherten Lenkwunsch.
Die vollständige Fahrprüfung zeigte einen Fehler bei 46 und 58 m/s Anfangstempo.
Die bestehende Tempohilfe senkt das Tempo nach einer sehr frühen Eingabe.
Dadurch endete die Vormerkung vor der Kurve.
Die Umsetzung nutzt deshalb 30 Sekunden als endliche Obergrenze.
Gegenbefehl, Pause und Quellenverlust beenden den Lenkwunsch sofort.

## Aktionen und Hilfestufen

| Aktion | Wirkung |
|---|---|
| `turn_left`, `turn_right` | Speichert die gewählte Richtung oder startet eine kurze manuelle Lenkung. |
| `speed_up`, `speed_down` | Ändert das gespeicherte Zieltempo mit der bisherigen Lautstärkewirkung. |
| `pedal_up`, `pedal_down` | Ändert das Zieltempo während der bestätigten Dauer. |

Eine ausdrückliche falsche Richtung bleibt erhalten.
Die Kurvenhilfe benötigt die passende Richtung.
Ein ausdrücklich gehaltenes Pedal verhindert einen entgegengesetzten automatischen Tempoeingriff.
Das Ende eines Pedals erhält das zuvor gespeicherte Zieltempo.
Zwei Quellen derselben Pedalrichtung verdoppeln die Wirkung nicht.

Sehr leicht erlaubt Ergänzungen und einen bewusst ausgelösten kalibrierten Ruf.
Leicht erlaubt Ergänzungen und verlangt eine konkrete Aktion.
Der reine Direktbetrieb existiert als Vertragsprüfung. Die Oberfläche bietet ihn noch nicht an.
Stuntcar erzeugt in dieser Lieferung keine neuen automatischen Tempoergänzungen.
Der allgemeine Kern unterstützt bewertete Kombinationen bereits.

## Hinweise und Bewertungsgrundlage

`stuntcar_rules_v1` bewertet eine passende Richtung mit +0,6.
Eine bekannte Gegenrichtung erhält −0,8. Eine fehlende Grundlage erhält `unknown` und `null`.
Eine belegte fehlende Tempoaktion kann den Wert auf −0,4 senken.
Eine belegte passende Kombination kann +0,8 erhalten. Die Regeln addieren keine Einzelwerte.

Feste Hilfswerte heißen empfohlenes Hilfstempo.
Die Anzeige bezeichnet sie nicht als sichere Höchstgeschwindigkeit.
Unbekannte Minima und Maxima bleiben `null`.
Geprüfte Einzelproben benötigen dieselbe Bedingung und Prüfsumme.
Die Hinweise verbinden keine Einzelproben zu einem sicheren Bereich.

Die Anzeige bestätigt die tatsächlich ausgeführte Richtung.
Der vorhandene Hinweiston ertönt einmal je gültigem Hinweisfenster.
Die Umsetzung enthält keine neue Sprachausgabe.

## Fahrberichte

Der Fahrprüfer nutzt denselben Controller und dieselbe Spielanbindung wie die Szene.
Neue Berichte speichern die gemeinsamen Anweisungen.
Der Prüfer übersetzt alte Eingabearten ausdrücklich.
Die Prüfsumme enthält die wirksamen Steuerungsdateien und die Regelfassung 3.
Die Berichtsdatei enthält sich nicht selbst in ihrer Prüfsumme.
Ein veralteter Bericht gibt das Stuntlabor weiterhin nicht frei.

Die regulären Stuntlabor-Fahrten erreichen auf beiden Hilfestufen das Ziel.
Zwei Erzeugungen liefern denselben Bericht einschließlich Eingaben und Hilfsverbrauch.
Die vollständige Matrix behält falsche, fehlende, späte und wechselnde Eingaben.
Dauerhaftes Gas darf wegen des Vorrangs der ausdrücklichen Eingabe scheitern.
Die Prüfungen verlangen deshalb keine heimliche Gegenbremse.

## Prüfstand und offene Proben

Die automatischen Prüfungen verwenden Godot 4.5.1 unter macOS.
Zehn neue Prüfeinstiege decken Vertrag, Auswahl, Quellen, Richtung, Ausführung, Regeln, Sitzung, Anzeige, Fahrberichte und Wiederverwendung ab.
Die bestehende Abnahme umfasst zusätzlich die Spielszene, Fahrmodelle, Sprachverbindung und Texte.
Die Python-Prüfungen decken Sprachpakete, Rufereignisse, Rückmeldungen und Mikrofonzustände ab.
Die automatische Abnahme besteht mit 32 von 32 Aufträgen.
Der Prüfstand steht unter `docs/superpowers/reviews/2026-10-17-steuerung-umsetzung-pruefstand.md`.

Drei Bilder aus der echten Spielszene prüfen Kurve, falsche Richtung und ungeprüften Sprung.
Sie liegen unter `docs/control-review/2026-10-17/`.
Die Bilder zeigen links als gewählte Richtung auch vor einer Rechtskurve.

Eine menschliche Sprachprobe mit dem vorhandenen Sprachmodell steht noch aus.
Eine menschliche Probe der Bedienbarkeit steht noch aus.
Eine Windows-Probe steht noch aus.
Diese offenen Proben erhalten keine erfundene Bestätigung.

Vorausberechnung, Referenzfahrten, Training, neue Sprachkombinationen und Gesten gehören nicht zu dieser Lieferung.

# Gemeinsame barrierefreie Steuerung

Der Kern verbindet eine Eingabequelle mit einem Spiel. Er enthält keine Fahrzeugregeln.
Eine Bewertung verändert das Spiel nicht. Nur `apply` führt Aktionen aus.

## Ablauf

1. Das Spiel beschreibt seine Aktionen mit `describe_actions`.
2. Die Quelle erzeugt eine gemeinsame Anweisung mit `InputSource`.
3. Der `Controller` prüft die Anweisung und ihre Reihenfolge.
4. Das Spiel bewertet Vorschläge mit `assess`.
5. Der `Selector` erhält ausdrückliche Aktionen und wählt erlaubte Ergänzungen.
6. Das Spiel prüft die gesamte Auswahl erneut und startet sie mit `apply`.

Der Controller bewegt das Spielmodell nicht. Das Spiel führt danach seinen eigenen Modellschritt aus.

## Die vier Spielmethoden

| Methode | Aufgabe |
|---|---|
| `describe_actions()` | Liefert den Aktionskatalog mit `schema_version: 1` und `catalog_version`. |
| `assess(request)` | Liefert bewertete Vorschläge und Hinweise für den aktuellen Zustand. |
| `apply(decision, now_ms)` | Prüft und startet alle Mitglieder gemeinsam oder keines. |
| `cancel(request, now_ms)` | Beendet eine Ausführung, eine Quelle oder die Sitzung. |

Der Katalog beschreibt Parameter, Dauer, Ausschlussgruppe, Bezugssystem und tatsächliche Wirkung jeder Aktion.
`pulse` bezeichnet einen einmaligen Auftrag. `bounded` bezeichnet einen Auftrag mit einer begrenzten Dauer.
Ein Impuls kann einen gespeicherten Spielwert verändern. Das Ende des Impulses setzt diesen Wert nicht automatisch zurück.

Eine Bestätigung enthält `result`, `execution_id`, `actions` und `member_ends`.
Jedes Mitglied nennt mit `ends_at_ms` sein bestätigtes Ende.
Ein Spiel kann frühere Enden über `active_members` in der Bewertung melden.
Jeder Eintrag enthält `execution_id`, `action_id` und `ends_at_ms`.
Wenn das Spiel diese Liste liefert, beschreibt sie alle noch aktiven Mitglieder.
Damit blockiert eine bereits beendete Aktion keine spätere Hilfe.

## Anweisungen und Zeit

Eine Anweisung nennt Sitzung, Quelle, Ereignis, Steuerung und Steuerungsfassung.
`event_id` bezeichnet ein Ereignis. `control_id` verbindet Beginn, Verlängerung und Ende.
Jede Verlängerung erhöht `control_revision`. Ein Ende beendet nur die passende Quelle und Steuerung.
Alte Fassungen, doppelte Ereignisse und fremde Sitzungen erzeugen keine neue Wirkung.

Alle Nachrichten verwenden dieselbe stetige Zeit in Millisekunden.
Tests setzen eine eigene Uhr. Ein Pausenzustand bewegt das Modell nicht.
Eine neue Fahrt erhält eine neue Sitzungskennung. Eine Fortsetzung behält die Kennung und die Liste verarbeiteter Ereignisse.

```gdscript
const InputSource = preload("res://addons/accessible_controls/core/input_source.gd")
# controller und session_id stammen aus der Vorbereitung der Sitzung.
var source = InputSource.new("switch")
var left = {"action_id":"move_left", "parameters":{}, "duration_ms":0}
var jump = {"action_id":"jump", "parameters":{}, "duration_ms":0}
controller.submit(source.begin(session_id, "explicit", [left], now_ms, 250))
# Eine gemeinsame Anweisung startet beide Mitglieder gemeinsam.
controller.submit(source.begin(session_id, "explicit", [left, jump], now_ms, 250))
```

Ein Spiel muss `jump` selbst anbieten und ausführen. Der Kern erfindet keine Aktion.
Die kleine zweite Spielanbindung steht unter `tests/control/platform_port.gd`.
Sie prüft einen echten Sprungimpuls und den erforderlichen Bodenkontakt.

## Bewertung und Hilfestufen

`utility` liegt zwischen −1 und +1. Dieser Wert ist eine Bewertung und keine Wahrscheinlichkeit.
`unknown` verlangt `utility: null`. Ein unbekannter Wert ist nicht null Punkte wert.
Jede Kombination erhält eine eigene Bewertung. Einzelwerte ergeben keine Summe für eine Kombination.
Ein bekannter Absturz begründet keine Ergänzung und keine Rufauswahl.
Eine ausdrücklich verlangte schlechte Aktion bleibt ausführbar, wenn das Spiel sie physisch ausführen kann.

| Profilangabe | Bedeutung |
|---|---|
| `profile_id` | Eindeutige Kennung der Hilfestufe und ihrer Fassung. |
| `allow_additions` | Erlaubt passende zusätzliche Aktionen. |
| `allow_activate` | Erlaubt eine bewusste Aktivierung ohne konkrete Aktion. |

Eine Ergänzung darf einer noch aktiven ausdrücklichen Aktion nicht widersprechen.
Ein neuer ausdrücklicher Gegenbefehl ersetzt nur widersprechende Mitglieder.
Gleichzeitige widersprüchliche Anweisungen starten keine Teilkombination.

`read_hints` nutzt `query_only: true` und `intent: null`.
Hinweise lösen keine Aktion aus. Ihre Anzeige verändert weder die Bewertung noch das Modell.
Neue gesprochene Kombinationen und Gesten gehören zu einer späteren Erweiterung.

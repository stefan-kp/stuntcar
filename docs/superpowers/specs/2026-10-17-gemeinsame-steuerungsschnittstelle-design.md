# Gemeinsame Schnittstelle für barrierefreie Spielsteuerung

Datum: 17. Oktober 2026

Status: Entwurf zur Prüfung durch Stefan. Dieser Auftrag umfasst keine Umsetzung.

Die Schnittstelle verbindet Eingaben, bewertete Spielaktionen und Hilfestufen.
Das Spiel bewertet mögliche Aktionen und Kombinationen anhand seines aktuellen Zustands.
Das Steuerungsmodul wählt daraus einen Vorschlag, der zur Anweisung des Spielers passt.
Eine ausdrückliche Anweisung hat auf jeder Hilfestufe Vorrang vor einer besseren Bewertung.
Für Stuntcar liefern zunächst Spielregeln und kurze Vorausberechnungen mit dem tatsächlichen Fahrmodell die Bewertungen.
Geprüfte Referenzfahrten zeigen dabei, welcher erreichte Zustand gut ist.
Jev, Clef oder ein anderes lernendes Modell bilden keine Voraussetzung.

## 1 Bestätigte Regeln und vorgeschlagener Umfang

Stefan bestätigte diese Regeln:

- Eine erkannte Anweisung nach links bleibt eine Anweisung nach links.
- Eine schlechte Bewertung allein darf die Anweisung nicht aufheben.
- Leichte Stufen dürfen passende Aktionen ergänzen, etwa Bremsen beim Lenken.
- Höhere Stufen verlangen die zusätzlichen Aktionen vom Spieler.
- Eine gemeinsame Anweisung darf mehrere Aktionen enthalten, etwa „bremsen links“.
- Auf der leichtesten Stufe darf ein geeigneter Ruf ohne erkannten Befehl die beste gültige Aktion auslösen.
- Das Spiel liefert Bewertungen für Einzelaktionen und Kombinationen.
- Stuntcar nutzt seine eigene Bewegungsberechnung als Grundlage der Bewertung.
- Neue Level erhalten automatische Prüfungen mit verschiedenen Zuständen und vollständigen Fahrten.
- Die Bewertung rechnet im Spiel nur ein kurzes Stück voraus.
- Mehrere geprüfte Referenzfahrten zeigen, wie gut der erreichte Zustand ist. Die kürzeste erreichbare Fahrzeit bestimmt den Nutzen.

Die folgenden Datenfelder und Auswahlregeln konkretisieren diese Vorgaben als Vorschlag.
Der erste Umfang umfasst gleichzeitige Aktionen. Folgen mit mehreren zeitlich getrennten Schritten gehören nicht zur ersten Fassung.
Diese Grenze betrifft einen einzelnen Vorschlag. Eine vollständige Levelprüfung darf mehrere Anweisungen über die Fahrt verteilen.
Die Schnittstelle unterstützt verschiedene Spiele. Die erste Anbindung soll Godot nutzen.
Gesten liefern später dieselbe Form der Eingabe wie Sprache oder Tasten.

## 2 Aufbau und Zuständigkeiten

| Teil | Aufgabe |
|---|---|
| Eingabequelle | Eine Taste, einen Ruf, einen Sprachbefehl oder eine Geste erkennen. |
| Eingabeanbindung | Die erkannte Eingabe in eine gemeinsame Anweisung übersetzen. |
| Steuerungsmodul | Die Anweisung erhalten und passende Vorschläge nach der Hilfestufe auswählen. |
| Spielanbindung | Verfügbare Aktionen, Bewertungen und Ausführung bereitstellen. |
| Fahrmodell oder anderes Spielmodell | Die tatsächliche Bewegung und ihre Folgen berechnen. |

Die Spielanbindung enthält das Wissen über Kurven, Sprünge oder Gegner.
Das Steuerungsmodul enthält dieses Wissen nicht.
Die Bewertung verändert den Spielzustand nicht.
Nur die Ausführung verändert den Spielzustand.

| Möglicher Aufbau | Vorteil | Grenze |
|---|---|---|
| Godot-Erweiterung mit allgemeinem Datenformat | Nutzt vorhandene Teile und erlaubt ein zweites Godot-Spiel als Gegenprobe. | Andere Spielsysteme brauchen später eine eigene Anbindung. |
| Vorhandene Dateien direkt herauslösen | Verlangt zunächst weniger neue Grenzen zwischen den Teilen. | Übernimmt viele Annahmen über Kurven und Fahrbefehle. |
| Vollständig unabhängiger Steuerungsdienst | Erlaubt Anbindungen für verschiedene Spielsysteme. | Verlangt bereits zum Start zusätzliche Nachrichten und eine eigene Laufzeit. |

Dieser Entwurf empfiehlt die Godot-Erweiterung mit allgemeinem Datenformat.
Die vorhandene Python-Spracherkennung kann als getrennte Eingabequelle erhalten bleiben.

## 3 Vier Aufgaben der Schnittstelle

Die Namen in dieser Tabelle bezeichnen den Vertrag. Sie legen noch keine Programmdateien oder Transporttechnik fest.

| Aufgabe | Name | Ergebnis |
|---|---|---|
| Aktionen beschreiben | `describe_actions` | Ein Katalog mit Bedeutung, Parametern, Dauer und Ausschlüssen. |
| Vorschläge bewerten | `assess` | Verfügbare Einzelaktionen und relevante Kombinationen im aktuellen Zustand. |
| Eine Entscheidung ausführen | `apply` | Eine Bestätigung mit den tatsächlich gestarteten Aktionen. |
| Eine Ausführung beenden | `cancel` | Eine Bestätigung des Endes für die bezeichnete Ausführung. |

`assess` erhält auch die ausdrücklichen Vorgaben des Spielers und das aktive Hilfsprofil.
Das Spiel muss angeforderte Einzelaktionen ausdrücklich als verfügbar oder nicht verfügbar beantworten.
Eine Liste mit ausschließlich guten Vorschlägen reicht dafür nicht aus.
Das Modul darf `assess` auch ohne neue Eingabe für aktuelle Hinweise aufrufen.
Eine solche Abfrage löst keine Aktion aus.
Vor einer Entscheidung verlangt das Modul eine gültige Antwort für die aktuelle `decision_revision`.

Die Vertragspartner prüfen Vertragsfassung und Katalogfassung vor dem Austausch von Aktionen.
Eine unbekannte Fassung startet keine Spielaktion und liefert eine verständliche Fehlermeldung.
Pause und Abbruch bleiben unabhängig davon erreichbar.

## 4 Der Aktionskatalog

Jede Aktion erhält eine dauerhafte Kennung. Angezeigte Texte dürfen diese Kennung nicht ersetzen.
Einzelaktionen und Kombinationen verwenden dieselben Aktionskennungen.

| Feld | Bedeutung |
|---|---|
| `action_id` | Eindeutige Kennung der Aktion. |
| `parameters` | Erlaubte Parameter mit Datentyp, Einheit, Grenzen und Standardwert. |
| `execution_mode` | `pulse` für einen Impuls oder `bounded` für eine begrenzte Ausführung. |
| `default_duration_ms` | Standarddauer einer begrenzten Aktion. Bei einem Impuls gilt der Wert 0. |
| `max_duration_ms` | Höchste erlaubte Dauer. Bei einem Impuls gilt der Wert 0. |
| `exclusive_group` | Gruppe von Aktionen, die sich gegenseitig ausschließen. |
| `reference_frame` | Bezug einer Richtung, etwa die eigene Spielfigur. |
| `effect` | Beschreibung der tatsächlichen Wirkung und ihres Endes. |

Ein Spiel kann beispielsweise `steer_left`, `steer_right`, `brake` und `jump` anbieten.
`steer_left` und `steer_right` gehören zur gleichen Ausschlussgruppe.
Eine Kombination darf keine widersprüchlichen Mitglieder derselben Ausschlussgruppe enthalten.
Aktionen mit begrenzter Dauer brauchen positive Standard- und Höchstdauern.
Die Standarddauer darf die Höchstdauer nicht überschreiten.

Die Zahlen einer Aktion beschreiben ihre Wirkung. Sie beschreiben nicht ihren Nutzen.
Ein Parameter `amount: 0.3` kann 30 Prozent der im Katalog beschriebenen Bremswirkung bedeuten.
Er bedeutet nicht 30 Prozent Erfolgswahrscheinlichkeit.
Das Spiel muss diese Bedeutung im Katalog festlegen.

Der Katalog darf keine Aktion anbieten, deren Wirkung das Spiel nicht ausführen kann.
Ein Spiel darf eine gefährliche, aber ausführbare Aktion nicht als technisch unmöglich ausgeben.

## 5 Die gemeinsame Anweisung

| Feld | Bedeutung |
|---|---|
| `schema_version` | Für diese Fassung gilt 1. |
| `session_id` | Kennung des aktuellen Spielversuchs. |
| `event_id` | Innerhalb der Sitzung eindeutige Kennung der Eingabe, einschließlich Quelle und Ereignisnummer. |
| `source_id` | Kennung der Eingabequelle. |
| `control_id` | Gemeinsame Kennung für Beginn, Änderungen und Ende einer gehaltenen Eingabe. |
| `kind` | `explicit`, `activate`, `unresolved` oder `cancel`. |
| `required_actions` | Ausdrücklich verlangte Aktionen mit den bekannten Parametern. |
| `forbidden_actions` | Ausdrücklich ausgeschlossene Aktionen. |
| `phase` | `begin`, `update` oder `end`. |
| `captured_at_ms` | Erfassungszeit in der gemeinsamen, stetig fortlaufenden Sitzungszeit. |
| `expires_at_ms` | Letzter erlaubter Zeitpunkt für die Annahme dieser Eingabe. |
| `opportunity_id` | Kennung eines erlaubten Hilfsfensters; sonst `null`. |

Eine Eingabeanbindung übersetzt ihre eigene Zeitbasis in die gemeinsame Sitzungszeit.
Die Kalenderzeit bestimmt keine Frist innerhalb des Spiels.
`captured_at_ms` darf `expires_at_ms` nicht überschreiten.

`explicit` enthält eine klar erkannte Anweisung.
Dieser Zustand verlangt mindestens eine ausdrückliche Aktion.
`activate` bezeichnet ein persönlich eingerichtetes Signal ohne ausdrückliche Spielaktion.
Ein geeigneter Ruf wie „blub“ kann ein solches Signal sein.
`unresolved` bedeutet, dass die Eingabeanbindung keine sichere Anweisung liefert.
Dieser Zustand darf keine freie Aktionsauswahl auslösen.
`cancel` beendet die gehaltenen Aktionen der bezeichneten Eingabequelle.

Jede Änderung erhält eine neue `event_id` und behält dieselbe `control_id`.
Ein einzelner Impuls verwendet nur `begin` und endet nach der festgelegten Wirkung.
Eine gehaltene Eingabe verwendet `begin`, danach mögliche `update` und zuletzt `end`.
`update` darf keinen neuen Impuls auslösen.
Die Eingabeanbindung muss eine anhaltende Geste deshalb von einer neuen Geste unterscheiden.

Eine abgelehnte ausdrückliche Anweisung wird nicht nachträglich zu `activate`.
Eine Äußerung liefert entweder ihre erkannten Befehle oder eine Rufauslösung.
Sie darf nicht beide Wege für dieselbe Absicht auslösen.

„Bremsen links“ enthält beide Aktionen in einer Anweisung mit einer gemeinsamen Kennung.
Zwei getrennte Nachrichten mit ähnlicher Zeit bilden noch keine gemeinsame Anweisung.
Die erste Fassung behandelt eine vereinbarte Kombinationsphrase erst nach ihrem vollständigen Ende als gemeinsame Anweisung.
Die zusätzliche Wartezeit gehört deshalb zur späteren Sprachprobe.

Die Zuverlässigkeit der Erkennung und die Stärke einer Aktion bleiben getrennte Werte.
Das Steuerungsmodul darf eine Anweisung nicht allein wegen ihrer geringen Lautstärke herabstufen.

## 6 Die Antwort des Spiels

Die Antwort enthält einen gemeinsamen Rahmen und eine Liste von Vorschlägen.

| Feld im Rahmen | Bedeutung |
|---|---|
| `schema_version` | Vertragsfassung 1. |
| `session_id` | Aktueller Spielversuch. |
| `decision_revision` | Kennung der entscheidungsrelevanten Lage gemäß Abschnitt 9. |
| `state_step` | Spielschritt, ab dem das Spiel bewertet hat. |
| `opportunity_id` | Zugehöriges Hilfsfenster; sonst `null`. |
| `valid_until_ms` | Äußerste Annahmefrist für diese Vorschläge. |
| `catalog_version` | Fassung des Aktionskatalogs. |
| `model_version` | Fassung der Spielregeln für die Bewegung. |
| `assist_profile_id` | Aktives Hilfsprofil samt Fassung. |
| `objective_id` | Spielziel, auf das sich die Bewertungen beziehen. |
| `horizon_ms` | Zeitraum, über den das Spiel die Folgen bewertet. |
| `scoring_version` | Fassung der Bewertungsregeln. |
| `evaluation_context` | Bei Vorausberechnungen: Zustand, Schrittweite, Folgeeingaben, Referenzfahrten und Grenzen der Suche gemäß Abschnitt 14. |
| `proposals` | Liste der Einzelaktionen und Kombinationen. |

Das Spiel bewertet alle Vorschläge einer Antwort anhand desselben Zustands, Ziels, Zeitraums und Hilfsprofils.
Werte aus verschiedenen Antworten dürfen nicht gemeinsam eine Rangfolge bilden.
Ein Wechsel von Modell, Katalog, Hilfsprofil, Referenzfahrten oder `decision_revision` macht vorherige Antworten ungültig.
Ein neuer Spielschritt allein macht eine Antwort nicht ungültig. Dafür gilt `valid_until_ms`.

| Feld je Vorschlag | Bedeutung |
|---|---|
| `proposal_id` | Innerhalb der Antwort eindeutige Kennung. |
| `actions` | Vollständige Liste der Aktionen samt Parametern und Dauer. |
| `available` | Kann das Spiel alle Aktionen gemeinsam ausführen? |
| `rating_status` | `rated` oder `unknown`. |
| `utility` | Nutzen zwischen −1 und +1; bei `unknown` gilt `null`. |
| `reason_code` | Eindeutiger Grund für Nutzen, Unverfügbarkeit oder fehlende Bewertung. |
| `evidence` | `rule`, `simulated`, `tested_samples` oder `unknown`. |

`rule` bezeichnet eine Bewertung aus Spielregeln.
`simulated` bezeichnet eine neue Vorausberechnung mit dem tatsächlichen Spielmodell ab dem angegebenen Zustand.
Bei Stuntcar bewertet sie den erreichten Zustand mit den Referenzfahrten aus Abschnitt 15.
`tested_samples` bezeichnet eine Bewertung aus passenden geprüften Fällen.
`unknown` bezeichnet eine fehlende Grundlage.
Diese Angaben sind keine Erfolgswahrscheinlichkeiten.

Für `rated` muss `utility` eine endliche Zahl im erlaubten Bereich sein.
`unknown` und `null` dürfen nicht als 0 in die Auswahl eingehen.
Ein nicht verfügbarer Vorschlag erhält `rating_status: unknown` und `utility: null`.

Eine leere Aktionsliste beschreibt „keine neue Aktion“.
Dieser Vorschlag beendet keine laufende Aktion und hält keine Spielfigur automatisch an.
Das Spiel bewertet ihn wie jeden anderen Vorschlag.

Jede Kombination erhält eine eigene Bewertung für ihre vollständige Wirkung.
Das Modul darf die Bewertungen der Einzelaktionen nicht addieren.
Das Spiel liefert relevante Kombinationen und beantwortet ausdrücklich angeforderte Kombinationen.
Die Antwort behauptet keine vollständige Suche über alle denkbaren Aktionen und Parameter.

## 7 Bedeutung der Bewertung und Auswahl

| Wert | Bedeutung für das angegebene Spielziel |
|---|---|
| +1 | Sehr günstig. |
| 0 | Neutral. |
| −1 | Sehr ungünstig. |

Die Werte bilden eine Rangfolge innerhalb einer Antwort.
Sie müssen zusammen nicht 1 ergeben.
Ein Wert von 0,8 bedeutet weder 80 Prozent Erfolg noch einen messbaren Verlust von 20 Prozent.
Die erste Fassung vergleicht und ordnet die Werte. Sie berechnet daraus keine erwarteten Gewinne.
Werte verschiedener Spiele müssen nicht dieselbe messbare Wirkung ausdrücken.
Abschnitt 15 beschreibt die vorgeschlagene Berechnung dieser Rangfolge für Stuntcar.

Für eine ausdrückliche Anweisung gilt diese Reihenfolge:

1. Prüfe Sitzung, Frist und `decision_revision` der Eingabe.
2. Erhalte alle ausdrücklich verlangten und ausgeschlossenen Aktionen.
3. Entferne Vorschläge mit nicht verfügbaren oder widersprüchlichen Aktionen.
4. Entferne Vorschläge, die das Hilfsprofil nicht erlaubt.
5. Wähle unter den verbleibenden bewerteten Vorschlägen den höchsten Nutzen.
6. Lass das Spiel die vollständige Entscheidung vor der Ausführung prüfen.

Bei gleichem Nutzen gewinnt zuerst der Vorschlag mit weniger ergänzten Aktionen.
Bei weiterem Gleichstand gewinnt die aufsteigende Zeichenfolge von `proposal_id`.
Diese Regel macht gleiche Antworten wiederholbar.

Ein Vorschlag muss alle ausdrücklichen Aktionen enthalten und ihre Wirkung erhalten.
Eine links benannte Aktion mit tatsächlich nach rechts wirkender Hilfe erfüllt diese Bedingung nicht.
Bekannte Stärke und Dauer bleiben erhalten.
Bei fehlenden Werten darf die Hilfe nur innerhalb der im Katalog festgelegten Bedeutung ergänzen.
Sie darf die Wirkung einer ausdrücklichen Aktion nicht auf null setzen.

Fehlt eine passende Bewertung, fordert das Modul keine andere Richtung an.
Es reicht die ausdrückliche Anweisung ohne Ergänzungen an das Spiel weiter.
Das Spiel führt sie bei gültiger Verfügbarkeit aus oder liefert eine begründete Ablehnung.
Ein fehlender Empfehlungswert ist keine Ablehnung der Anweisung.

Für `activate` gilt die freie Auswahl nur im erlaubten Hilfsfenster auf „Sehr leicht“.
Das Modul berücksichtigt dabei auch den bewerteten Vorschlag „keine neue Aktion“.
Auch bei ausschließlich negativen Werten gewinnt der höchste Wert.
Ohne verfügbaren, bewerteten Vorschlag startet `activate` keine Aktion.
Ohne Eingabe startet das Modul grundsätzlich keine neue Empfehlung.

## 8 Regeln je Hilfestufe

| Regel | Sehr leicht | Leicht | Direkt als spätere Stufe |
|---|---|---|---|
| Ausdrückliche Richtung erhalten | Ja | Ja | Ja |
| Ausdrückliche Kombination erhalten | Ja | Ja | Ja |
| Passende Aktionen ergänzen | Ja | Ja | Nein |
| Bestes Ergebnis nach einem geeigneten Ruf wählen | Ja, im gültigen Hilfsfenster | Nein | Nein |
| Eine schlechte Anweisung allein wegen ihrer Bewertung ablehnen | Nein | Nein | Nein |
| Ohne Eingabe eine neue Empfehlung starten | Nein | Nein | Nein |

„Sehr leicht“ und „Leicht“ sind die vorhandenen Stufen.
„Direkt“ beschreibt hier nur die Regel für eine spätere höhere Stufe.
Dieser Entwurf verlangt noch keinen neuen Menüeintrag.

Spielhilfen wie eine längere Reaktionsfrist oder zusätzliche Spurführung gehören zum angegebenen Hilfsprofil.
Die Bewertung muss ihre Wirkung berücksichtigen.
Solche Hilfen dürfen eine ausdrücklich gewählte Aktion weder umkehren noch verdeckt aufheben.
Ein neues gegensätzliches Kommando beendet die widersprechende Hilfe innerhalb derselben Aktionsgruppe.
Andere Aktionsgruppen laufen nur bis zu ihrem festgelegten Ende weiter.

## 9 Gemeinsame Ausführung und Ende

`apply` erhält die Sitzung, `decision_revision`, Eingabekennung und die vollständig ausgewählten Aktionen.
Das Spiel prüft vor dem Start die gesamte Kombination.
Alle Mitglieder beginnen im selben Spielschritt.
Wenn ein Mitglied nicht ausführbar ist, startet das Spiel kein anderes Mitglied dieser Kombination.
Die erste Fassung ersetzt die Kombination nicht still durch eine Teilmenge.

Eine Bestätigung enthält `execution_id`, Eingabekennung, Ergebnis, gestartete Aktionen und einen Grund.
Das Ergebnis lautet `applied`, `rejected`, `stale` oder `duplicate`.
Einzelne Parameter dürfen nach der Prüfung nicht still andere Werte erhalten.
Das Spiel meldet später das Ende oder den Abbruch mit derselben Ausführungskennung.

Die physische Bewegung ändert sich in jedem Spielschritt. Eine Kennung dieses Zustands wäre bei jeder Antwort bereits veraltet.
`decision_revision` ändert sich deshalb nur bei entscheidungsrelevanten Ereignissen:

- Ein Hilfsfenster öffnet oder schließt.
- Eine Aktion startet oder endet.
- Hilfsprofil, Katalog, Modell oder Referenzfahrten wechseln.
- Pause, Fortsetzung, Neustart oder Quellenverlust treten ein.

Eine Antwort mit gleicher `decision_revision` bleibt bis `valid_until_ms` gültig.
`apply` prüft im aktuellen Spielschritt nur die Verfügbarkeit. Es bildet keine neue Rangfolge.
Eine geänderte `decision_revision` verlangt eine neue Bewertung.
Das Modul darf dieselbe noch gültige Eingabe einmal neu bewerten lassen.
Eine weitere Änderung entfernt alle Ergänzungen.
Die ausdrücklichen Aktionen gehen dann ohne Ergänzung an das Spiel, wie in Abschnitt 7 beschrieben.
Eine veraltete Bewertung allein führt nie zur Ablehnung einer ausdrücklichen Anweisung.
Ein `activate` ohne gültige Bewertung startet keine Aktion.
Eine Wiederholung darf keine bereits gestartete Wirkung erneut auslösen.
Ungültige Parameter, doppelte Kennungen und widersprüchliche Aktionsgruppen dürfen keine teilweise Ausführung erzeugen.

Die Frist eines Vorschlags begrenzt seinen Start. Sie ersetzt nicht die Dauer seiner Aktionen.
Begrenzte Aktionen enden spätestens nach ihrer bestätigten Dauer.
Ein Hilfsfenster darf zusätzlich ein früheres Ende verlangen.
Nach dem Ende darf eine Hilfe keine Wirkung für das folgende Streckenelement behalten.

Ein Impuls kann einen dauerhaften Spielzustand verändern, etwa das Zieltempo.
Der Katalog muss diese Wirkung beschreiben.
Nach dem Impuls bleibt diese Wirkung Teil des Spielzustands. Sie ist keine dauerhaft neue Anweisung.

Solange eine ausdrückliche Aktion läuft, darf die Hilfe keine widersprechende Aktion derselben Gruppe starten.
Die Bewertung einer neuen Ergänzung muss bereits laufende Aktionen berücksichtigen.
Wiederholungen derselben Eingabekennung dürfen keine zweite Ausführung starten.
Unterschiedliche Eingabekennungen bleiben getrennte Anweisungen, auch wenn sie dieselbe Aktion verlangen.
Gegensätzliche ausdrückliche Eingaben im selben Spielschritt starten keine neue Aktion der betroffenen Gruppe.
Die Rückmeldung nennt den Widerspruch.

Pause und Abbruch stehen außerhalb der Nutzenbewertung und haben Vorrang.
Sie beenden aktive Hilfe und gehaltene Eingaben.
Ein Neustart erzeugt eine neue Sitzung und verwirft alte Eingaben und Entscheidungen.
Nach einer Pause verlangt eine gehaltene Eingabe eine neue bewusste Auslösung.
Ein Ausfall der aktiven Eingabequelle beendet ihre gehaltenen Aktionen und pausiert das Spiel.

## 10 Beispiel einer Antwort

Die Zahlen in diesem Beispiel erläutern das Format. Sie sind keine gemessenen Werte aus Stuntcar.
Der angenommene Katalog definiert `amount` als Anteil der jeweiligen vollen Wirkung.
Er erlaubt die folgenden Dauern. Die eigene Spielfigur bildet den Richtungsbezug.

```json
{
  "schema_version": 1,
  "session_id": "fahrt-7",
  "decision_revision": 17,
  "state_step": 420,
  "opportunity_id": "kurve-3",
  "valid_until_ms": 7100,
  "catalog_version": 1,
  "model_version": "beispiel-1",
  "assist_profile_id": "very_easy:1",
  "objective_id": "strecke_fortsetzen",
  "horizon_ms": 1000,
  "scoring_version": 1,
  "proposals": [
    {
      "proposal_id": "links",
      "actions": [
        {"action_id": "steer_left", "parameters": {"amount": 1.0}, "duration_ms": 500}
      ],
      "available": true,
      "rating_status": "rated",
      "utility": 0.6,
      "reason_code": "kurvenrichtung",
      "evidence": "rule"
    },
    {
      "proposal_id": "links_bremsen",
      "actions": [
        {"action_id": "steer_left", "parameters": {"amount": 1.0}, "duration_ms": 500},
        {"action_id": "brake", "parameters": {"amount": 0.3}, "duration_ms": 800}
      ],
      "available": true,
      "rating_status": "rated",
      "utility": 0.9,
      "reason_code": "kurvenrichtung_und_tempo",
      "evidence": "rule"
    },
    {
      "proposal_id": "rechts",
      "actions": [
        {"action_id": "steer_right", "parameters": {"amount": 1.0}, "duration_ms": 500}
      ],
      "available": true,
      "rating_status": "rated",
      "utility": -0.8,
      "reason_code": "gegen_kurvenrichtung",
      "evidence": "rule"
    },
    {
      "proposal_id": "keine_neue_aktion",
      "actions": [],
      "available": true,
      "rating_status": "rated",
      "utility": -0.4,
      "reason_code": "kurve_ohne_lenkeingabe",
      "evidence": "rule"
    }
  ]
}
```

Bei „links“ ergänzt die leichte Hilfe hier die Bremse mit Stärke 0,3.
Die Bewertung 0,9 bestimmt die Auswahl. Sie bestimmt nicht die Bremsstärke.
Bei „rechts“ führt die negative Bewertung nicht zur Auswahl von links.
Ohne passenden Zusatzvorschlag führt das Spiel rechts ohne Ergänzung aus.
Auf „Direkt“ führt das Spiel bei „links“ ausschließlich die ausdrückliche Aktion aus.

## 11 Eignung für Stuntcar

Die Codeprüfung bezieht sich auf den vorhandenen Stand mit beiden Fahrmodellen.
Die letzten gelesenen Änderungen gehören zum Stand `86b6eff`.
Der Entwurf ersetzt keine vorhandene Abnahme und ändert keine Spielregel.

### Vorhandene Teile und erforderliche Anpassungen

| Vorhandener Teil | Eignung | Erforderliche Anpassung |
|---|---|---|
| [Kurvenhilfe](../../../scripts/vehicle/curve_assist.gd) | Liefert Hilfsfenster, Kennungen und Annahmephasen. | Die Fenster werden allgemein. Eine Richtung darf keine gegensätzliche Kurvenfreigabe auslösen. |
| [Bisheriges Fahrmodell](../../../scripts/vehicle/drive_model.gd) | Kennt Kurven, Tempo, Spielerziel und aktives Hilfsziel. | Es braucht eine tatsächliche Umsetzung ausdrücklicher Richtungen und eine gemeinsame Ausführung mehrerer Aktionen. |
| [Räumliches Fahrmodell](../../../scripts/vehicle/spatial_drive_model.gd) | Kennt Bodenkontakt, Flug, Restdauer der Hilfe und Bewegungsereignisse. | Die Eingabe muss ihre Richtung bis zur Bewegungsberechnung behalten. |
| [Bewegung auf der Fahrfläche](../../../scripts/vehicle/spatial/surface_motion.gd) | Berechnet Tempo, Seitenbewegung und Kontakt. | `turn_authorized` reicht als Eingabe nicht. Der Wert enthält keine gewählte Lenkrichtung. |
| [Stunthilfe](../../../scripts/vehicle/spatial/stunt_assist.gd) | Liefert Zieltempo und begrenzte Kräfte für einzelne Elemente. | Sie muss das Hilfsprofil und ausdrückliche Vorgaben beim Ergänzen von Aktionen beachten. |
| [Sprachverbindung](../../../scripts/input/voice_bridge.gd) | Verwirft alte oder doppelte Nachrichten und meldet Ausfälle. | Der Wortschatz und die Ereignisform werden allgemein. |
| [Befehlsverarbeitung](../../../scripts/input/command_router.gd) | Unterscheidet Fahrt, Pause, Menüs und Rufhilfe. | Spielzustand und Eingabeauswahl erhalten getrennte Zuständigkeiten. |
| [Spracherkennung](../../../voice/streaming.py) | Erkennt mehrere Befehlswörter einer Äußerung. | Eine gemeinsame Anweisung mit garantiert gemeinsamem Start fehlt. |
| [Prüfung räumlicher Tempohinweise](../../../scripts/track/spatial/verification.gd) | Bindet Hinweise an Zustand, Profil und Prüfsummen. | Neue Bewertungsregeln müssen dieselben Gültigkeitsgrenzen beachten. |
| [Vorhandener Fahrprüfer](../../../scripts/vehicle/spatial/drive_runner.gd) | Spielt Eingabefolgen mit dem tatsächlichen Fahrmodell nach. | Vollständige Zustandskopien und unabhängige Vergleiche mehrerer Vorschläge fehlen noch. |
| [Vorhandene Streckenprüfung](../../../tools/spatial/check_drives.gd) | Erstellt reguläre Fahrten und Berichte je Hilfsprofil. | Die Fallauswahl, die Suche, der Referenzsatz und die Abnahmeregeln aus Abschnitt 16 müssen hinzukommen. |

### Wichtigster Unterschied bei der Richtung

`CurveAssist.request` akzeptiert auf „Sehr leicht“ auch eine gegensätzliche Richtung.
`DriveModel.request_assisted_turn` übernimmt anschließend die Kurvenrichtung als ausgeführte Richtung.
Auf „Leicht“ lehnt die Kurvenhilfe die gegensätzliche Richtung ab.
Beide Verhaltensweisen widersprechen der neuen Vorgabe für ausdrückliche Anweisungen.

Das räumliche Fahrmodell nutzt dieselbe Kurvenfreigabe.
Seine Flächenbewegung erhält nur die Freigabe und führt dann zur Spurmitte zurück.
Eine Umbenennung der Befehle reicht daher nicht aus.
Das Fahrmodell muss eine tatsächliche Lenkeingabe nach links oder rechts umsetzen können.
Trägheit darf die sichtbare Wirkung verzögern. Die Hilfe darf die Lenkeingabe nicht umkehren.

Eine gültige Eingabe garantiert künftig nicht jede erfolgreiche Kurvenfahrt.
Eine ausdrücklich falsche Richtung kann zum Abkommen von der Strecke führen.
Die Hilfe darf passende Bremswirkung ergänzen. Sie darf die Richtung nicht ersetzen.
Die bisherigen Tests zur Korrektur falscher Richtungen müssen später die neue Regel prüfen.

### Tempo und Kombinationen

`change_speed` verändert heute vor allem ein Zieltempo.
`keyboard_speed` verändert dieses Ziel während eines Tastendrucks fortlaufend.
Diese Befehle sind keine vorhandene Bremse mit frei wählbarer Stärke 0,3 und Dauer 800 Millisekunden.
Die Spielanbindung muss diese Bedeutungen im Katalog getrennt beschreiben.
Sie darf eine Zieltempoänderung nicht als genaue Bremswirkung ausgeben.

Die vorhandene Tempohilfe liefert eine Grundlage für passende Ergänzungen.
Sie liefert noch keine gemeinsame Bewertung mehrerer Vorschläge.
Ihre Eingriffe können derzeit unabhängig von einem neuen Lenkbefehl auftreten.
Der Entwurf verlangt deshalb eine gemeinsame Prüfung aller aktiven Hilfen und ausdrücklichen Aktionen.
Auch spätere höhere Stufen brauchen passende Profile in beiden Fahrmodellen.

Das räumliche Modell bietet bereits Zustand und begrenzte Hilfsdauer für Stunts.
Seine geprüften Tempohinweise gelten nur für passende Zustände und passende Prüfsummen.
Ein neuer Bewertungswert darf daraus keine allgemeine Erfolgswahrscheinlichkeit ableiten.
Änderungen an den in der Prüfung erfassten Fahrdateien verlangen neue Prüfberichte.

### Sprünge und andere Spiele

Stuntcar startet einen Flug durch die Strecke und die Bewegung des Autos.
Es bietet derzeit keinen frei auslösbaren Sprungbefehl wie ein Plattformspiel.
Sein Aktionskatalog darf deshalb zunächst kein `jump` versprechen.
Die Vorbereitung eines Stunts kann stattdessen passende Tempoaktionen anbieten.
Ein Plattformspiel kann denselben Vertrag mit einem echten `jump` verwenden.

### Ergebnis der Eignungsprüfung

Das Konzept passt zu Stuntcar als Zielaufbau.
Die beiden Fahrmodelle können dieselbe äußere Schnittstelle verwenden.
Sie brauchen jeweils eine eigene Spielanbindung für Bewertung und Ausführung.
Die erforderliche Richtungswirkung ist die größte sachliche Änderung.
Die gemeinsame Schnittstelle allein behebt diesen Unterschied nicht.

## 12 Fälle für die spätere Abnahme

| Fall | Erwartetes Ergebnis |
|---|---|
| Links erhält −1, rechts erhält +1; der Spieler sagt links. | Das Spiel setzt links um. |
| Links mit Bremse ist besser als links allein; leichte Stufe. | Die Hilfe ergänzt die erlaubte Bremse. |
| Derselbe Fall auf Direkt. | Das Spiel setzt nur links um. |
| Der Spieler sagt bremsen links. | Beide Aktionen beginnen im selben Spielschritt. |
| Der Spieler nennt eine genaue Bremsstärke. | Die Hilfe erhält diese Stärke. |
| Der Spieler schließt Bremsen aus. | Die Hilfe ergänzt keine Bremse. |
| Eine aktive Beschleunigung widerspricht einer neuen Bremsempfehlung. | Die Hilfe erhält die aktive ausdrückliche Beschleunigung. |
| Ein Mitglied einer ausdrücklichen Kombination ist unmöglich. | Das Spiel lehnt die gesamte Kombination mit einem Grund ab. |
| Eine ausdrückliche Aktion hat keine Bewertung. | Das Spiel prüft und verarbeitet die Aktion ohne Ergänzung. |
| Ein geeigneter Ruf trifft auf Sehr leicht im gültigen Fenster ein. | Der beste verfügbare, bewertete Vorschlag gewinnt. |
| Alle Werte sind negativ. | Der höchste gültige Wert gewinnt; auch keine neue Aktion nimmt am Vergleich teil. |
| Der Ruf trifft auf Leicht ein. | Der Ruf startet keine freie Auswahl. |
| Ein ausdrücklicher Befehl scheitert. | Das Modul behandelt ihn nicht als Ruf. |
| Eine Teiläußerung bleibt unklar. | Sie startet keine freie Auswahl. |
| Eine Nachricht trifft doppelt ein. | Sie erzeugt keine zweite Wirkung. |
| Pause, Neustart oder Quellenverlust treten ein. | Alte Eingaben und laufende Hilfen wirken nicht weiter. |
| Die Bewegung ändert sich zwischen Bewertung und Start, `decision_revision` bleibt gleich. | Das Modul nutzt die noch gültige Antwort ohne neue Bewertung. |
| `decision_revision` ändert sich zweimal vor dem Start. | Die ausdrückliche Aktion startet ohne Ergänzung. |
| Eine Eingabe trifft ohne gültige Antwort ein. | Die ausdrückliche Aktion startet ohne Ergänzung; `activate` startet keine Aktion. |
| Zwei Referenzfahrten passen zum Endzustand. | Die kürzere Restzeit bestimmt den Nutzen. |
| Der Endzustand liegt außerhalb aller Korridore. | Der Nutzen liegt unter jedem Wert im Korridor und über einem Absturz. |
| Kein Hilfsfenster ist offen. | Das Spiel rechnet nicht voraus und ergänzt keine Aktion. |
| Eine Geste bleibt über viele Kamerabilder gleich. | Sie erzeugt keine wiederholten Impulse ohne neue Auslösung. |
| Gleiche Antworten enthalten gleiche Nutzenwerte. | Die feste Auswahlregel liefert denselben Vorschlag. |
| Eine Aktion verspricht links, aber die Hilfe wirkt dagegen. | Die Abnahme lehnt diese Anbindung ab. |

Die Abnahme prüft die tatsächliche Bewegungswirkung und die Rückmeldung.
Eine Prüfung nur der Befehlsnamen genügt nicht.
Beide Fahrmodelle brauchen diese Fälle.
Ein zweites Spiel muss denselben Vertrag ohne Kurvenbegriffe im Steuerungsmodul nutzen können.

## 13 Vorhandenes Verhalten als Ausgangspunkt

Die folgenden bestehenden Prüfprogramme liefen während dieser Bestandsprüfung erneut.
Sie prüfen das aktuelle Verhalten. Sie bestätigen noch keine Umsetzung dieses Entwurfs.

| Prüfung | Ergebnis |
|---|---|
| `tests/run_curve_assist_tests.gd` | 26 Bedingungen, 0 Fehler. |
| `tests/spatial/test_assists.gd` | 14 Bedingungen, 0 Fehler. |
| `tests/spatial/test_surface_motion.gd` | 7 Bedingungen, 0 Fehler. |
| Python: `test_protocol`, `test_call_detector`, `test_microphone` | 26 Tests, 0 Fehler. |

Godot meldete beim Start einen Fehler beim Lesen der Systemzertifikate.
Die drei Prüfprogramme beendeten ihre Prüfungen jeweils erfolgreich mit Rückgabewert 0.
Die Prüfung nutzte keine neue menschliche Sprachprobe und keine Kamera.
Die Erprobung mit den vorgesehenen Spielern bleibt Teil der späteren Abnahme.

## 14 Bewertung mit der tatsächlichen Spielephysik

### Grundgedanke

Die Bewertung besteht aus zwei Teilen.
Vor dem Spiel erzeugt die Levelprüfung mehrere geprüfte Referenzfahrten gemäß Abschnitt 16.
Im Spiel rechnet die Spielanbindung jeden Vorschlag nur ein kurzes Stück voraus.
Danach vergleicht sie den erreichten Zustand mit den Referenzfahrten gemäß Abschnitt 15.

Eine kurze Vorausberechnung allein übersieht spätere Folgen, etwa eine zu späte Bremsung.
Die Referenzfahrten zeigen diese Folgen bereits früh.
Ein zu schnelles Auto liegt zum Beispiel außerhalb jeder geprüften Referenzfahrt, obwohl es noch nicht abgestürzt ist.
Lange Vorausberechnungen bis zum Abschnittsende entfallen deshalb im laufenden Spiel.
Die Antwort ist bei der Eingabe bereits fertig. Sie ist höchstens einen Rechentakt alt.

### Grundlage und vollständiger Ausgangszustand

Die Bewertung verwendet dieselben Bewegungsfunktionen wie das laufende Spiel.
Eine getrennte, vereinfachte Bewegung darf keine geprüfte Bewertung ersetzen.
Die Bewegungsfunktionen müssen die im Katalog versprochene Wirkung tatsächlich ausführen.
Die heutige Umdeutung einer falschen Richtung darf keine Grundlage für die neue Bewertung bilden.
Feste Regeln dürfen eindeutige Vorschläge vorbereiten. Ihre Kennzeichnung bleibt `rule`.
Vorausberechnungen können diese Vorschläge anschließend anhand ihrer tatsächlichen Folgen vergleichen.

Jede Vorausberechnung beginnt mit einer eigenen vollständigen Kopie desselben Ausgangszustands.
Sie verändert weder die laufende Fahrt noch andere Vorausberechnungen.
Sie löst keine sichtbaren Effekte, Geräusche, Mikrofonzugriffe oder echten Eingabeereignisse aus.
Sie erfasst Bewegungsereignisse nur innerhalb ihrer eigenen Kopie.

| Zustandsteil | Erforderlicher Inhalt |
|---|---|
| Bewegung | Position, Geschwindigkeit, Ausrichtung, Seitenbewegung und Bodenkontakt oder Flug. |
| Strecke | Levelkennung, Abschnitt, Streckenfortschritt und zugehörige Formdaten. |
| Spielerziel | Zieltempo, aktive ausdrückliche Aktionen und deren Restdauer. |
| Hilfen | Aktive Kurvenhilfe, Freigaben, Zielwerte, Restdauer und bereits verbrauchte Hilfe je Abschnitt. |
| Weitere Fahrregeln | Turbo, Wartezeiten, Bremszustand und weitere zeitabhängige Fahrwerte. |
| Eingabeverarbeitung | Aktive Eingaben, Spielzustand, Hilfsfenster und bereits verarbeitete Ereigniskennungen. |
| Wiederholung | Spielschritt, Vertragsfassungen und gegebenenfalls Zustand des Zufallsgenerators. |

Eine Kopie nur von Position und Tempo reicht nicht.
Auch `DriveState.snapshot()` enthält derzeit nicht alle Werte der übergeordneten Fahr- und Eingabeverarbeitung.
Die spätere Umsetzung braucht deshalb eine vollständige Zustandserfassung und Wiederherstellung.
Ein Kontrolllauf ohne neue Aktion muss nach der Wiederherstellung dieselbe Bewegung wie die Ausgangsfahrt liefern.
Das Spiel erstellt diese Kopie in jedem Rechentakt. Ihre Erstellung muss deshalb schnell sein.

### Interner Vertrag für Vorausberechnungen

Dieser Vertrag gehört zur Spielanbindung. Er erweitert nicht die vier Aufgaben für normale Eingabequellen.
Die Bezeichnungen beschreiben Aufgaben und noch keine fertigen Programmfunktionen.

| Aufgabe | Eingabe | Ergebnis |
|---|---|---|
| Zustand erfassen | Laufende Fahrt an einer festgelegten Schrittgrenze. | Vollständiger Zustand mit Fassung und Prüfsumme. |
| Zustand kopieren | Vollständiger Zustand. | Unabhängige Fahrt ohne Verbindung zu echten Eingaben. |
| Vorausberechnung ausführen | Kopie, Vorschlag, Zeitraum und Folgeeingaberegel. | Verlauf, Endzustand, Ereignisse, Verbrauch der Hilfe und Endegrund. |
| Ergebnis bewerten | Ergebnisse aller verglichenen Vorschläge, Referenzsatz und Bewertungsprofil. | Nutzenwerte, Messwerte und Kennzeichnung der Grenzen. |

Für den Start aller Vorschläge gilt dieselbe Grenze zwischen zwei Spielschritten.
Der Prüfer verwendet die im Fahrmodell festgelegte Schrittweite, zunächst 1/60 Sekunde.
Er verwendet dieselbe Unterteilung eines Schritts für Flug und Landung wie das echte Modell.
Er darf weder Hilfsdauer zurücksetzen noch neue Kurvenfreigaben erfinden.
Eine Kopie erhält eigene Ereigniskennungen für ihre Vorausberechnung. Sie behält alle bereits wirksamen Eingabegrenzen.

`evaluation_context` enthält die folgenden Angaben:

| Feld | Bedeutung |
|---|---|
| `snapshot_version` und `state_digest` | Fassung und Prüfsumme des vollständigen Ausgangszustands. |
| `step_s` | Schrittweite der Bewegungsberechnung. |
| `evaluation_target` | Gemeinsames Abschnittsziel für die Restzeit der Referenzfahrten. |
| `reference_set_id` und `reference_set_digest` | Verwendeter Referenzsatz und seine Prüfsumme. |
| `continuation_policy_id` | Fassung der gemeinsamen Regel für spätere Eingaben. |
| `search_policy_version` | Fassung der Auswahl von Parametern und Vorschlägen. |
| `candidate_count` | Zahl der vollständig bewerteten Vorschläge. Nicht geprüfte Vorschläge bleiben mit `unknown` in der Liste. |
| `max_model_steps` und `used_model_steps` | Grenze und Verbrauch der Berechnung. |
| `coverage` | `complete_for_candidates` oder `partial`. Das Ergebnis gilt nur für die bezeichneten Vorschläge. |

Jeder simulierte Vorschlag enthält zusätzlich `metrics` und `stop_reason`.
`metrics` enthält die Messwerte aus Abschnitt 15.
`stop_reason` unterscheidet `finished`, `crashed`, `goal_reached`, `horizon_reached`, `budget_exhausted` und `invalid_state`.
Ein ungültiger Zustand liefert keine Bewertung.
Ein Abbruch durch die Rechengrenze liefert für den betroffenen Vorschlag ebenfalls `unknown`.

### Auswahl der Vorschläge und gemeinsame Folgeeingaben

Die Auswahl beginnt mit der ausdrücklichen Anweisung und dem Vorschlag „keine neue Aktion“.
Die Spielanbindung ergänzt verfügbare Einzelaktionen und erlaubte Kombinationen aus unterschiedlichen Aktionsgruppen.
Sie bewertet auch schlechte, aber ausführbare Aktionen.
Eine schlechte Vorhersage darf `available` nicht auf `false` setzen.

Für frei wählbare Zusatzstärken schlägt dieser Entwurf zunächst die Werte 0,2, 0,3, 0,5, 0,75 und 1,0 vor.
Die Anfangsauswahl für Zusatzdauern umfasst 200, 500 und 1.000 Millisekunden.
Der Katalog begrenzt diese Werte und ergänzt bei Bedarf eine Dauer bis zum Ende des Hilfsfensters.
Ein ausdrücklich genannter Wert erhält einen eigenen Vorschlag, auch wenn er nicht in dieser Auswahl steht.
Die Suche darf diesen Wert nicht auf den nächsten Auswahlwert ändern.

Die Suche prüft zunächst Einzelaktionen und danach Kombinationen aus höchstens einer Lenk- und einer Tempoaktion.
Weitere Spiele legen ihre eigenen erlaubten Gruppen fest.
Im laufenden Spiel verwendet die Suche höchstens 8 Vorschläge je Rechentakt.
Dazu gehören die aktuell gehaltene ausdrückliche Anweisung und „keine neue Aktion“.
Die Levelprüfung verwendet höchstens 24 Vorschläge je Entscheidungspunkt.
Eine feste Regel darf die Ergänzungen im Spiel vorwählen, etwa nach der Abweichung vom Tempo der nächsten Referenzfahrt.
Eine größere vorgeschriebene Kombination bleibt zulässig. Die Grenze betrifft die automatisch erzeugten Ergänzungen.

Nach dem Start eines Vorschlags kommen während der Vorausberechnung keine weiteren neuen Befehle hinzu.
Schon aktive Eingaben und der Vorschlag wirken bis zu ihrem angegebenen Ende oder bis zum Ende des Zeitraums.
Anschließend gelten ihre im Katalog beschriebenen Folgen, etwa ein weiterhin gespeichertes Zieltempo.
Diese Regel erhält die Kennung `no_new_input:1`.
Sie verhindert einen Vergleich, bei dem nur manche Vorschläge später perfekte zusätzliche Eingaben erhalten.
Die Referenzfahrten bewerten den Zustand am Ende. Sie liefern keine zusätzlichen Eingaben in der Vorausberechnung.

### Zeitraum und Rechentakt

Der Zeitraum beträgt zunächst eine Sekunde, also 60 Modellschritte.
Alle Vorschläge derselben Antwort verwenden denselben Zeitraum und dasselbe Abschnittsziel.
Ein früherer Absturz, das Abschnittsziel oder das Streckenende beendet die jeweilige Vorausberechnung.
Ein Flug am Ende des Zeitraums ist zulässig. Die Referenzfahrten enthalten auch Flugzustände.
Ein Flug bestätigt nur dann eine Landung, wenn der Zustand im geprüften Korridor einer Referenzfahrt liegt.

Die Spielanbindung rechnet nur bei offenem Hilfsfenster.
Sie startet alle 100 Millisekunden Spielzeit eine neue Vorausberechnung vom aktuellen Zustand.
Die Rechnung läuft außerhalb des Spielschritts. Sie darf keinen Spielschritt verzögern.
Die Antwort erhält `valid_until_ms` = Startzeit der Rechnung plus 200 Millisekunden.
Bei einer Eingabe nutzt das Modul die letzte gültige Antwort mit passender `decision_revision`.

Ohne offenes Hilfsfenster gibt es keine Vorausberechnung.
Eine ausdrückliche Anweisung geht dann ohne Ergänzung an das Spiel, wie in Abschnitt 7 beschrieben.
Ohne Eingabe startet die Rechnung keine Aktion. Sie bereitet nur Antworten vor.

Bei 8 Vorschlägen und 60 Schritten liegt die Obergrenze bei 480 äußeren Modellschritten je Rechentakt.
Das ergibt höchstens 4.800 äußere Modellschritte je Sekunde.
Interne Teilschritte und ihre Zahl gehören zusätzlich in das Prüfprotokoll.
Diese Grenze beschreibt den Arbeitsumfang. Sie verspricht noch keine bestimmte Antwortzeit.
Eine spätere Messung legt Zeitraum, Rechentakt und Zahl der Vorschläge für das laufende Spiel fest.
Bis zu dieser Messung gelten die Werte als Vorschlag.

Bei einer Rechengrenze bewertet das Modul nur vollständig geprüfte Vorschläge mit identischem Zeitraum.
Es kennzeichnet die übrigen Vorschläge als `unknown` und die Abdeckung als `partial`.
Fehlt eine rechtzeitig gültige Bewertung, gelten die Ausweichregeln aus Abschnitt 7.
Das Modul darf keine veraltete Empfehlung auf eine neue `decision_revision` anwenden.

## 15 Konkrete Bewertungsregel für Stuntcar

### Referenzfahrten und Korridore

Eine Referenzfahrt ist eine vollständige, geprüfte Fahrt vom Start bis zum Ziel.
Sie gilt für ein Level, ein Fahrmodell und ein Hilfsprofil.
Mehrere Referenzfahrten desselben Levels und Hilfsprofils bilden einen Referenzsatz.
Die Referenzfahrten unterscheiden sich etwa in Linie, Tempo oder Bremspunkt.

Jede Referenzfahrt speichert entlang des Streckenfortschritts diese Werte:

| Wert | Inhalt |
|---|---|
| Bewegung | Seitenlage, Seitenbewegung, Tempo, Ausrichtung sowie Bodenkontakt oder Flug. |
| Restzeit | Verbleibende Fahrzeit bis zu jedem Abschnittsziel und bis zum Ziel. |
| Korridor | Erlaubte Abweichung je Bewegungswert an dieser Stelle. |

Ein Korridor umfasst nur geprüfte Zustände.
Die Levelprüfung belegt ihn gemäß Abschnitt 16.
Ein Zustand im Korridor erreicht mit der festen Vergleichssteuerung das nächste Abschnittsziel ohne Absturz.
Seine Restzeit weicht höchstens um die im Bericht genannte Toleranz von der Restzeit der Referenzfahrt ab.
Ein Korridor liefert keine Erfolgswahrscheinlichkeit.

Mehrere Referenzfahrten dürfen sich überschneiden.
So deckt der Referenzsatz verschiedene gute Wege ab, etwa links oder rechts an einem Hindernis vorbei.
Das Steuerungsmodul kennt die Referenzfahrten nicht. Sie gehören zur Spielanbindung.

### Ziel und Messwerte

Das erste Bewertungsprofil `stuntcar_reference_v1` bevorzugt Zustände ohne Absturz innerhalb eines geprüften Korridors.
Unter diesen Zuständen gewinnt die kürzeste erreichbare Fahrzeit.
Danach berücksichtigt es zusätzliche Hilfe und ergänzte Aktionen.
Diese Reihenfolge und die folgenden Zahlen bilden einen prüfbaren Vorschlag.
Sie sind keine aus Spielversuchen mit Menschen abgeleiteten Gewichte.

Alle Vorschläge derselben Antwort verwenden denselben Referenzsatz und dieselbe Bezugszeit.
Der Prüfer begrenzt `D`, `A` und `C` auf den Bereich 0 bis 1.

| Messwert | Berechnung |
|---|---|
| Passende Referenzfahrten | Alle Referenzfahrten, deren Korridor den Endzustand an seinem Streckenfortschritt enthält. |
| Geschätzte Fahrzeit `E` | Verstrichene Zeit der Vorausberechnung plus kürzeste Restzeit aller passenden Referenzfahrten bis zum Abschnittsziel. |
| Bezugszeit `E0` | Kürzeste Restzeit aller Referenzfahrten ab dem Streckenfortschritt des Ausgangszustands. |
| Abstand `D` | Kleinster Abstand des Endzustands zu einem Korridor, gemessen in Korridorbreiten und auf 0 bis 1 begrenzt. |
| Zusätzliche Hilfe `A` | Dauer zusätzlicher Spielhilfe geteilt durch den Zeitraum. Gleichzeitige Hilfen zählen je Schritt höchstens einmal. |
| Ergänzungen `C` | Zahl ergänzter Aktionen geteilt durch zwei. Ausdrücklich verlangte Aktionen zählen nicht als Ergänzung. |

Erreicht ein Vorschlag das Abschnittsziel innerhalb des Zeitraums, gilt die tatsächlich gemessene Zeit als `E`.
`E0` hängt nur vom Ausgangszustand ab. Sie gilt deshalb für alle Vorschläge derselben Antwort.
Das Abschnittsziel bezeichnet eine festgelegte Position hinter der Kurve oder hinter der Landung.
Die Streckenprüfung legt diese Position vor der Bewertung fest.

Für den Vergleich mit dem Korridor zählen Bodenkontakt und tatsächlich berechnete Landekontakte.
Ein Flugzustand passt nur zu einem Flugzustand der Referenzfahrt.
Eine bloße Nähe zu einer Fahrfläche während des Flugs zählt nicht als Landung.

Für `A` zählt nur zusätzliche Hilfe innerhalb der Vorausberechnung.
Vorher verbrauchte Hilfe zählt nicht erneut.
Spurhilfe, automatische Tempoanpassung und zusätzliche Haltekraft zählen als Hilfe.
Schwerkraft, normale Fahrkräfte und ausdrücklich verlangte Aktionen zählen nicht als zusätzliche Hilfe.

### Berechnung des Nutzens

| Lage am Ende des Zeitraums | Nutzen | Bereich |
|---|---|---|
| Berechneter Absturz | `−1` | −1 |
| Ohne Absturz, außerhalb aller Korridore | `−0.5 + 0.4 × (1 − D)` | −0,5 bis −0,1 |
| Ohne Absturz, in mindestens einem Korridor | `0.1 + 0.7 × min(1, E0 / E) − 0.05 × A − 0.05 × C` | 0 bis +0,8 |

Damit gilt eine feste Reihenfolge.
Ein Zustand im Korridor ist besser als jeder Zustand außerhalb.
Ein Zustand ohne Absturz ist besser als ein Absturz.
Innerhalb des Korridors gewinnt die kürzeste erreichbare Fahrzeit.
Der Vertrag verlangt keinen Vorschlag mit dem Wert +1.
Der Prüfer normiert nicht nach dem besten und schlechtesten Vorschlag derselben Antwort.
Sonst könnte eine durchweg schlechte Auswahl einen scheinbar sehr guten Wert erzeugen.

Die Beispiele verwenden eine Bezugszeit `E0` von 4 Sekunden.

| Beispiel | Messwerte | Nutzen |
|---|---|---|
| Links ohne Bremse; Absturz innerhalb des Zeitraums. | Absturz. | −1,0 |
| Links ohne Bremse; zu schnell, aber noch kein Absturz. | Außerhalb aller Korridore, `D=0.6` | −0,34 |
| Links mit Bremsstärke 0,3; Korridor einer schnellen Referenzfahrt. | `E=4.2, A=0.2, C=0.5` | +0,73 |
| Links mit Bremsstärke 0,8; nur Korridor einer langsamen Referenzfahrt. | `E=5.5, A=0.2, C=0.5` | +0,57 |

Diese Beispielwerte erläutern die Formel. Sie sind keine gemessenen Fahrten.
Die bisherige Fahrsteuerung bietet die hier angenommene genaue Bremsstärke noch nicht an.
Die Spielanbindung darf solche Vorschläge erst nach einer entsprechenden Erweiterung des Fahrmodells anbieten.

Die Physik berechnet die Folgen. Das Bewertungsprofil legt ihre Bedeutung für das Spielziel fest.
Die Korridore bewerten nur geprüfte Zustände.
Außerhalb aller Korridore zeigt der Abstand nur eine Richtung zur nächsten geprüften Fahrt.
Er belegt keine sichere Rückkehr auf die Strecke.
`horizon_reached` bezeichnet deshalb keine erfolgreiche vollständige Fahrt.
Die Vollfahrtprüfung aus Abschnitt 16 ergänzt diese Grenze.

Eine negative Bewertung hebt eine ausdrückliche Anweisung nicht auf.
Bei „links“ vergleicht die leichte Hilfe weiterhin nur passende Vorschläge nach links.
Ein ausdrücklich gewählter schlechter Vorschlag bleibt ausführbar, sofern das Spiel seine Aktion tatsächlich unterstützt.

## 16 Automatische Prüfung neuer Level

### Prüfauftrag und Ablauf

Jedes neue Level erhält einen eigenen Prüfauftrag mit festen Fällen und erwarteten Ergebnissen.
Der Auftrag nennt Fahrmodell, Hilfsprofile, Schrittweite, Bewertungsprofil und Grenzen der Suche.
Die vorhandenen Stufen „Sehr leicht“ und „Leicht“ brauchen getrennte Ergebnisse.
Ein späteres Profil „Direkt“ erhält eigene Fälle erst nach seiner tatsächlichen Umsetzung.

| Stufe der Prüfung | Inhalt | Ergebnis |
|---|---|---|
| Daten und Geometrie | Pflichtfelder, Formverweise, Anschlüsse, Fahrflächen und mögliche Landeflächen prüfen. | Datenfehler oder gültige Grundlage für Fahrversuche. |
| Einzelne Abschnitte | Kurven, Kuppen, Rampen, Flug, Landung und Looping mit verschiedenen Zuständen durchfahren. | Messwerte und Fehler je Fall. |
| Übergänge | Das Ende einer Hilfe und den Beginn des nächsten Elements zusammen prüfen. | Keine übertragene Freigabe und keine erneuerte Restdauer. |
| Vollständige Fahrten | Vom tatsächlichen Start bis zum Ziel dieselben Bewegungsfunktionen und Eingaberegeln nutzen. | Nachspielbare Eingabefolge oder dokumentierter Abbruch. |
| Referenzsatz | Aus vollständigen Fahrten Referenzfahrten auswählen und ihre Korridore belegen. | Geprüfter Referenzsatz je Hilfsprofil mit Prüfsumme. |
| Wiederholung | Erfolgreiche und fehlgeschlagene Fälle mit denselben Daten erneut ausführen. | Übereinstimmung innerhalb festgelegter Toleranzen. |

Der Prüfer nutzt zunächst aus vollständigen Fahrten erreichte Zustände als Ausgangspunkte.
Er ergänzt gezielt künstliche Randzustände.
Der Bericht unterscheidet beide Gruppen. Ein künstlicher Zustand belegt keine Erreichbarkeit im normalen Spiel.

### Anfangsauswahl der Fälle

Die vorhandene Auswahl enthält die Starttempi 0, 5, 14, 22, 35, 46 und 58 Meter pro Sekunde.
Der neue Prüfauftrag übernimmt diese Werte nur, wenn das aktive Modell und Profil sie unterstützen.
Tempo 0 prüft zunächst den Stillstand und anschließend das Anfahren nach einer ausdrücklichen Eingabe.
Eine gewollte Vollbremsung braucht keinen erfolgreichen Zieleinlauf als Ergebnis.

| Fallgruppe | Vorgeschlagene Fälle |
|---|---|
| Seitliche Lage | Spurmitte sowie jeweils 0,5 Meter links und rechts. |
| Seitenbewegung | Keine Seitenbewegung sowie jeweils 0,5 Meter pro Sekunde nach links und rechts. |
| Eingabezeit | Frühe, passende, späte und sehr späte Eingabe, soweit das Hilfsfenster diese Phasen enthält. |
| Grenzen | Ein Modellschritt vor, auf und nach einer Zeitgrenze. Position jeweils 0,01 Meter neben einer Grenze. |
| Tempogrenzen | Geprüfte Übergänge jeweils mit 0,1 Meter pro Sekunde Abstand auf beiden Seiten. |
| Eingabeverhalten | Passende Richtung, gegensätzliche Richtung, fehlende Eingabe, Ruf und ausdrückliche Kombination. |
| Tempoaktionen | Beschleunigen, Vollbremsen und wechselnde Tempobefehle. |
| Restdauer der Hilfe | Volle Restdauer, ein verbleibender Schritt und bereits verbrauchte Hilfe. |
| Unterbrechung | Pause, Fortsetzung, Neustart und Verlust der Eingabequelle. |
| Referenzsatz | Zustände im Korridor, auf seiner Grenze und knapp außerhalb; überlappende Korridore; Endzustand im Flug. |
| Aktualität | Eingabe mit frischer Antwort, mit abgelaufener Antwort und mit geänderter `decision_revision`. |

Die Leveldaten und das Modell liefern die tatsächlich geltenden Grenzen.
Der Prüfer darf nicht für alle Elemente dieselbe Fahrbahnbreite oder dasselbe Mindesttempo annehmen.
Eine Suche nach Tempogrenzen prüft zuerst ein Raster im erlaubten Bereich.
Sie verfeinert danach Übergänge zwischen Erfolg und Fehler.
Sie darf ohne weitere Prüfung keine einzelne durchgehende Erfolgszone annehmen.

Die Fälle für Unterbrechungen verwenden zusätzlich die tatsächliche Zustands- und Eingabeverarbeitung.
Eine Prüfung nur der Bewegung reicht für Pause oder alte Eingaben nicht aus.
Bei gegensätzlichen ausdrücklichen Befehlen prüft der Fall die verlangte Wirkung.
Er verlangt keine heimliche Richtungskorrektur und nicht zwingend eine erfolgreiche Fahrt.

### Suche nach einer vollständigen Fahrt

Der Levelprüfer darf mehrere Anweisungen über eine Fahrt verteilen.
Eine feste Vergleichssteuerung verwendet zunächst die Streckenrichtung und die erlaubten Tempoaktionen.
Sie ruft dieselbe Bewertungs- und Ausführungsschnittstelle wie die spätere Hilfe auf.
Sie verändert weder Position noch Geschwindigkeit direkt, um einen Abschnitt zu bestehen.

Zusätzlich darf der Prüfer alternative Eingabezeiten, Stärken und Kombinationen untersuchen.
Er verwendet dafür vollständige Zustandskopien an den festgelegten Entscheidungspunkten.
Ein Suchzweig enthält die bereits ausgeführten Aktionen, den erreichten Zustand und die verbleibende Hilfe.
Eine Wiederholung eines Zweigs darf keine Hilfsdauer erneuern.

Der vorgeschlagene erste Suchlauf behält höchstens 32 Zweige je Entscheidungspunkt.
Er prüft pro Zweig höchstens die 24 Vorschläge aus Abschnitt 14.
Er beendet eine vollständige Fahrt spätestens nach 18.000 äußeren Modellschritten, entsprechend 300 Sekunden.
Der Prüfauftrag begrenzt zusätzlich die Gesamtzahl der Zweige und Modellschritte über alle Fälle je Profil.
Die vorgeschlagenen Anfangsgrenzen betragen 4.096 gestartete Zweige und 2.000.000 äußere Modellschritte je Profil.
Diese Gesamtgrenzen gehören vor dem Start in den Bericht. Ihr Ablauf beendet die Suche mit `incomplete`.
Ein weiterer Lauf mit höheren Grenzen erhält einen neuen Prüfauftrag und eigene Ergebnisse.

Die Auswahl der Zweige erfolgt zuerst nach vermiedenen Abstürzen und dann nach erreichtem Streckenfortschritt.
Bei Gleichstand berücksichtigt sie den geringeren Verbrauch der Hilfe und anschließend die kürzere Fahrzeit.
Eine gefundene Fahrt erhält eine vollständige Eingabefolge und eine Wiederholung vom regulären Start.
Eine erfolglose begrenzte Suche beweist nicht, dass das Level unlösbar ist.

### Erzeugung der Referenzfahrten

Bei dieser Suche gibt es noch keinen Referenzsatz.
Die Suche ordnet die Zweige deshalb nur nach der oben genannten Reihenfolge. Sie verwendet keinen Nutzenwert aus Abschnitt 15.

Jede gefundene vollständige Fahrt ist ein Kandidat für den Referenzsatz.
Der Prüfer ergänzt gezielt Varianten mit anderer Linie, anderem Tempo oder anderem Bremspunkt.
Ein Kandidat verwendet nur Aktionen und Hilfen, die sein Hilfsprofil erlaubt.
Jeder Kandidat muss vom regulären Start aus mit derselben Eingabefolge wiederholbar sein.

Der Prüfer ermittelt danach den Korridor jedes Kandidaten:

1. Lege Prüfpunkte entlang der Fahrt fest: zunächst alle 5 Meter Streckenfortschritt sowie an jedem Abschnittsbeginn, Absprung und jeder Landung.
2. Verschiebe an jedem Prüfpunkt Seitenlage, Seitenbewegung, Tempo und Ausrichtung einzeln in Rasterstufen nach beiden Seiten.
3. Fahre von jedem verschobenen Zustand mit der festen Vergleichssteuerung bis zum nächsten Abschnittsziel.
4. Setze die Grenze auf die letzte Stufe ohne Absturz und mit einer Restzeit innerhalb der Toleranz. Die Toleranz beträgt zunächst 10 Prozent der Restzeit der Referenzfahrt.
5. Verfeinere jede Grenze zwischen der letzten erfolgreichen und der ersten fehlgeschlagenen Stufe.
6. Prüfe zusätzlich alle Ecken des Korridors mit gleichzeitiger Abweichung aller Werte. Verkleinere den Korridor, bis alle Ecken bestehen.

Zwischen zwei Prüfpunkten gilt der kleinere Korridor der beiden benachbarten Prüfpunkte.
Die verschobenen Zustände sind künstliche Zustände. Der Bericht kennzeichnet sie entsprechend.

Der Referenzsatz enthält zunächst höchstens 8 Referenzfahrten je Level und Hilfsprofil.
Der Prüfer entfernt einen Kandidaten, wenn ein anderer Kandidat überall einen größeren Korridor und keine längere Restzeit hat.
Die schnellste geprüfte Fahrt bleibt immer im Referenzsatz.
Der Bericht nennt, welcher Anteil der regulär erreichten Prüfzustände in mindestens einem Korridor liegt.

Nach der Erzeugung prüft der Prüfer die Bewertung im Spiel selbst.
Die feste Vergleichssteuerung fährt dafür mit kurzer Vorausberechnung und Referenzsatz gemäß Abschnitt 14 vom Start bis zum Ziel.
Diese Fahrt zählt zu den Pflichtfällen.

Alle Pflichtfälle stehen vor der Suche fest.
Der Prüfer darf schwierige Fälle nicht nachträglich aus der Liste entfernen.
Nach einer Anpassung der Bewertungsregeln folgt eine getrennte Abnahme mit zuvor zurückgehaltenen Fällen.
So prüft die Abnahme auch Zustände, die nicht zur Wahl der Gewichte und Suchwerte dienten.

### Ergebnis und Abnahme

| Status | Bedeutung |
|---|---|
| `passed` | Alle festgelegten Pflichtfälle lieferten ihr erwartetes Ergebnis und bestanden die Wiederholung. |
| `failed` | Mindestens ein vollständig geprüfter Pflichtfall verletzt sein festgelegtes Sollverhalten. |
| `incomplete` | Mindestens ein Pflichtfall bleibt ungeprüft, ohne gültige Grundlage oder außerhalb der Rechengrenze. |

Ein vorsätzlich falscher Befehl darf einen Absturz ergeben und trotzdem seinen Testfall bestehen.
Ein vorgesehener regulärer Durchlauf darf dies nicht.
Der Bericht nennt deshalb für jeden Fall Sollverhalten und tatsächliches Ergebnis.
Ein Fehler hat im Gesamtstatus Vorrang vor einer unvollständigen Prüfung.
Ohne Fehler, aber mit offenen Pflichtfällen bleibt der Gesamtstatus `incomplete`.

Der neue Abnahmebericht muss für `passed` mindestens eine vollständige reguläre Fahrt je gefordertem Hilfsprofil enthalten.
Er muss außerdem je gefordertem Hilfsprofil einen Referenzsatz mit belegten Korridoren enthalten.
Er bestätigt nur die bezeichneten Fälle und Bereiche.
Der spätere neue Abnahmeweg übernimmt weder `failed` noch `incomplete` als erfolgreiche Freigabe.
Die vorhandene Funktion `Verification.playable` prüft derzeit nur die passende Prüfsumme und `clean_completed`.
Sie setzt die hier beschriebene umfassendere Abnahme noch nicht um.

## 17 Prüfberichte und weitere Bewertungsverfahren

Jeder Bericht enthält Level, Modellfassung, Hilfsprofil, Schrittweite und vollständige Fallliste.
Er enthält außerdem Bewertungsfassung, Suchprofil, Folgeeingaberegel, Rechengrenzen und gegebenenfalls Zufallswerte.
Zu jedem Fall gehören Ausgangszustand, Aktionen, Messwerte, Endegrund und nachspielbarer Verlauf.
Erfolgreiche und fehlgeschlagene Fälle bleiben im Bericht erhalten.

Eine gemeinsame Prüfsumme erfasst alle Dateien und Daten, die Bewegung, Auswahl oder Bewertung beeinflussen.
Dazu gehören auch die Regeln für Zustandskopien, die Ausführung von Kombinationen und der Referenzsatz mit seinen Korridoren.
Eine Änderung am Fahrmodell oder an der Strecke verlangt einen neu erzeugten Referenzsatz.
Eine Änderung dieser Grundlagen macht die betroffenen Bewertungen und Abnahmen ungültig.
Ein reiner Austausch sichtbarer Modelle darf die Gültigkeit nur erhalten, wenn er keine geprüfte Fahr- oder Kollisionsgeometrie verändert.

Gespeicherte Einzelbewertungen gelten zunächst nur für den vollständig passenden Zustand.
Eine spätere Zusammenfassung ähnlicher Zustände braucht eigene Abweichungsgrenzen und Prüfungen.
Eine einzelne erfolgreiche Fahrt liefert keine Erfolgswahrscheinlichkeit.
Der Anteil erfolgreicher Varianten beschreibt ausschließlich die angegebenen Varianten und ihre Verteilung.

Jev, Clef oder ein späteres eigenes Modell dürfen zusätzliche Vorschläge vorbereiten.
Eine weitere Möglichkeit wäre ein Modell, das die Ergebnisse vieler geprüfter Fahrten nachbildet.
Beide Erweiterungen brauchen einen Vergleich mit zurückgehaltenen Fahrfällen und eigene Zeitmessungen.
Die erste Fassung benötigt weder externes Modelltraining noch Modellzugriffe im laufenden Spiel.
Die Auswahlregeln und die ausdrückliche Anweisung bleiben von der Herkunft einer Bewertung unabhängig.

## 18 Prüfung der vorhandenen Grundlage bei dieser Ergänzung

Die folgenden bestehenden Programme liefen bei der Ergänzung erneut.
Sie bestätigen vorhandene Grundlagen. Sie bestätigen keine Umsetzung der neuen Bewertung oder Levelprüfung.

| Prüfung | Ergebnis |
|---|---|
| `tests/spatial/test_verification.gd` | 10 Bedingungen, 0 Fehler. |
| `tests/spatial/test_boundaries.gd` | 11 Bedingungen, 0 Fehler. |

Die erste Prüfung vergleicht wiederholte Fahrten und die Bewegung des Prüfprogramms mit dem tatsächlichen Spielmodell.
Die zweite Prüfung untersucht unter anderem Sprungtempo, Landebreite, Aufprallgrenzen und verbrauchte Hilfsdauer.
Beide Programme beendeten ihre Prüfungen mit Rückgabewert 0.
Godot meldete erneut den Fehler beim Lesen der Systemzertifikate.
Die neue automatische Prüfung beliebiger Level bleibt ein Entwurf.

# Gemeinsame Schnittstelle für barrierefreie Spielsteuerung

Datum: 17. Oktober 2026

Status: Entwurf zur Prüfung durch Stefan. Dieser Auftrag umfasst keine Umsetzung.

Die Schnittstelle verbindet Eingaben, bewertete Spielaktionen und Hilfestufen.
Das Spiel bewertet mögliche Aktionen und Kombinationen anhand seines aktuellen Zustands.
Das Steuerungsmodul wählt daraus einen Vorschlag, der zur Anweisung des Spielers passt.
Eine ausdrückliche Anweisung hat auf jeder Hilfestufe Vorrang vor einer besseren Bewertung.
Stuntcar beginnt mit einfachen Hinweisen aus den Streckendaten und vorhandenen Spielregeln.
Eine spätere Erweiterung vergleicht wenige Pläne mit dem tatsächlichen Fahrmodell.
Gespeicherte Referenzfahrten bilden keine Voraussetzung für Hinweise oder Bewertungen.
Der Spieler entscheidet. Hinweise allein starten keine Aktion.
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
- Die gemeinsame Steuerung soll auch für andere Spiele nutzbar sein.
- Der Umbau soll schrittweise erfolgen. Einfache Hinweise kommen vor einer laufenden Vorausberechnung.

Der aktuelle Vorschlag ersetzt die frühere Bewertung anhand gespeicherter Referenzfahrten.
Die spätere Vorausschau muss den entscheidenden Ausgang erfassen, etwa die Landung hinter einem Sprung.

Die folgenden Datenfelder und Auswahlregeln konkretisieren diese Vorgaben als Vorschlag.
Ein öffentlicher Vorschlag enthält zunächst nur gleichzeitig beginnende Aktionen.
Die spätere Bewertung darf intern zeitlich getrennte Schritte untersuchen.
Diese internen Pläne erteilen keine Erlaubnis für spätere Aktionen.
Eine vollständige Levelprüfung darf mehrere Anweisungen über die Fahrt verteilen.
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

### Vorgeschlagene Schritte des Umbaus

| Schritt | Inhalt | Grenze vor dem nächsten Schritt |
|---|---|---|
| 1 Zuständigkeiten trennen | Eingabequellen, gemeinsame Anweisung, Auswahl nach Hilfestufe und Spielanbindung getrennt beschreiben und später herauslösen. | Die bestehende Richtungskorrektur bleibt als Altverhalten sichtbar. Sie erfüllt den neuen Vertrag nicht. |
| 2 Gemeinsamen Vertrag nutzbar machen | Tatsächliche Aktionswirkung, Beginn, Ende und ausdrückliche Richtungen in beiden Fahrmodellen herstellen. Vorhandene Schilder und einfache Hinweise anbinden. | Eine falsche ausdrückliche Richtung wirkt tatsächlich falsch. Kein Hinweis darf sie ersetzen. |
| 3 Einfache Hilfe ergänzen | Einzelaktionen und relevante Kombinationen anhand aktueller Spielregeln bewerten. Ein zweites kleines Spiel prüft die allgemeinen Grenzen. | Hilfestufen, Quellenverlust und gemeinsame Ausführung bestehen die Abnahme. Die Hilfe braucht keine Vorausberechnung. |
| 4 Vorausberechnung erproben | Wenige Pläne bis hinter den entscheidenden Abschnitt vergleichen. Nur eine bereits erlaubte unmittelbare Aktion ergänzen. | Zeitversatz, vollständige Zustandskopien und getrennte Abnahmefälle bestehen auch mit Darstellung. |

Schritt 1 ist eine vorbereitende Trennung. Er erklärt das heutige Verhalten nicht nachträglich für vertragskonform.
Ein erster nutzbarer gemeinsamer Steuerungsweg braucht mindestens Schritt 2.
Die Schritte sind ein Vorschlag für einen späteren Auftrag. Dieser Auftrag ändert nur den Entwurf.
Die Hinweise können bereits ohne automatische Hilfe Nutzen bieten.
Das Paket muss ohne Vorausberechnung funktionieren.

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
Vor einer Ergänzung verlangt das Modul eine gültige Antwort für die aktuelle `decision_revision`.
Eine ausdrückliche Anweisung bleibt auch ohne Bewertung ausführbar.

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
| `max_duration_ms` | Höchste Dauer je Bestätigung oder Verlängerung. Bei einem Impuls gilt 0. |
| `max_update_gap_ms` | Höchster Abstand frischer Nachrichten bei einer gehaltenen Aktion; sonst 0. |
| `exclusive_group` | Gruppe von Aktionen, die sich gegenseitig ausschließen. |
| `reference_frame` | Bezug einer Richtung, etwa die eigene Spielfigur. |
| `effect` | Beschreibung der tatsächlichen Wirkung und ihres Endes. |

Ein Spiel kann beispielsweise `steer_left`, `steer_right`, `brake` und `jump` anbieten.
`steer_left` und `steer_right` gehören zur gleichen Ausschlussgruppe.
Eine Kombination darf keine widersprüchlichen Mitglieder derselben Ausschlussgruppe enthalten.
Aktionen mit begrenzter Dauer brauchen positive Standard- und Höchstdauern.
Die Standarddauer darf die Höchstdauer nicht überschreiten.
Eine gehaltene Aktion braucht einen positiven Wert für `max_update_gap_ms`.
Ihr bestätigtes Ende liegt spätestens bei der letzten frischen Nachricht plus `max_update_gap_ms`.

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
| `control_revision` | Positive, je `control_id` streng steigende Nummer für Beginn, Änderungen und Ende. |
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
Bei `begin` verlangt dieser Zustand mindestens eine ausdrückliche Aktion.
Bei `end` darf die Aktionsliste leer sein. Die `control_id` bestimmt die beendeten Mitglieder.
`activate` bezeichnet ein persönlich eingerichtetes Signal ohne ausdrückliche Spielaktion.
Ein geeigneter Ruf wie „blub“ kann ein solches Signal sein.
`unresolved` bedeutet, dass die Eingabeanbindung keine sichere Anweisung liefert.
Dieser Zustand darf keine freie Aktionsauswahl auslösen.
`cancel` beendet die gehaltenen Aktionen der bezeichneten Eingabequelle.

Jede Änderung erhält eine neue `event_id` und behält dieselbe `control_id`.
Das Spiel speichert die höchste angenommene `control_revision` je Sitzung, Quelle und `control_id`.
Es verwirft ältere oder gleiche Nummern ohne neue Wirkung und ohne Verlängerung.
Nach `end` bleibt diese `control_id` beendet. Ein neuer Beginn braucht eine neue `control_id`.
Eine ersetzte Aktion bleibt ebenfalls beendet. Eine alte Verlängerung darf sie nicht erneut starten.
Ein einzelner Impuls verwendet nur `begin` und endet nach der festgelegten Wirkung.
Eine gehaltene Eingabe verwendet `begin`, danach mögliche `update` und zuletzt `end`.
`update` darf keinen neuen Impuls auslösen.
Die Eingabeanbindung muss eine anhaltende Geste deshalb von einer neuen Geste unterscheiden.

Der Katalog legt für jede gehaltene Aktion eine Frist für frische `update`-Nachrichten fest.
Frisch bedeutet auch: Die Erfassungszeit liegt höchstens `max_update_gap_ms` vor der aktuellen Sitzungszeit.
Eine verspätete Nachricht verlängert eine Aktion nicht durch ihre späte Ankunft.
Ein frisches `update` darf nur die noch gehaltenen Mitglieder verlängern, jeweils höchstens um `max_duration_ms` ab dieser Nachricht.
Ohne frisches `update` endet jedes Mitglied spätestens an seinem bestätigten Ende.
Eine Verlängerung erzeugt keinen neuen Impuls. Die Bestätigung nennt das neue Ende je Mitglied.
`end` beendet nur die Mitglieder der bezeichneten `control_id`.
Für getrennte Quellen und getrennte Tasten bleiben die Enden getrennt.
`update.required_actions` nennt den vollständigen noch gehaltenen Satz dieser `control_id`.
Ein dort fehlendes bisher gehaltenes Mitglied endet. Andere Quellen bleiben davon unberührt.
Eine gemeinsame Kombinationsphrase endet nach den bestätigten Dauern ihrer Mitglieder.
Die erste Fassung unterstützt keinen gesprochenen Teilabbruch einer solchen Phrase.

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
| `horizon_ms` | Maximale Dauer der Vorausberechnung. Bei reinen Regeln gilt 0. |
| `scoring_version` | Fassung der Bewertungsregeln. |
| `assessment_method` | `rules_only` für einfache Regeln oder `lookahead` für die spätere Vorausberechnung. |
| `hints` | Hinweise des Spiels nach Abschnitt 14. Hinweise starten keine Aktion. |
| `evaluation_context` | Bei Vorausberechnungen: Zustand, Schrittweite, Folgeeingaben und Grenzen der Suche gemäß Abschnitt 14. |
| `proposals` | Liste der Einzelaktionen und Kombinationen. |

Das Spiel bewertet alle Vorschläge einer Antwort anhand desselben Zustands, Ziels, Zeitraums und Hilfsprofils.
Werte aus verschiedenen Antworten dürfen nicht gemeinsam eine Rangfolge bilden.
Ein Wechsel von Modell, Katalog, Hilfsprofil, Bewertungsregeln oder `decision_revision` macht vorherige Antworten ungültig.
Eine gleiche `decision_revision` und eine offene Zeitfrist genügen nicht für eine Ergänzung.
Das Spiel prüft zusätzlich den aktuellen Zustand nach Abschnitt 9.

| Feld je Vorschlag | Bedeutung |
|---|---|
| `proposal_id` | Innerhalb der Antwort eindeutige Kennung. |
| `actions` | Vollständige Liste der Aktionen samt Parametern und Dauer. |
| `available` | Kann das Spiel alle Aktionen gemeinsam ausführen? |
| `rating_status` | `rated` oder `unknown`. |
| `utility` | Nutzen zwischen −1 und +1; bei `unknown` gilt `null`. |
| `reason_code` | Eindeutiger Grund für Nutzen, Unverfügbarkeit oder fehlende Bewertung. |
| `evidence` | `rule`, `simulated`, `tested_samples` oder `unknown`. |
| `outcome_status` | Bei Vorausberechnung: `goal_reached`, `finished`, `open`, `crashed` oder `unknown`; sonst `null`. |

`rule` bezeichnet eine Bewertung aus Spielregeln.
`simulated` bezeichnet eine neue Vorausberechnung mit dem tatsächlichen Spielmodell ab dem angegebenen Zustand.
Bei Stuntcar bewertet sie die berechneten Folgen bis zum gemeinsamen Abschnittsziel nach Abschnitt 15.
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

1. Prüfe Sitzung und Frist der Eingabe. Prüfe die Bewertungsgrundlage nur für mögliche Ergänzungen.
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

Für automatische Ergänzungen und `activate` gilt zusätzlich eine Grenze bei Vorausberechnungen.
Ein Vorschlag mit `outcome_status: crashed` darf keine Ergänzung oder freie Rufauswahl begründen.
Das Spiel behält ihn als negative Information und als ausdrücklich ausführbare Aktion in der Antwort.
Fehlt dadurch ein wählbarer Vorschlag, bleibt die ausdrückliche Anweisung ohne Ergänzung.
Ein Ruf startet dann keine neue Aktion. Ein offener Ausgang erhält dafür keinen erfundenen Zahlenwert.

Für `activate` gilt die freie Auswahl nur im erlaubten Hilfsfenster auf „Sehr leicht“.
Das Modul berücksichtigt dabei auch den bewerteten Vorschlag „keine neue Aktion“.
Auch bei ausschließlich negativen Regelwerten gewinnt der höchste zulässige Wert.
Die zusätzliche Grenze für berechnete Abstürze bleibt bestehen.
Ohne verfügbaren, bewerteten Vorschlag startet `activate` keine Aktion.
Ohne Eingabe startet das Modul grundsätzlich keine neue Spielaktion.
Es darf weiterhin Hinweise anzeigen.

## 8 Regeln je Hilfestufe

| Regel | Sehr leicht | Leicht | Direkt als spätere Stufe |
|---|---|---|---|
| Ausdrückliche Richtung erhalten | Ja | Ja | Ja |
| Ausdrückliche Kombination erhalten | Ja | Ja | Ja |
| Passende Aktionen ergänzen | Ja | Ja | Nein |
| Bestes Ergebnis nach einem geeigneten Ruf wählen | Ja, im gültigen Hilfsfenster | Nein | Nein |
| Eine schlechte Anweisung allein wegen ihrer Bewertung ablehnen | Nein | Nein | Nein |
| Ohne Eingabe eine neue Spielaktion starten | Nein | Nein | Nein |

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
- Hilfsprofil, Katalog, Modell oder Bewertungsregeln wechseln.
- Bodenkontakt, Flug, Landung oder verfügbare Hilfsdauer ändern die geltenden Bedingungen.
- Pause, Fortsetzung, Neustart oder Quellenverlust treten ein.

Die Frist begrenzt die Gültigkeit nur nach oben.
Vor jeder Ergänzung prüft das Spiel auch, ob die Bewertungsgrundlage im aktuellen Zustand noch gilt.
Einfache Regeln prüfen dafür ihre aktuellen Bedingungen erneut.
Eine vorberechnete Antwort braucht einen gesondert geprüften Bereich für Zustand und möglichen Startverzug.
Ohne diesen Nachweis darf sie nur für den exakt passenden Ausgangszustand gelten.
Erfolgreiche Einzelproben belegen keinen ganzen Bereich zwischen den Proben.
`apply` prüft diese Grundlage und die Verfügbarkeit unmittelbar vor dem Start.
Bei einer ungültigen Grundlage startet es nichts und meldet `stale`.
Eine neue Bewertung oder die unveränderte ausdrückliche Anweisung folgt danach.
Eine verspätete Empfehlung darf den passenden Bremspunkt nicht still überschreiten.
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

Eine spätere ausdrückliche Gegenanweisung ersetzt die ältere ausdrückliche Aktion derselben Ausschlussgruppe.
Sie beendet außerdem eine widersprechende Hilfe dieser Gruppe.
Andere Gruppen behalten ihr bestätigtes Ende.
Für diese Reihenfolge zählt die Annahme im Spielschritt. Gleichzeitige Gegenanweisungen behandelt die folgende Regel.
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
  "horizon_ms": 0,
  "assessment_method": "rules_only",
  "hints": [],
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
      "evidence": "rule",
      "outcome_status": null
    },
    {
      "proposal_id": "links_bremsen",
      "actions": [
        {"action_id": "steer_left", "parameters": {"amount": 1.0}, "duration_ms": 500},
        {"action_id": "brake", "parameters": {"amount": 0.3}, "duration_ms": 800}
      ],
      "available": true,
      "rating_status": "rated",
      "utility": 0.8,
      "reason_code": "kurvenrichtung_und_tempo",
      "evidence": "rule",
      "outcome_status": null
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
      "evidence": "rule",
      "outcome_status": null
    },
    {
      "proposal_id": "keine_neue_aktion",
      "actions": [],
      "available": true,
      "rating_status": "rated",
      "utility": -0.4,
      "reason_code": "kurve_ohne_lenkeingabe",
      "evidence": "rule",
      "outcome_status": null
    }
  ]
}
```

Bei „links“ ergänzt die leichte Hilfe hier die Bremse mit Stärke 0,3.
Die Bewertung 0,8 bestimmt die Auswahl. Sie bestimmt nicht die Bremsstärke.
Bei „rechts“ führt die negative Bewertung nicht zur Auswahl von links.
Ohne passenden Zusatzvorschlag führt das Spiel rechts ohne Ergänzung aus.
Auf „Direkt“ führt das Spiel bei „links“ ausschließlich die ausdrückliche Aktion aus.

## 11 Eignung für Stuntcar

Die Codeprüfung bezieht sich auf den vorhandenen Stand mit beiden Fahrmodellen.
Die aktuelle Ergänzung prüft die Steuerungsdateien erneut am Stand `5a37796`.
Die gesonderten Landschaftsänderungen gehören nicht zu diesem Auftrag.
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
| [Vorhandene Streckenprüfung](../../../tools/spatial/check_drives.gd) | Erstellt reguläre Fahrten und Berichte je Hilfsprofil. | Die Fallauswahl, die Suche und die Abnahmeregeln aus Abschnitt 16 müssen hinzukommen. |
| [Streckenschilder](../../../scripts/track/track_builder.gd) und [Anzeige](../../../scripts/ui/game_ui.gd) | Nutzen die bekannte Kurvenrichtung bereits für Hinweise. | Anzeige und Steuerung müssen dieselbe aktuelle Hinweisgrundlage nutzen. |

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
| Alle Werte des Regelprofils sind negativ. | Der höchste gültige Wert gewinnt; auch keine neue Aktion nimmt am Vergleich teil. |
| Ohne Ergänzung bleibt die Simulation offen; eine Ergänzung führt zum Absturz. | Die ausdrückliche Anweisung startet ohne Ergänzung. Ein Ruf startet keine neue Aktion. |
| Zwei Änderungen derselben gehaltenen Eingabe treffen in umgekehrter Reihenfolge ein. | Nur die höhere `control_revision` wirkt. Die ältere Nachricht verlängert nichts. |
| Nach Ende oder Gegenbefehl trifft eine alte Verlängerung ein. | Die beendete Aktion bleibt beendet. |
| Eine Aktion wirkt nach dem Abschnittsziel noch weiter. | Die Prüfung erfasst Restwirkung und Übergabe. Die Zwischenmarke allein bestätigt keine vollständige Aktionsprüfung. |
| Der Ruf trifft auf Leicht ein. | Der Ruf startet keine freie Auswahl. |
| Ein ausdrücklicher Befehl scheitert. | Das Modul behandelt ihn nicht als Ruf. |
| Eine Teiläußerung bleibt unklar. | Sie startet keine freie Auswahl. |
| Eine Nachricht trifft doppelt ein. | Sie erzeugt keine zweite Wirkung. |
| Pause, Neustart oder Quellenverlust treten ein. | Alte Eingaben und laufende Hilfen wirken nicht weiter. |
| Die Bewegung ändert sich zwischen Bewertung und Start, `decision_revision` bleibt gleich. | Das Spiel prüft auch die Zustandsbedingungen. Ohne gültige Grundlage entfallen die Ergänzungen. |
| `decision_revision` ändert sich zweimal vor dem Start. | Die ausdrückliche Aktion startet ohne Ergänzung. |
| Eine Eingabe trifft ohne gültige Antwort ein. | Die ausdrückliche Aktion startet ohne Ergänzung; `activate` startet keine Aktion. |
| Ein Hinweis stammt nur aus einzelnen erfolgreichen Tempoproben. | Er verspricht keinen durchgehend sicheren Tempobereich. |
| Ein Flug endet erst nach dem Rechenzeitraum. | Die Landung bleibt offen. Der Vorschlag erhält keine Erfolgszusage. |
| Ein zeitlich verzögerter Plan gewinnt bei jeder neuen Rechnung. | Die Prüfung erkennt ein dauerhaftes Verschieben ohne Fortschritt. |
| Die Rechengrenze lässt keinen Platz für Ergänzungen. | Die ausdrückliche Aktion bleibt erhalten. Kombinationen erhalten reservierte Prüfplätze. |
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

## 14 Einfache Hinweise und spätere Vorausberechnung

### Einfache Hinweise als erster nutzbarer Schritt

Das Spiel kennt seine Regeln und die nächsten Hindernisse.
Es kann daraus Hinweise liefern, ohne mehrere Fahrverläufe vorauszuberechnen.
Die gemeinsame Steuerung muss weder Kurven noch Sprünge verstehen.
Die Spielanbindung übersetzt die Anforderungen in Aktionsvorschläge und verständliche Hinweise.

Ein Hinweis beschreibt eine Anforderung. Er erteilt keine Anweisung an das Fahrzeug.
Ein sichtbares Schild, ein gesprochener Hinweis und eine mögliche Ergänzung verwenden dieselbe Grundlage.
Nur die bewusste Eingabe des Spielers und die Hilfestufe erlauben eine Ausführung.
Ein Hilfsfenster allein erlaubt keine neue Aktion.

| Bekannte Anforderung des Spiels | Möglicher Hinweis | Grenze |
|---|---|---|
| Die nächste Kurve verlangt links. | „Links lenken.“ | Das ist eine Streckenanforderung. Eine ausdrückliche Rechtsanweisung bleibt rechts. |
| Das Tempo liegt über einem gültigen Zielbereich am Kurveneingang. | „Vor der Kurve langsamer.“ | Der Hinweis behauptet nicht, dass die verbleibende Bremsstrecke ausreicht. |
| Der nächste Sprung verlangt ein Mindesttempo. | „Vor dem Sprung beschleunigen.“ | Gilt nur für die angegebene Absprunglage und die geltenden Bedingungen. |
| Ein Plattformspiel kennt die Sprungweite und eine Lücke. | „Springen.“ | Nur bei einem tatsächlich vorhandenen Sprungbefehl und bekanntem Auslösebereich. |
| Die Anbindung kennt keinen passenden Bereich. | Keine genaue Tempogrenze anzeigen. | Eine unbekannte Grenze ist weder null noch eine allgemeine Freigabe. |

### Daten und Geltung eines Hinweises

`assess` liefert Hinweise im Feld `hints`. Eine eigene neue Nachrichtenverbindung ist dafür nicht nötig.
Jeder Hinweis enthält die folgenden Daten:

| Feld | Bedeutung |
|---|---|
| `hint_id` und `opportunity_id` | Kennung des Hinweises und des zugehörigen Hilfsfensters. |
| `message_key` und `message_parameters` | Spielseitiger Textschlüssel und seine Werte für die Anzeige. |
| `recommended_actions` | Passende Aktionskennungen. Die Liste führt keine Aktion aus. |
| `evidence` | `rule`, `tested_samples`, `simulated` oder `unknown`. |
| `applies_when` | Spielseitig prüfbare Bedingungen einschließlich Abschnitt, Zustand und Hilfsprofil. |
| `valid_until_ms` | Zusätzliche äußerste Zeitgrenze. |
| `game_details` | Optionale Angaben des Spiels, etwa Anforderungen am Kurveneingang. |

Das Modul behandelt `game_details` als Angaben des Spiels. Es berechnet daraus keine eigene Fahrphysik.
Stuntcar kann dort die erforderliche Richtung, den Eingangsbereich und passende Tempobereiche nennen.
Jeder Tempobereich nennt Einheit, Mindestwert, Höchstwert und Grundlage. Unbekannte Grenzen erhalten `null`.
Der Wert gilt am bezeichneten Eingang, nicht automatisch an jeder Stelle der Anfahrt oder im Flug.
Mehrere getrennte gültige Bereiche bleiben getrennt. Die Anbindung verbindet sie nicht zu einem größeren Bereich.

Eine feste Spielregel darf einen Bereich verbindlich definieren.
Ein vorgegebener Hilfswert bezeichnet dagegen nur ein Ziel der Hilfe.
Einzelne erfolgreiche Fahrproben belegen zunächst nur die geprüften Zustände.
Sie beweisen weder die dazwischenliegenden Tempi noch eine allgemeine Höchstgeschwindigkeit.
Die Anzeige muss diese Unterschiede erhalten, etwa „empfohlenes Tempo“ statt „sichere Höchstgeschwindigkeit“.

Bei Stuntcar liefern `turn_sign`, die Hilfsfenster und die vorhandenen Schilder bereits die Richtungsgrundlage.
`StuntAssist.limits` liefert überwiegend vorgegebene Zielbereiche für die Hilfe.
`Verification.speed_hint` verlangt passende Zustände und Prüfsummen.
Diese Grundlagen dürfen nicht still dieselbe Aussage über eine sichere Durchfahrt erhalten.

### Eine einfache Bewertung aus Regeln

Das erste Profil `stuntcar_rules_v1` nutzt aktuelle Anforderungen und tatsächlich ausführbare Aktionen.
Es prüft die Bedingungen beim Ausführen einer Ergänzung erneut.
Die einfache Hilfe muss keine allgemein beste Fahrt finden.
Sie kann erkennbare Fehler benennen und passende Ergänzungen anbieten.

| Lage unter den geltenden Bedingungen | Beispielwert | Grund |
|---|---:|---|
| Passende Richtung und passende erforderliche Tempoergänzung. | +0,8 | Die Kombination erfüllt beide bekannten Anforderungen. |
| Passende Richtung; keine Tempoergänzung erforderlich. | +0,6 | Der Vorschlag erfüllt die bekannte Anforderung. |
| Passende Richtung, aber eine bekannte Tempoanforderung fehlt. | −0,4 | Die Richtung genügt unter diesen Bedingungen nicht. |
| Ausdrücklich entgegengesetzte Richtung. | −0,8 | Der Vorschlag widerspricht der bekannten Streckenanforderung. |
| Keine passende Grundlage. | `unknown`, `utility: null` | Das Spiel kann diesen Vorschlag nicht begründet bewerten. |

Dies sind feste Ordnungswerte für dieses vorgeschlagene Regelprofil. Sie sind keine gemessenen Erfolgsanteile.
Bei mehreren widersprüchlichen Anforderungen gilt zuerst der ungünstigste zutreffende Fall.
Ein positives Ergebnis verlangt, dass keine bekannte Anforderung des aktuellen Abschnitts widerspricht.
Eine bekannte, aber bereits unerreichbare Tempoanforderung erhält keinen positiven Erfolgswert.
Eine einfache Bremsstreckenprüfung darf diese Lage erkennen. Sie muss ihre Annahmen zu Kräften, Gefälle und Hilfe nennen.
Eine Berechnung mit gleichbleibender Bremswirkung liefert nur unter diesen Annahmen einen passenden Bremspunkt.
Ist diese Grundlage nicht gegeben, darf die Anzeige eine allgemeine Tempoempfehlung nennen. Die Bewertung bleibt offen.

Kombinationen erhalten eine eigene Prüfung aller Mitglieder und ihrer gemeinsamen Wirkung.
Das Profil addiert keine Einzelwerte.
Eine bekannte falsche Aktion bleibt technisch verfügbar.
Die ausdrückliche Anweisung hat weiterhin Vorrang vor dem Beispielwert.

### Vollständiger Zustand für die spätere Vorausberechnung

Die spätere Vorausberechnung verwendet dieselben Bewegungsfunktionen wie das laufende Spiel.
Sie beginnt mit unabhängigen vollständigen Zustandskopien an derselben Schrittgrenze.
Sie verändert keine echte Fahrt und erzeugt keine sichtbaren Effekte oder echten Eingaben.

| Zustandsteil | Inhalt |
|---|---|
| Bewegung | Räumliche Position, vollständige Geschwindigkeit, Ausrichtung, Seitenbewegung und Kontaktzustand. |
| Strecke | Level, Formdaten, Abschnitt und örtlicher Fortschritt. |
| Eingaben | Aktive ausdrückliche Aktionen, Parameter, Restdauer, Ereignisse und Bestätigungen. |
| Ziele und Hilfen | Zieltempo, Kurvenfreigaben, Hilfsziele, Restdauer und verbrauchte Hilfe je Abschnitt. |
| Weitere Regeln | Turbo, Wartezeiten, Bremszustand, Spielschritt und gegebenenfalls Zufallszustand. |

`DriveState.snapshot()` allein enthält diese Werte noch nicht vollständig.
Ein Kontrolllauf nach einer Wiederherstellung muss dieselbe Fortsetzung ergeben.
Das gilt auch während eines Flugs und bei teilweise verbrauchter Hilfe.
Im Flug bleibt `distance_m` im heutigen Modell bis zur Landung unverändert.
Die Bewertung benötigt deshalb räumliche Position, Geschwindigkeit und Flugabschnitt statt nur dieses Streckenwerts.

### Interne Pläne und Grenze zur Ausführung

Ein interner Plan darf Bremsen, das Halten einer Geschwindigkeit und spätere Wechsel enthalten.
Er braucht Beginn und Ende jedes Schritts.
Die spätere Anbindung muss einen Plan bei einer erneuten Rechnung korrekt fortsetzen oder ausdrücklich verwerfen.
Sie darf einen nötigen Wechsel nicht durch wiederholten Neustart ständig verschieben.
Zielgeschwindigkeiten bieten dafür eine zusätzliche einfache Planform.
Die Anbindung erreicht sie mit unterstützten Aktionen. Sie setzt die tatsächliche Geschwindigkeit nicht direkt.

Jeder interne Plan erhält eine ausdrückliche Regel für seine späteren Eingaben.
Bereits aktive ausdrückliche Aktionen behalten ihre Wirkung bis zu ihrem bestätigten Ende.
Ein Plan darf weder eine spätere Erlaubnis noch einen künftigen richtigen Spielerbefehl voraussetzen.
Für die Laufzeitbewertung gilt zunächst `no_new_input:1`: Nach dem bewerteten Start kommen keine neuen Befehle hinzu.
Erlaubte bereits gestartete Hilfe darf nur innerhalb ihrer bestätigten Dauer weiterwirken.

Versuche dürfen zusätzlich einen vorgegebenen Testfahrer verwenden. Sie kennzeichnen dessen spätere Eingaben ausdrücklich.
Ein erfolgreicher Verlauf mit diesem Testfahrer belegt keine gleichwertige Hilfe ohne diese Eingaben.
Pläne mit noch nicht erlaubten späteren Aktionen bleiben Versuchsgrundlage. Sie liefern keine automatische Ausführungsfreigabe.
Eine spätere Erweiterung dieses Vertrags braucht eine eigene Abnahme der erlaubten Fortsetzung.

Der öffentliche Vorschlag enthält weiterhin nur Aktionen mit gemeinsamem Start.
Die Anbindung führt nur dessen bestätigte unmittelbare Wirkung aus.
Ein neuer ausdrücklicher Befehl verwirft alle widersprechenden internen Zukunftspläne.
Die spätere Bewertung ersetzt damit weder die Entscheidung des Spielers noch seine künftigen Eingaben.

### Auswahl und Grenzen der Berechnung

Die Spielanbindung prüft zuerst die ausdrückliche Anweisung und die Verfügbarkeit aller angeforderten Aktionen.
Diese Prüfung benötigt keine erfolgreich beendete Suchrechnung.
Für die spätere Laufzeitsuche bilden acht Pläne eine Messgröße. Sie sind noch keine feste Leistungszusage.
Die Suche reserviert Plätze für die ausdrückliche Anweisung ohne Ergänzung, „keine neue Aktion“ und passende Kombinationen.
Bei einem einzelnen Lenkbefehl und verfügbaren Tempoaktionen reserviert sie mindestens zwei Plätze für unterschiedliche erlaubte Tempoergänzungen.
Verwendet die Anweisung bereits beide Gruppen, prüft sie zuerst diese verlangte Kombination.
Viele Einzelvarianten dürfen die passenden Kombinationen nicht vollständig verdrängen.

Eine freie Parametersuche muss ausdrücklich verlangte Werte unverändert aufnehmen.
Die Suche darf freie Stärken und Dauern begrenzen. Sie meldet nicht geprüfte Vorschläge als `unknown`.
Sie darf eine ausführbare schlechte Aktion nicht wegen ihrer Bewertung aus dem Katalog entfernen.

`evaluation_context` nennt den vollständigen Ausgangszustand samt Fassung und Prüfsumme.
Er nennt außerdem die Schrittweite, das Abschnittsziel, die spätere Eingaberegel und die Fassung der Suche.
Er enthält die Zahl der Kandidaten, die Rechengrenzen, die verbrauchten Schritte und das tatsächliche Ende je Plan.
Das Ende unterscheidet `goal_reached`, `finished`, `crashed`, `horizon_reached`, `budget_exhausted` und `invalid_state`.
Nur vollständig verglichene Kandidaten erhalten eine Rangfolge. Die Antwort kennzeichnet eine unvollständige Auswahl mit `coverage: partial`.

### Dauer und Aktualität der Vorausschau

Das gemeinsame Abschnittsziel liegt hinter der entscheidenden Stelle, beim Sprung hinter der berechneten Landung.
Alle Vorschläge einer Antwort erhalten dasselbe Ziel, dieselbe maximale Dauer und dieselben erlaubten Folgeeingaben.
Ein Absturz, das erreichte Abschnittsziel oder das Streckenende darf einen Lauf früher beenden.
Ein Ende vor dem Abschnittsziel bleibt offen. Ein Flug bestätigt keine Landung.
Am Abschnittsziel erfasst die Rechnung auch alle noch wirksamen Aktionen und dauerhaften Wirkungen.
Eine automatische Ergänzung muss dort enden oder eine gesondert geprüfte Übergabe haben.
Ohne diese Grundlage bleibt ihre Bewertung offen.
Eine ausdrückliche Restdauer oder ein ausdrücklich gesetztes Zieltempo bleibt erhalten.
Die spätere Abnahme prüft diese Fortsetzung über die Zwischenmarke hinaus.

Die Dauer folgt dem Abschnitt. Eine feste Sekunde bildet keine Vorgabe mehr.
Die Versuche aus Abschnitt 19 nutzten höchstens drei, sechs oder acht Sekunden und eine erneute Auswahl nach 250 Millisekunden Spielzeit.
Diese Werte gelten als Versuchsparameter. Die spätere Laufzeit braucht eigene Grenzen für Rechenzeit und Aktualität.
Die Rechnung darf die echte Fahrt nicht während ihrer Arbeit anhalten.
Sie muss den Zustand beim tatsächlichen Start der Aktion nach Abschnitt 9 berücksichtigen.

Gleiche Plananfänge dürfen gemeinsame Physikschritte verwenden.
Beim ersten unterschiedlichen Befehl erhält jeder Zweig einen unabhängigen vollständigen Zustand.
Eine Gegenprüfung muss gleiche Endzustände, Ereignisse und Auswahl wie getrennte Läufe bestätigen.
Eine größere Schrittweite verändert dagegen die Physik. Sie gehört nicht zu dieser Verbesserung.

Ohne gültige rechtzeitige Bewertung führt das Spiel eine ausdrückliche Anweisung ohne Ergänzung aus.
Ein `activate` ohne gültige Bewertung startet keine Aktion.
Eine Rechnung ohne neue Spielereingabe bereitet nur Hinweise und Antworten vor.

## 15 Bewertung der vorausberechneten Folgen

### Ziel und Messwerte

Die spätere Bewertung benötigt keine gespeicherten Referenzfahrten.
Sie prüft die tatsächlichen Folgen bis zum bezeichneten Abschnittsziel.
Das Ziel lautet zunächst: Den Abschnitt mit der erlaubten Steuerung durchfahren und erkennbare Fehler vermeiden.
Eine möglichst kurze Rundenzeit ist kein übergeordnetes Ziel für die barrierefreie Hilfe.

Das Profil `stuntcar_lookahead_v1` trennt die folgenden Ausgänge:

| Ausgang | Bedeutung |
|---|---|
| `goal_reached` oder `finished` | Das Modell durchfuhr das Ziel ohne Absturz. Eine erforderliche Prüfung der Restwirkung oder Übergabe liegt vor. |
| `open` | Die Rechnung endete ohne Absturz vor dem Ziel, etwa im Stillstand oder im Flug. Auch ein erreichtes Ziel bleibt bei ungeprüfter Restwirkung oder Übergabe offen. |
| `crashed` | Das Modell berechnete einen Absturz vor dem Ziel. |
| `unknown` | Ungültiger Zustand, fehlende Grundlage oder Abbruch durch die Rechengrenze. |

`stop_reason` beschreibt das tatsächliche Ende der Rechnung. `outcome_status` beschreibt die Grundlage für die Auswahl.
Ein Lauf mit `stop_reason: goal_reached` kann daher `outcome_status: open` behalten.
`metrics` enthält Zielerreichung, Fahrzeit, Fortschritt, Seitenabweichung, Hilfsverbrauch und Wechsel der ergänzten Eingaben.
Weitere Abstände zu bekannten Fehlergrenzen brauchen eine eigene Definition und Prüfung.
Ein großer Abstand zu einer Spurgrenze beweist zum Beispiel noch keine sichere Landung.
Die Bewertung darf einen fehlenden Abstand nicht als maximalen Abstand behandeln.

### Reihenfolge und Nutzen

Nur eine nach dem Vertrag erlaubte Fortsetzung darf einen Vorschlag als durchgefahren bewerten.
Für durchgefahrene Vorschläge gilt diese Reihenfolge:

1. Bevorzuge weniger Wechsel der ergänzten Eingaben.
2. Bevorzuge bei Gleichstand weniger zusätzliche Hilfe.
3. Bevorzuge bei weiterem Gleichstand die kürzere gemessene Abschnittszeit.
4. Nutze zuletzt die feste Kennungsreihenfolge aus Abschnitt 7.

Dies ist ein Vorschlag für die spätere Abnahme. Die Versuche aus Abschnitt 19 nutzten ein anderes, stärker auf Fortschritt ausgerichtetes Vergleichsziel.
Die neue Reihenfolge muss deshalb eigene zurückgehaltene Fälle bestehen.
Eine neue Spielereingabe beendet die Bindung an eine bisher bevorzugte Hilfe.
Die Regel für weniger Wechsel darf ausdrückliche Eingaben niemals verzögern.

Die Spielanbindung ordnet diese durchgefahrenen Vorschläge und setzt `N` auf deren Zahl.
Für Rang `r`, beginnend mit 0, gilt `utility = 0.4 + 0.4 × (N − r) / N`.
Diese Formel gilt nur für `N > 0`. Sie erhält die festgelegte Reihenfolge innerhalb dieser Antwort.
Sie beschreibt weder einen Gewinn noch eine Erfolgswahrscheinlichkeit.
Sie macht einen offenen Verlauf nicht durch bloßes Ordnen positiv.

Ein berechneter Absturz erhält −0,9. Dieser Wert beschreibt den Fehler.
Er begründet keine automatische Ergänzung oder Rufauswahl nach Abschnitt 7.
Ausdrücklich verlangte Aktionen bleiben davon unberührt.
Ein offener Ausgang erhält `rating_status: unknown` und `utility: null`.
Die Spielanbindung darf dazu einen getrennten aktuellen Regelhinweis aus Abschnitt 14 geben.
Sie darf diesen Hinweis nicht als simulierten Erfolg ausweisen oder beide Bewertungsarten still zu einer Rangfolge mischen.
Eine negative Bewertung oder ein offener Ausgang hebt eine ausdrückliche Anweisung nicht auf.

Wenn alle geprüften Pläne scheitern, nennt die Antwort dies ausdrücklich mit `assessment_outcome: all_tested_failed`.
Sie behauptet keine Unlösbarkeit des Levels.
Ohne automatisch wählbare Variante startet ein Ruf keine neue Aktion.
Ein offener Verlauf bleibt unbewertet. Er darf keine bekannte Absturzvariante zur Ergänzung erzwingen.
Die Bewertung von „keine neue Aktion“ erhält dabei alle schon laufenden ausdrücklichen Aktionen.

## 16 Automatische Prüfung neuer Level

### Prüfauftrag und Ablauf

Jedes neue Level erhält feste Pflichtfälle und erwartete Ergebnisse.
Der Prüfauftrag nennt Modell, Hilfsprofil, Regelprofil oder Suchprofil, Schrittweite und Rechengrenzen.
Die beiden vorhandenen Hilfestufen erhalten getrennte Ergebnisse.

| Teil | Prüfung |
|---|---|
| Daten und Geometrie | Formen, Anschlüsse, Fahrflächen und mögliche Landeflächen. |
| Einfache Hinweise | Richtung, Tempobedeutung, Geltungsbereich, unbekannte Werte und Anzeige ohne Ausführung. |
| Einzelne Abschnitte | Kurve, Kuppe, Absprung, Flug, Landung und Looping mit verschiedenen Zuständen. |
| Übergänge | Ende einer Hilfe, Beginn des nächsten Elements und unveränderter Hilfsverbrauch. |
| Vollständige Fahrten | Nachspielbare Fahrt vom regulären Start bis zum Ziel mit denselben Eingaberegeln wie die geprüfte Anbindung. |
| Wiederholung | Gleiche Ergebnisse innerhalb vorher festgelegter Toleranzen. |

Regulär erreichte Zustände und künstliche Randzustände bleiben im Bericht getrennt.
Eine künstliche Startlage beweist keine Erreichbarkeit aus der normalen Fahrt.
Eine erfolgreiche Fahrt beweist keinen vollständig sicheren Bereich um diese Fahrt.

### Anfangsauswahl der Fälle

Die bisherigen Starttempi 0, 5, 14, 22, 35, 46 und 58 Meter je Sekunde bilden mögliche Prüfpunkte.
Der Auftrag übernimmt sie nur, soweit das aktive Modell und Profil sie unterstützen.
Stillstand prüft auch das spätere Anfahren nach einer ausdrücklichen Eingabe.
Eine gewollte Vollbremsung braucht keinen Zieleinlauf.

| Fallgruppe | Inhalt |
|---|---|
| Lage und Bewegung | Spurmitte, seitliche Abweichung und Seitenbewegung in beide Richtungen. |
| Eingabe | Frühe, passende, späte, falsche und fehlende Richtung; Ruf; ausdrückliche Kombination. |
| Tempo | Beschleunigen, Bremsen, Halten einer Geschwindigkeit und wechselnde Befehle. |
| Hilfe | Volle, teilweise und verbrauchte Hilfe; Ende einer Hilfe innerhalb eines Physikschritts. |
| Grenzen | Ein Schritt vor, auf und nach einer Zeitgrenze; Zustände auf beiden Seiten einer bekannten Raum- oder Tempogrenze. |
| Flug | Unterschiedliche Positionen und Geschwindigkeiten trotz gleichem `distance_m`; tatsächliche Landung; offener Ausgang. |
| Gegenbefehl | Ein späterer ausdrücklicher Befehl ersetzt die frühere gegensätzliche Aktion. |
| Halten und Ende | Frische und fehlende Verlängerung; getrennte Quellen; getrennte Enden einer Kombination. |
| Unterbrechung | Pause, Fortsetzung, Neustart und Quellenverlust mit der tatsächlichen Eingabeverarbeitung. |
| Aktualität | Neuer Kontaktzustand, verbrauchte Hilfe, überschrittener Bremspunkt und verzögerter Beginn einer berechneten Aktion. |
| Planung | Dauerhaft verschobener Wechsel, Stillstand als vermeintlicher Erfolg und Verdrängung aller Kombinationen durch Einzelaktionen. |

Die Suche nach Tempogrenzen prüft zunächst ein Raster und verfeinert Übergänge.
Erfolg an zwei Punkten belegt nicht den Bereich dazwischen.
Einzelachsen und erfolgreiche Ecken belegen ebenfalls keinen ganzen Raum von Zuständen.
Für eine stärkere Bereichszusage braucht die Anbindung einen gesonderten Nachweis.
Ohne diesen Nachweis bleibt das Ergebnis eine Liste geprüfter Zustände.

### Suche nach einer vollständigen Fahrt

Eine Vergleichssteuerung darf die Strecke mit vorgegebenen korrekten Eingaben durchfahren.
Dieser Versuch prüft die Physik und dient zum Finden von Fällen.
Die spätere Abnahme der Hilfe nutzt dagegen deren tatsächlich erlaubte Eingaben.
Sie darf keine benötigte künftige Spielereingabe erfinden.
Beide Verfahren verändern Position oder Geschwindigkeit nicht direkt, um einen Abschnitt zu bestehen.

Die Suche hält vollständige Zustände einschließlich Restdauer und verbrauchter Hilfe fest.
Sie untersucht verschiedene Eingabezeiten und erlaubte Kombinationen.
Als erste Suchgrenzen gelten höchstens 32 behaltene Zweige, 24 Vorschläge je Entscheidungspunkt und 18.000 Schritte je Fahrt.
Der Auftrag begrenzt zusätzlich alle gestarteten Zweige und alle Modellschritte über seine Fälle.
Die früher vorgeschlagenen 4.096 Zweige und 2.000.000 Schritte je Profil bleiben mögliche Anfangswerte, keine Vollständigkeitszusage.
Eine ausgeschöpfte Gesamtgrenze beendet die Suche mit `incomplete`.
Eine erfolglose begrenzte Suche beweist keine Unlösbarkeit.

Die Suche darf Zweige nach durchfahrenen Abschnitten, Fortschritt und Hilfsverbrauch vorwählen.
Diese Vorwahl ist keine erfolgreiche Levelabnahme.
Eine gefundene Fahrt braucht eine gespeicherte Eingabefolge und eine Wiederholung vom regulären Start.
Vor der Wahl der Suchwerte legt der Auftrag getrennte spätere Abnahmefälle zurück.
Nach einer Änderung der Regeln müssen diese Fälle und die Pflichtfälle erneut bestehen.

### Ergebnis und Abnahme

| Status | Bedeutung |
|---|---|
| `passed` | Alle vorher festgelegten Pflichtfälle lieferten ihr erwartetes Ergebnis und bestanden die Wiederholung. |
| `failed` | Ein vollständig geprüfter Pflichtfall verletzt sein Sollverhalten. |
| `incomplete` | Mindestens ein Pflichtfall bleibt ohne Ergebnis, ohne Grundlage oder außerhalb der Rechengrenze. |

`failed` hat Vorrang vor `incomplete`. Ohne Fehler und mit offenen Pflichtfällen bleibt das Ergebnis `incomplete`.
Ein vorsätzlich falscher Befehl darf einen Absturz ergeben und trotzdem seinen Testfall bestehen.
Ein regulär verlangter Durchlauf darf dies nicht.
Ein erfolgreicher Bericht braucht mindestens eine vollständige reguläre Fahrt je gefordertem Hilfsprofil.
Er nennt seine geprüften Fälle. Er behauptet keine allgemeine sichere Spielbarkeit aller Zustände.
Die heutige Funktion `Verification.playable` prüft nur passende Prüfsumme und `clean_completed`.
Sie erfüllt diese umfassendere Abnahme noch nicht.

## 17 Prüfberichte und weitere Bewertungsverfahren

Jeder Bericht nennt Level, Modell, Hilfsprofil, Schrittweite, Bewertung und vollständige Fallliste.
Er nennt die späteren Eingaben, den Ausgangszustand, die Aktionen, die Rechengrenzen, die Messwerte und den Endegrund.
Erfolgreiche und fehlgeschlagene Fälle bleiben erhalten.
Die Prüfsumme erfasst alle Dateien und Daten, die Bewegung, Aktionswirkung oder Bewertung beeinflussen.
Änderungen dieser Grundlagen machen die betroffenen Ergebnisse ungültig.
Eine reine sichtbare Änderung darf die Gültigkeit nur erhalten, wenn die geprüfte Fahr- und Kollisionsgeometrie gleich bleibt.

Gespeicherte Bewertungen gelten zunächst nur für den vollständig passenden Zustand.
Eine Zusammenfassung ähnlicher Zustände braucht eigene Abweichungsgrenzen und Prüfungen.
Gespeicherte Fahrten dürfen als wiederholbare Prüfbeispiele dienen. Die Laufzeit benötigt sie nicht als Referenzfahrten.
Eine einzelne erfolgreiche Fahrt liefert keine Erfolgswahrscheinlichkeit.
Der Anteil erfolgreicher Varianten beschreibt nur die geprüften Varianten.

Jev, Clef oder ein späteres eigenes Modell dürfen zusätzliche Kandidaten vorbereiten.
Die erste Fassung benötigt weder externes Modelltraining noch Modellzugriffe im laufenden Spiel.
Die ausdrückliche Anweisung und die Hilfestufe gelten unabhängig von der Herkunft eines Vorschlags.

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

## 19 Ergebnisse des Machbarkeitsversuchs

### Umfang und Grundlage

Der Versuch vom 17. Oktober 2026 nutzte das vorhandene räumliche Fahrmodell und das Stuntlabor am Stand `5a37796`.
Er änderte weder die Spielsteuerung noch die Fahrphysik.
Die Physik rechnete mit 60 Schritten je Spielsekunde ohne Darstellung.
Ein vorgegebener Testfahrer lieferte korrekte Kurveneingaben.
Die Ergebnisse betreffen deshalb vor allem die Geschwindigkeitsplanung unter dieser Bedingung.

Der [Versuchsbericht](../../research/2026-10-17-vorausschau-versuch.txt) beschreibt Ablauf, Befunde und Grenzen.
Der [Auszug der Messwerte](../../research/2026-10-17-vorausschau-messwerte.json) enthält die Ergebnisse und Kennwerte der verwendeten Quelldateien.
Dieser Auszug ist kein nachspielbarer Abnahmebericht nach Abschnitt 17.
Die Versuchsskripte und vollständigen Suchdaten liegen nur vorläufig unter `/private/tmp`.

Zunächst umfasste der Versuch 24 Startzustände, zwölf Abschnittsfahrten mit erneuter Auswahl und vier Gegenversuche.
Er prüfte Kuppe, Steilkurve, Sprung, Looping und Rechtskurve.
Beide vorhandenen Hilfestufen sowie frische und verbrauchte Hilfe gehörten zu den Fällen.
Ein Gegenversuch ohne spätere Kurveneingabe fand keine vollständige Durchfahrt der Rechtskurve.
Zwei seitlich versetzte Startzustände in der Steilkurve lieferten ebenfalls keine erfolgreiche Variante.
Diese Ergebnisse belegen keine Unlösbarkeit. Sie begrenzen die geprüfte Auswahl.

### Dauer, Fortschritt und vollständige Fahrten

Vor dem Sprung startete ein Fall mit 32 Metern je Sekunde und verbrauchter Hilfe.
Eine erneute Auswahl nach jeweils 250 Millisekunden Spielzeit ergab:

| Maximale Vorausschau | Ergebnis im geprüften Sprungabschnitt |
|---|---|
| 1 Sekunde | Absturz. |
| 3 Sekunden | Absturz. |
| 6 Sekunden | Abschnitt durchfahren. |

Im ersten vollständigen Versuch erreichte nur eine von vier Fahrten das Ziel.
Drei Fahrten standen nach 120 Spielsekunden weiterhin vor einem schwierigen Abschnitt.
Wiederholt neu begonnene Pläne verschoben einen späteren Wechsel teilweise dauerhaft.
Die Prüfung eines einzelnen günstigen Plans reichte deshalb nicht aus.

Der ergänzte Versuch verwendete sieben Zielgeschwindigkeiten und den Plan zum Halten des bisherigen Ziels.
Die Zielgeschwindigkeiten betrugen 8, 11, 16, 21, 26, 32 und 46 Meter je Sekunde.
Er erreichte sie mit den vorhandenen Geschwindigkeitseingaben.
Zusätzlich erhielt die Auswahl ein Ziel hinter dem nächsten schwierigen Abschnitt.
Die Vorausschau betrug je nach Abschnitt höchstens drei, sechs oder acht Sekunden.

| Hilfestufe | Hilfe zu Beginn | Ergebnis | Spielzeit |
|---|---|---|---:|
| Sehr leicht | Frisch | Ziel erreicht. | 29,07 Sekunden |
| Sehr leicht | Verbraucht | Ziel erreicht. | 22,83 Sekunden |
| Leicht | Frisch | Ziel erreicht. | 29,00 Sekunden |
| Leicht | Verbraucht | Ziel erreicht. | 22,83 Sekunden |

Eine weitere Prüfung nutzte Kuppe, Sprung, Looping und Rechtskurve mit jeweils 12, 22 und 38 Metern je Sekunde Starttempo.
Die Hilfe hatte noch eine Sekunde je Element zur Verfügung.
Alle zwölf Abschnittsfahrten durchfuhren ihr Ziel.
Die Fahrzeiten beweisen keine allgemein beste Aktion und vergleichen nicht die Qualität der Hilfestufen.

### Rechenzeit und gemeinsame Plananfänge

Jede Auswahl verglich acht Pläne. Ein Lauf endete am Abschnittsziel, beim Absturz oder an der maximalen Vorausschau.
Die folgende Tabelle nennt den mittleren sortierten Wert aus fünf Messungen nach einem vorbereitenden Lauf.
Die Messung enthält Zustandskopien, Physik, Bewertung und Auswahl. Darstellung und einmaliger Aufbau fehlen.

| Abschnitt | Maximale Vorausschau | Getrennte Läufe | Gemeinsame Anfänge | Zeitersparnis |
|---|---:|---:|---:|---:|
| Kuppe | 6 Sekunden | 51,8 ms | 43,1 ms | 16,7 Prozent |
| Sprung | 8 Sekunden | 120,2 ms | 102,4 ms | 14,8 Prozent |
| Looping | 6 Sekunden | 67,4 ms | 57,5 ms | 14,7 Prozent |
| Rechtskurve | 6 Sekunden | 37,7 ms | 30,2 ms | 19,7 Prozent |

Die gemeinsame Berechnung lieferte dieselben geprüften Ergebnisse und dieselbe Auswahl wie die getrennten Läufe.
Die Zustandskopien lieferten auch im Flug dieselbe Fortsetzung. Ihr Hilfsverbrauch blieb voneinander unabhängig.
Die Prüfung verglich dabei nicht sämtliche Bewegungsereignisse oder alle denkbaren Zustände.
Die vollständigen verbesserten Fahrten brauchten in diesen Messungen höchstens 138,5 Millisekunden je Auswahl.

Während der Versuchsrechnung wartete die simulierte echte Fahrt.
Die Messung belegt deshalb keine gleichwertige Aktualität oder Rechenzeit im laufenden dargestellten Spiel.
Ein späterer Einsatz muss den Startverzug und die Belastung durch die Darstellung gesondert prüfen.
Eine Sekunde Vorausschau, ein Rechentakt von 100 Millisekunden und eine Gültigkeit von 200 Millisekunden bilden keine bestätigte Vorgabe mehr.

### Bedeutung für die nächsten Schritte

Die Messung stützt wenige passende Pläne und ein Ziel hinter der entscheidenden Stelle.
Sie stützt die gemeinsame Berechnung identischer Plananfänge ohne Änderung der Physik.
Sie belegt noch keine barrierefreie Gesamtsteuerung mit ausdrücklichen Gegenbefehlen oder Sprache.
Sie prüft nicht das in Abschnitt 15 vorgeschlagene Ziel mit weniger Eingabewechseln.

Der erste nutzbare Umbau sollte deshalb mit der gemeinsamen Schnittstelle und einfachen aktuellen Hinweisen beginnen.
Die spätere Vorausberechnung ergänzt diese Grundlage erst nach eigenen Prüfungen der tatsächlichen Eingaberegeln und der Aktualität.

## 20 Erneuter Review mit Astra

Astra bewertet den schrittweisen Umbau als sinnvoll, mit Korrekturen bei gehaltenen Eingaben und der Auswahl offener Simulationsausgänge.
Der Entwurf enthält diese Korrekturen. Astra bestätigte sie bei einer gezielten Nachprüfung.
Ein zusätzlicher Textabgleich stellt klar, dass ungeprüfte Restwirkungen auch nach einer erreichten Zwischenmarke offen bleiben.
Der [Reviewbericht](../reviews/2026-10-17-steuerungskonzept-astra.md) nennt Befunde, Korrekturen und Grenzen der Prüfung.
Die Umsetzung bleibt einem späteren Auftrag vorbehalten.

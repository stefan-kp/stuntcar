# Stuntcar: Hilfestufen und spätere Streckenprüfung

Datum: 17. Oktober 2026. Status: Entwurf zur Prüfung durch Stefan.

Dieser Entwurf beschreibt die Architektur und die Abnahme. Er enthält keinen ausführlichen Umsetzungsplan.
Er ändert keinen Spielcode. Stefan hat diesen schriftlichen Entwurf noch nicht bestätigt.

## 1. Ziel und Reihenfolge

Stuntcar soll mit Sprache und Tastatur zugänglich bleiben. Auch Menschen mit körperlichen Einschränkungen sollen das Spiel bedienen können.
Stunts, Höhe, Sprünge und Tempo erzeugen den Spielspaß. Schnelle Reaktionen stehen nicht im Mittelpunkt.
Das Auto braucht für jede Kurve eine neue absichtliche Eingabe. Das Spiel übernimmt keine Fahrt ohne diese Eingaben.

Die vorgeschlagene Reihenfolge ist tragfähig:

1. Die Hilfestufen „Sehr leicht“ und „Leicht“ auf den vorhandenen Strecken erproben.
2. Ein gemeinsames Fahrmodell mit tempoabhängigen Sprüngen und einer Streckenprüfung entwickeln.
3. Weitere Streckenelemente auf dieser Grundlage ergänzen.

Der erste Schritt braucht bereits klare Regeln für Kurven und Rettungen.
Er braucht noch keinen allgemeinen Streckensimulator. Ein Streckensimulator berechnet später Fahrten ohne Bildausgabe.
Das neue Sprungmodell und dieser Simulator gehören zusammen. Ein Simulator mit anderen Fahrregeln hätte keinen verlässlichen Bezug zum Spiel.

Abzweigungen entfallen vollständig. Mimik, neue Stuntknöpfe und eine realistische Fahrzeugsimulation gehören nicht zum ersten Ausbau.
„Mittel“ und „Schwer“ bleiben spätere Erweiterungen. Das Menü bietet zunächst nur die beiden fertigen unteren Stufen an.

**Kennzeichnung:** Die folgenden Abschnitte unterscheiden bestätigte Vorgaben und Entwurfsentscheidungen.
Entwurfsentscheidungen sind konkrete Vorschläge. Sie brauchen noch Stefans Prüfung.
Zahlen aus dem bisherigen Code beschreiben nur den Bestand. Sie sind keine neuen, gemessenen Grenzwerte.

## 2. Geprüfter Bestand

Die Leseprüfung bezieht sich auf den vorhandenen Arbeitsstand mit dem letzten Commit `1b8499a`.
Andere lokale Änderungen betreffen unter anderem Landschaften und die README-Datei. Dieser Entwurf lässt diese Änderungen unangetastet.

| Quelle | Festgestellter Stand | Folge für den Ausbau |
|---|---|---|
| `scripts/vehicle/drive_model.gd` | `active_curve_id` bindet die Hilfe an eine Kurve. Ohne Lenkaktion bleibt die Fahrtrichtung gleich. | Die Bindung an genau eine Kurve bleibt erhalten. |
| Dieselbe Datei | Lautstärke verändert derzeit die Lenkstärke. Weitere Eingaben können die Spur korrigieren. | Die unteren Stufen brauchen eine Lenkung ohne Lautstärkeeinfluss und ohne Pflicht zu weiteren Korrekturen. |
| Dieselbe Datei | `faster` erhöht das Zieltempo dauerhaft. Ein lautes `faster` ergänzt einen Turbo für 1,2 Sekunden. | Zieltempo, tatsächliches Tempo und zeitlich begrenzter Zusatzschub müssen unterscheidbar bleiben. |
| Dieselbe Datei | Das Auto bremst in der Luft derzeit nicht ab. `off_road` beendet die Fahrt nach einer seitlichen Grenzüberschreitung. | Rettung und endgültiger Absturz brauchen eine gemeinsame, eindeutige Grenze. |
| `scripts/track/track_data.gd` | Jede ausgewählte Strecke hat einen linearen Verlauf. Der Katalog lädt mehrere Streckendateien. | Keine Architektur für Abzweigungen nötig. |
| Dieselbe Datei | `flight_height` bestimmt die Flughöhe aus der Streckenposition. Das Tempo bestimmt nicht die Sprungweite. | Der erste Schritt kann keine sinnvollen Sprung-Tempogrenzen bestätigen. |
| Dieselbe Datei | `project` ordnet das Auto im Bodenriss der Strecke zu. Steilkurven erlauben 0 bis 45 Grad. | Loopings brauchen später eine räumliche Streckenbeschreibung. |
| `scripts/input/command_router.gd` | `unrecognized_turn` prüft Fahrtzustand, Mikrofonprofil, Signalstärke, Rufdauer und Kurvennähe. | Diese Prüfung bildet die Grundlage für „Sehr leicht“. |
| `voice/streaming.py` und `scripts/input/voice_bridge.gd` | Rufende, Befehlsvorrang, Paketnummer und Eingabegeneration verhindern bereits bestimmte Wiederholungen. | Diese Regeln bleiben erhalten. Die neue Kurvenbindung ergänzt sie. |
| `scripts/main.gd` | Das Spiel verbindet Sprache, Tastatur, Fahrmodell, Anzeige und Effekte. Tastenechos lösen keine neue Lenkung aus. | Neue Fahrregeln gehören ins gemeinsame Fahrmodell, nicht zusätzlich in die Anzeige. |

Die bisherige Rufhilfe verlangt mindestens 0,15 Sekunden Signal und die höchste persönliche Lautstärkestufe.
Die Sprachverarbeitung nutzt zusätzlich feste technische Signalgrenzen. Das ist noch keine vollständige persönliche Trennung von Ruf und Raumgeräusch.
Der Ausbau darf diese vorhandenen Grenzen nicht als allgemeine Erkennung von Absicht darstellen.

Die Leseprüfung umfasste auch `README.md`, `tracks/README.md`, `docs/voice-stunts.md` und `docs/stunt-umsetzung.md`.
Sie umfasste die Tests für Grundfahrt, Rufhilfe, Strecken sowie Tempo und Steilkurven.
Einige Tests verlangen noch die alte Wirkung einer falschen Richtung oder zusätzliche Korrekturen bei hohem Tempo.
Die spätere Umsetzung muss diese Erwartungen ausdrücklich nach Hilfestufe unterscheiden.

## 3. Wahl der Architektur

| Ansatz | Vorteil | Nachteil |
|---|---|---|
| **Schrittweise Entwicklung mit gemeinsamem Fahrmodell** | Die Steuerung lässt sich früh erproben. Spätere Prüfungen verwenden dieselben Regeln. | Die Sprungprüfung folgt erst im zweiten Schritt. |
| Neues Fahrmodell und vollständiger Simulator zuerst | Alle Elemente könnten früh dieselbe Berechnung nutzen. | Das verschiebt die wichtige Erprobung der Sprachsteuerung. |
| Unabhängiger Simulator neben dem bisherigen Spiel | Die Prüfung könnte schnell erste Zahlen liefern. | Die Zahlen würden das bisherige garantierte Sprungmodell kaum sinnvoll prüfen. |

**Entwurfsentscheidung:** Der erste Ansatz gilt als Grundlage.
Dieser Entwurf legt den ersten Ausbau fest. Die Abschnitte zum zweiten Ausbau bestimmen dessen Grenzen und Schnittstellen.
Vor dem zweiten Ausbau folgt ein eigener genauer Entwurf. Der erste Umsetzungsplan soll nur den ersten Ausbau behandeln.

## 4. Regeln für die unteren Hilfestufen

### 4.1 Auswahl und Eingaben

**Bestätigte Vorgabe:** Beide unteren Stufen bestimmen die Lenkstärke selbst. Die Lautstärke bestimmt dort keinen Lenkeinschlag.
Eine angenommene Eingabe gilt höchstens für die zugeordnete Kurve. Die nächste Kurve braucht eine neue Eingabe.
Die Hilfe darf das Tempo selbst verändern. Sie darf dadurch keine fehlende Lenkfreigabe ersetzen.

| Eingabe im gültigen Kurvenbereich | Sehr leicht | Leicht |
|---|---|---|
| Richtige Richtung | Die Hilfe führt durch die zugeordnete Kurve. | Die Hilfe führt durch die zugeordnete Kurve. |
| Falsche oder falsch erkannte Richtung | Die Hilfe verwendet die passende Kurvenrichtung. | Die Eingabe gibt die Kurve nicht frei. |
| Geeigneter absichtlicher Ruf ohne erkannten Befehl | Die Hilfe verwendet die passende Kurvenrichtung. | Der Ruf gibt die Kurve nicht frei. |
| Erkanntes `faster` oder `slower` | Der Befehl verändert das Zieltempo. Er gibt keine Kurve frei. | Der Befehl verändert das Zieltempo. Er gibt keine Kurve frei. |
| Keine Eingabe, Stille oder Dauergeräusch | Keine neue Lenkaktion. | Keine neue Lenkaktion. |

Das Spiel kann einen falsch erkannten Tempobefehl nicht sicher von einem beabsichtigten Tempobefehl unterscheiden.
Deshalb behält ein erkanntes `faster` oder `slower` seine Bedeutung. Es darf keine zusätzliche Rufhilfe aus derselben Äußerung auslösen.
Separate Richtungswörter in einer Äußerung bleiben eigenständige Befehle.

**Entwurfsentscheidungen:**

- „Sehr leicht“ bildet die Voreinstellung für neue Einstellungen. Das Spiel speichert die gewählte Hilfestufe.
- Ein Stufenwechsel gilt ab dem nächsten Start oder Neustart. Die aktuelle Kurvenfreigabe ändert sich dadurch nicht.
- Auf „Leicht“ zeigt das Spiel eine falsche Richtung an. Es führt dadurch keine falsche Lenkbewegung aus.
- Eine spätere richtige Eingabe kann die Kurve innerhalb des gültigen Bereichs noch freigeben.
- Eine falsche Folgeeingabe löscht keine bereits gültige Freigabe derselben Kurve.
- Eine Richtungseingabe außerhalb eines gültigen Kurvenbereichs löst auf den unteren Stufen keine freie Lenkbewegung aus.
- Die vorhandene gesonderte Landekorrektur bleibt im ersten Ausbau nur bei einer passenden Richtung wirksam. Sie erweitert keine Kurvenfreigabe.

Die Tastatur folgt denselben Bedeutungen. Auf „Sehr leicht“ genügt eine der beiden Richtungstasten.
Auf „Leicht“ muss die Richtung stimmen. Eine gehaltene Richtungstaste zählt nur beim ersten Druck.
Für die nächste Kurve muss der Spieler die Taste loslassen und erneut drücken.
Gas und Bremse bleiben auf der Tastatur dauerhaft bedienbar. Gleichzeitige entgegengesetzte Richtungstasten geben keine Kurve frei.
Die vorhandenen eigenen Tastenzuordnungen bleiben nutzbar.

### 4.2 Ein begrenzter Bereich für jede Kurve

**Entwurfsentscheidung:** Jede Kurvengelegenheit hat eine Kennung, einen Anfang und ein endgültiges Ende.
Die Kennung verbindet Hinweis, Eingabe, Fahrhilfe und Prüfung.
Die erste Annahme bindet die Eingabe sofort an diese Kennung. Sie darf später nicht zur nächsten Kurve wechseln.
Eine Eingabe vor dem Anfang bleibt wirkungslos. Das Spiel speichert sie nicht für eine spätere Kurve.
Solange die aktuelle Kurve läuft, gelten weitere Lenkbefehle höchstens für diese Kurve.
Am Kurvenende endet die Freigabe. Danach hält das Auto ohne neue Eingabe seine erreichte Fahrtrichtung.

| Abschnitt | Wirkung einer passenden Eingabe | Sichtbare Rückmeldung |
|---|---|---|
| Früh, innerhalb des angekündigten Bereichs | Das Spiel merkt die Eingabe vor. Das Auto lenkt erst am Kurvenanfang. | Die Anzeige bestätigt die vorgemerkte Kurve. |
| Passend | Die Hilfe führt sauber durch die Kurve. | Die Anzeige bestätigt die Richtung. |
| Spät | Die Hilfe führt mit seitlicher Abweichung und Tempverlust durch die Kurve. | Das Auto rutscht sichtbar. Das Tempo sinkt. |
| Sehr spät, innerhalb der Rettungsgrenze | Die Hilfe bremst stark und führt zurück auf eine gültige Spur. | Die Anzeige nennt die Rettung. Das Auto bremst sichtbar. |
| Nach der Rettungsgrenze | Die Eingabe gibt diese Kurve nicht mehr frei. | Die Anzeige meldet die verpasste Kurve. |

Die Grenzen stehen als endliche Parameter im Fahrmodell. Sie umfassen Streckenposition, Zeit und zulässigen Fahrzeugzustand.
Der Fahrzeugzustand enthält Tempo, seitlichen Abstand und Fahrtrichtung.
Die Rettungsgrenze liegt vor dem endgültigen Verlust der befahrbaren Fläche. Das Spiel erlaubt keine rückwirkende Rettung eines Absturzes.
`off_road` und der Zustand `FALLING` sperren jede Rettung. Eine bereits abgelaufene Rettungsgrenze bleibt ebenfalls geschlossen.

Die Abschnitte folgen fest aufeinander: früh, passend, spät, sehr spät, geschlossen.
Jede Abschnittsgrenze gehört zum nachfolgenden Abschnitt. Das Ende des Rettungsbereichs gehört bereits zum geschlossenen Bereich.
Die Gelegenheit schließt bei der ersten erreichten Positions-, Zeit- oder Zustandsgrenze.
Ein unterstützter Zustand muss bis zum Kurvenende mit den erlaubten Kräften rettbar bleiben.
Die spätere Parametertabelle nennt diese Grenzen je Hilfsprofil und Kurve. Sie darf keinen unbegrenzten Ersatzwert enthalten.

Der Hinweis öffnet den Eingabebereich genau einmal.
Die vorhandene Vorlaufwahl mit 3, 5 oder 8 Sekunden bildet den Ausgangspunkt für die Erprobung.
Eine Berechnung aus dem aktuellen Tempo darf den bereits geöffneten Bereich nicht nachträglich schließen oder neu öffnen.
Eine endliche Höchstdauer beendet eine ungenutzte Gelegenheit auch bei Stillstand. Die Pause hält diese Spielzeit an.
Nach Ablauf braucht diese verpasste Kurve einen Neustart, falls das Auto davor stehen bleibt.

Die Anzeige zeigt frühzeitig die Richtung und den aktuellen Eingabeabschnitt. Ein Ton ergänzt die Anzeige.
Der letzte Rettungsabschnitt muss erkennbar beginnen. Eine kleine, plötzlich wechselnde Frist genügt nicht.
Die endgültige Grenze darf nicht hinter einer bereits erreichten Absturzgrenze liegen.

Konkrete Grenzwerte entstehen bei der Erprobung aller vorhandenen Kurven.
Der erste Ausbau gilt erst als fertig, wenn die Werte endlich, versioniert und durch Grenztests belegt sind.
Ein unerfüllbares Rettungsversprechen erfordert eine frühere, klar angezeigte Grenze oder stärkere Hilfe innerhalb ihrer festen Grenzen.

### 4.3 Was als neue Eingabe zählt

**Entwurfsentscheidung:** Das Eingabesystem ergänzt eine eindeutige Kennung je Ruf und je bestätigtem Wort.
Die vorhandenen Paketnummern und Eingabegenerationen bleiben wirksam. Eine Eingabegeneration trennt beispielsweise die Fahrt vor und nach einer Pause.
Wiederholte Pakete, nachträgliche Ergebnisse und das Ende derselben Äußerung erzeugen keine zweite Lenkfreigabe.
Die Kurvenzuordnung verwendet den Zeitpunkt der Annahme im Spiel. Sie behauptet keine gemessene Sprachverzögerung.

Ein unbekannter Ruf zählt erst nach seinem Ende. Er braucht ein gültiges Profil für das verwendete Mikrofon.
Die Prüfung verwendet persönliche Signalwerte und eine erfasste Geräuschgrenze. Sie verlangt eine begrenzte Dauer und eine anschließende Pause.
Sie verwirft zu kurze Signale, zu lange Signale und ungültige Messwerte.
Eine künstliche Aufteilung durch die Spracherkennung zählt nicht als neues Rufende.

Ein unbekannter Ruf darf keine Kurve freigeben, wenn er vollständig vor deren Eingabebereich lag.
Die Verarbeitung erfasst dafür Rufbeginn und Rufende im laufenden Eingabestrom.
Sie ordnet diese Angaben derselben Eingabegeneration zu. Sie leitet daraus keine vermeintlich gemessene Gesamtverzögerung ab.
Nach einem Ruf braucht die Erkennung eine neue, getrennte Äußerung für eine weitere Kurve.
Ein wiederholtes, eindeutig bestätigtes Richtungswort darf als neue Eingabe zählen. Ein unveränderter Dauerlaut darf das nicht.
Die Tests müssen diese Unterscheidung mit Geräuschen und längeren Lauten prüfen.

Ein festgestelltes Signal beweist keine Absicht. Die persönliche Rufübung muss deshalb die Erkennung und mögliche Fehlauslösungen sichtbar machen.
Die bisherige Pflicht zur höchsten Lautstärkestufe ist keine feste Produktregel für den Ausbau.
Auch ein gut unterscheidbarer, leiser persönlicher Ruf soll genügen. Die Prüfung muss das gegen Raumgeräusche absichern.
Ohne gültiges Mikrofonprofil bleibt die Rufhilfe aus. Erkannte Wörter und die Tastatur bleiben nutzbar.

## 5. Tempo, Rettung und sichtbare Bewegung

**Bestätigte Vorgabe:** Ein Tempobefehl verändert das Tempo tatsächlich. Die Hilfe darf danach selbst beschleunigen oder bremsen.
Ein starker Bremsbefehl vor einer Rampe darf einen späteren spektakulären Rettungsschub auslösen.
Das Spiel braucht zunächst nur Zusatzschub und starke Bremsung. Andere Rettungsmittel folgen bei Bedarf.

**Entwurfsentscheidung:** Das Modell trennt drei Werte:

- Das Zieltempo des Spielers speichert die Wirkung seiner Tempobefehle.
- Das Hilfsziel gilt nur für eine bestimmte, begrenzte Rettung.
- Das tatsächliche Tempo folgt der berechneten Beschleunigung oder Bremsung.

Die vorhandene Lautstärkewirkung auf Tempobefehle bleibt zunächst erhalten.
Sie nutzt die persönliche Kalibrierung. Sie verändert weiterhin keine Lenkstärke auf den unteren Stufen.
Der normale Turbo bleibt ein Effekt eines Tempobefehls. Ein Rettungsschub erhält einen eigenen Grund und eine eigene Anzeige.
Nach der Rettung folgt das Auto wieder dem Zieltempo des Spielers.

Ein Rettungsereignis enthält Elementkennung, Grund, Beginn, Ende und die tatsächlich angewendete Kraftwirkung.
Die Anzeige zeigt zuerst den Tempobefehl und danach den Rettungseingriff. Das Fahrprotokoll hält beides getrennt fest.
Eine reine Änderung der Zielanzeige ohne Wirkung auf die Bewegung genügt nicht.
Der Bremsbefehl vor einer Rampe muss eine erkennbare Bremsphase auslösen. Der spätere Schub erklärt die erneute Beschleunigung.

Die Rettung hat feste Grenzen für Dauer, Beschleunigung, Bremsung und seitliche Korrektur.
Ein dauerhafter Bremsbefehl darf innerhalb derselben Rettung vorübergehend hinter dem Hilfsziel zurückstehen.
Er verändert weiter das gespeicherte Zieltempo. Nach der Rettung wirkt dieses Zieltempo wieder.
Dieselbe Ursache löst pro Element keine endlose Folge neuer Rettungen aus.
Außerhalb eines angekündigten Hilfsbereichs darf das Auto stehen bleiben.

Die Kurvenhilfe lenkt nur mit Freigabe. Die Tempohilfe darf ohne Freigabe bremsen, aber keine passende Fahrtrichtung herstellen.
Auch nach einem Tempohilfseingriff bleibt eine Kurve ohne Lenkbefehl verpasst.
Die Hilfe darf eine solche Fahrt nicht durch endloses Warten vor jeder Kurve ersetzen.

### Zeitverlust als Entwurfsentscheidung

Eine saubere Fahrt soll schneller bleiben als eine gerettete Fahrt unter vergleichbaren Ausgangsbedingungen.
Die Rettung kostet tatsächliche Fahrzeit durch Bremsung, eine längere Spur oder eine begrenzte Erholungsphase.
Eine Erholungsphase begrenzt das Tempo nach der Rettung. Sie verändert nicht nur eine Ergebniszahl.
Der Zusatzschub darf eine notwendige Geschwindigkeit erreichen. Er darf keinen Zeitgewinn durch absichtliches Bremsen erzeugen.

Die Prüfung vergleicht Fahrten ab demselben Zustand vor dem Element bis zu einem gemeinsamen Punkt hinter der Erholungsphase.
Sie vergleicht außerdem die Gesamtfahrt. Weitere Tempobefehle dürfen die Erholungsgrenze nicht aufheben.
Das ist zunächst eine prüfbare Entwurfsregel. Es ist keine Behauptung über alle denkbaren Eingaben.

## 6. Erster Ausbau: wählbare Hilfe auf vorhandenen Strecken

Der erste Ausbau enthält die Stufenwahl, die Eingaberegeln und die zeitabhängige Kurvenhilfe.
Er ergänzt die nötige Rückmeldung, die Rufprüfung und begrenzte Kurvenrettungen.
Er braucht keinen Umbau der Landschaften und keine neuen Streckenelemente.

Das bisherige Sprungmodell bleibt in diesem Schritt erhalten. Die Flugbahn hängt weiterhin von der Streckenposition ab.
Ein Sprung mit niedrigem Tempo kann deshalb noch keine Aussage über eine echte Mindestgeschwindigkeit liefern.
Die Anzeige und die Dokumentation dürfen dafür keine geprüften Sprung-Tempobereiche behaupten.
Die Erprobung der Tempobefehle bleibt möglich. Die verlässliche Rampenrettung mit tempoabhängiger Flugbahn folgt im zweiten Ausbau.

### Zuständigkeiten

| Baustein | Aufgabe und Verbindung |
|---|---|
| Sprachverarbeitung und `voice_bridge.gd` | Liefern geprüfte Eingabeereignisse mit Herkunft, Wort- oder Rufkennung und Messwerten. |
| `command_router.gd` | Prüft den Spielzustand und die gewählte Stufe. Übergibt zulässige Eingaben an das Fahrmodell. |
| Regelteil neben `drive_model.gd` | Bestimmt die Kurvengelegenheit, deren Abschnitt und die einmalige Freigabe. Verwendet Strecke und Hilfestufe. |
| `drive_model.gd` | Führt die Bewegung und die begrenzten Hilfen aus. Liefert Zustand und Ereignisse für Anzeige und Prüfung. |
| `track_data.gd` | Liefert den linearen Verlauf und die vorhandenen Kurven. Der erste Ausbau braucht kein neues Streckenformat. |
| `main.gd`, Anzeige und Effekte | Verbinden die Bausteine. Zeigen Vorgänge aus dem Fahrmodell an. Berechnen keine eigenen Rettungsregeln. |

Der Regelteil bleibt ohne Bildausgabe und ohne Mikrofonzugriff prüfbar.
Ein Hilfsprofil enthält die stufenabhängigen Regeln und Grenzwerte. Es erzeugt keine eigenständige zweite Fahrphysik.
Das Modell verarbeitet pro festem Zeitschritt die Eingaben, die Hilfsentscheidung und danach die Bewegung.
Es prüft anschließend Grenzen und gibt Ereignisse aus. Das Projekt verwendet derzeit 60 solche Zeitschritte pro Sekunde.

Neustart, Streckenwechsel und Absturz löschen offene Freigaben und alte Ereignisse.
Die Pause hält Bewegung und Rettungsdauer an. Die Fortsetzung übernimmt keine alten, während der Pause erzeugten Eingaben.
Ein Mikrofonfehler erzeugt keine Ersatzlenkung. Ein ungültiges Hilfsprofil erzeugt eine verständliche Fehlermeldung statt unbegrenzter Hilfe.

### Abnahme des ersten Ausbaus

Die späteren Tests prüfen alle vorhandenen Strecken mit beiden unteren Stufen.
Sie nennen jeweils Tempo, Eingabezeitpunkt, Stufe, Vorlaufwahl und Ausgangszustand.

| Prüfung | Erforderliches Ergebnis |
|---|---|
| Keine Eingabe | Das Auto beginnt keine Lenkaktion und verpasst die Kurve. |
| Genau eine Eingabe | Die Hilfe führt höchstens durch die zugeordnete Kurve. Die nächste Kurve braucht eine neue Eingabe. |
| Sehr leicht: richtige Richtung, falsche Richtung, unbekannter geeigneter Ruf | Jede dieser Eingaben kann dieselbe Kurve freigeben. |
| Leicht: falsche Richtung oder unbekannter Ruf | Keine Freigabe. Eine rechtzeitige richtige Eingabe bleibt möglich. |
| Frühe, passende, späte und sehr späte Eingabe | Die Bewegung und der Zeitverlust entsprechen dem angekündigten Abschnitt. |
| Grenzen der Rettung | Tests unmittelbar vor, auf und nach jeder Grenze zeigen eine eindeutige Entscheidung. |
| Gültige Eingabe im unterstützten Zustandsbereich | Eine Eingabe genügt zuverlässig bis zum Kurvenende. Weitere Korrekturen sind nicht erforderlich. |
| Eingabe nach endgültigem Absturz | Keine Rettung und keine Freigabe für den nächsten Versuch. |
| Stille, Dauerlaut, Dauertaste, wiederholtes Paket | Keine automatische Freigabe späterer Kurven. |
| Erkanntes `faster` oder `slower` samt späterer Rückmeldung | Genau die vorgesehenen Tempobefehle wirken. Keine zusätzliche Ruflenkung. |
| Gleiche Richtung bei verschiedenen persönlichen Lautstärken | Die unteren Stufen erzeugen dieselbe Lenkhilfe. |
| Pause, Neustart, Streckenwechsel und Mikrofonwechsel | Kein alter Befehl wirkt in einem neuen Zusammenhang. |
| Saubere und gerettete Vergleichsfahrt | Die Rettung erzeugt keinen Zeitvorteil. Effekte erklären die tatsächliche Bewegung. |

Automatische Tests prüfen Regeln und Bewegung. Spielversuche mit Sprache und Tastatur prüfen Verständlichkeit, Zugänglichkeit und Fahrgefühl.
Das Team protokolliert die tatsächlich erprobten Personen, Geräte und Bedingungen. Es behauptet keine allgemeine Barrierefreiheit.
Für die Abnahme müssen die unteren Stufen ohne genaue Lautstärkesteuerung und ohne schnelle Folgekorrekturen nutzbar sein.

## 7. Zweiter Ausbau: gemeinsames Sprungmodell und Streckenprüfung

Dieser Abschnitt legt die Anschlussbedingungen fest. Er ersetzt keinen eigenen Umsetzungsplan.

### 7.1 Tempoabhängiger Flug

**Entwurfsentscheidung:** Beim Absprung übernimmt das Auto die tatsächliche Position und Geschwindigkeit.
Das Überfahren der Rampe löst den Sprung aus. Dafür braucht der Spieler keinen zusätzlichen Befehl.
Die Rampenrichtung bestimmt die anfängliche Flugrichtung. Eine feste Spielschwerkraft verändert die vertikale Geschwindigkeit.
Eine begrenzte Hilfskraft darf die Bewegung verändern. Das Modell berechnet die Flugbahn in festen Zeitschritten.
Eine Landung entsteht durch den tatsächlichen Kontakt mit dem vorgesehenen Landebereich.

Das Modell setzt die Höhe nicht mehr über `flight_height(distance_m)` auf einen vorgegebenen Bogen.
Es darf das Auto auch nicht am Ende der Lücke unbemerkt auf die Landung setzen.
Zu geringe Geschwindigkeit kann ohne Hilfe vor dem Landebereich enden. Zu hohe Geschwindigkeit kann dahinter enden.
Die Darstellung verwendet die berechnete Position. Sie verdeckt keine verfehlte Landung durch einen beliebigen Effekt.

Der erste neue Flug benötigt nur Rampen, Schwerkraft, Zusatzschub und starke Bremsung am Boden.
Er muss keine Luftbremsung durch Reifen behaupten. Falls später eine Kraft im Flug wirkt, braucht sie eine sichtbare Ursache.
Die unteren Stufen bereiten einen sicheren Absprung innerhalb ihrer festen Hilfsgrenzen vor.
Eine fehlende vorherige Kurvenfreigabe bleibt trotzdem ein Fehler.

### 7.2 Daten je Streckenelement

Das erweiterte Streckenformat bekommt eine neue Versionsnummer. Alte Dateien bleiben ausdrücklich dem alten Sprungmodell zugeordnet.
Eine Umstellung der vorhandenen Strecken verlangt eine neue Prüfung. Sie darf deren bisherige Prüfergebnisse nicht übernehmen.

| Daten | Zweck |
|---|---|
| Stabile Elementkennung und Elementart | Verbinden den Verlauf, die Eingaben, die Hilfe und den Prüfbericht. |
| Beginn, Ende und räumlicher Verlauf | Bestimmen die tatsächliche Lage und Länge. |
| Rampenform und Absprungrichtung | Bestimmen den Übergang in den Flug. |
| Landebereich mit Länge, Breite, Höhe und zulässiger Ausrichtung | Bestimmt eine gültige Landung. |
| Empfohlenes Tempo, Mindesttempo und Höchsttempo | Beschreiben geprüfte Bereiche für einen bezeichneten Zustand und eine Hilfestufe. |
| Hinweisbeginn, Eingabebereiche und Rettungsende | Begrenzen eine Eingabe und deren Hilfe. |
| Unterstützte Fahrzeugzustände und Grenzen der Kräfte | Begrenzen das Rettungsversprechen. |
| Regeln für Erholungsphase und Zeitverlust | Verhindern einen Vorteil durch absichtliche Rettungen. |
| Version der Strecke, Fahrregeln und Hilfsprofile | Bestimmen die Gültigkeit eines Prüfberichts. |

Nicht jedes Element braucht jede Angabe. Eine Gerade braucht beispielsweise keinen Landebereich und meist kein Mindesttempo.
Die Dateiprüfung verlangt nur die für die Elementart notwendigen Angaben. Sie weist widersprüchliche oder unendliche Werte zurück.
Ein vorgeschlagener Tempobereich aus einer Streckendatei gilt erst nach der Fahrprüfung als geprüft.
Die geprüften Bereiche enthalten ihre Bedingungen. Ein einzelner Tempowert ohne Anfahrzustand genügt nicht.

### 7.3 Gemeinsame Berechnung und Bericht

Spiel und Simulator verwenden denselben Bewegungsschritt, dieselben Hilfsprofile und dieselbe Prüfung der Landung.
Der Simulator ersetzt lediglich Mikrofon und Tastatur durch vorher festgelegte Eingabeereignisse.
Er braucht weder Fahrzeugeffekte noch Kamera noch Landschaftsbilder.
Bei gleichen Ausgangsdaten muss er dieselben Fahrzustände wie das Spiel liefern, innerhalb einer dokumentierten Rechentoleranz.

Die Prüfung führt das Auto durch mehrere Elemente und ganze Strecken.
Sie setzt Tempo und Zustand zwischen zwei Elementen nicht zurück.
Sie prüft beispielsweise, ob nach einer Kurve genügend Strecke zur Beschleunigung vor der nächsten Rampe bleibt.
Kurvenhilfe, Bremsphase, Rettungsschub und Erholungsphase gehen dabei vollständig in die Berechnung ein.

Die Prüfung unterscheidet drei Ergebnisse:

- **Saubere Fahrt:** Die passende Eingabe und die normale stufenabhängige Kurvenführung genügen. Keine besondere Rettung greift ein.
- **Rettung möglich:** Eine erlaubte, begrenzte Hilfe erreicht einen gültigen Ausgang des Elements.
- **Rettung nicht möglich:** Die getestete Fahrt überschreitet eine Grenze oder verfehlt den Ausgang.

„Ohne Rettung“ schließt die gewöhnliche Kurvenführung der unteren Stufen nicht aus.
Der Bericht nennt sie ausdrücklich. Sonst könnte eine scheinbar hilfefreie Prüfung ihre tatsächliche Lenkhilfe verbergen.

Der Bericht nennt Strecke, Datenstand, Fahrregelversion, Hilfestufe, Zeitschritt und Rechentoleranz.
Er nennt außerdem Startzustände, Tempobefehle, Lenkzeitpunkte, verwendete Hilfen und geprüfte Grenzfälle.
Er enthält die Elementfolge, die gemessenen Zeiten, die kleinsten Abstände zu Grenzen und die Fehlergründe.
Eine nicht geprüfte Kombination bleibt „nicht geprüft“. Eine Stichprobe beweist keine mathematische Vollständigkeit.

Die Anzeige „zu langsam“, „passend“ oder „zu schnell“ verwendet dieselben gültigen Bereichsdaten wie der Bericht.
Sie verwendet keine zusätzliche Tabelle mit unabhängig gepflegten Grenzen.
Bei einem unpassenden Fahrzeugzustand oder veralteten Daten zeigt sie keinen gesicherten Tempobereich an.
Eine Änderung der Strecke, Fahrregeln oder Hilfsprofile macht den bisherigen Bericht ungültig.

### Abnahme des zweiten Ausbaus

- Zwei unterschiedliche Absprungtempi erzeugen ohne Rettung unterschiedliche Flugweiten.
- Zu langsame und zu schnelle Prüffahrten können den Landebereich verfehlen.
- Eine erfolgreiche Rettung erklärt jede zusätzliche Kraft durch ein passendes Ereignis und einen sichtbaren Effekt.
- Eine starke Bremsung vor der Rampe bleibt sichtbar. Der anschließende Rettungsschub bleibt davon unterscheidbar.
- Dieselben Eingaben liefern im Spiel und Simulator übereinstimmende Ergebnisse.
- Die Prüfung nennt mindestens eine saubere Gesamtfahrt je freigegebener Strecke und unterer Hilfestufe.
- Die Prüfung nennt die getesteten rettbaren Fehler und die Grenzen der Hilfe.
- Die Prüfung erfasst Übergänge zwischen Kurven, Rampen und Landungen ohne künstlichen Neustart des Fahrzeugzustands.
- Wiederholtes absichtliches Bremsen vor Rampen liefert in den Vergleichsfahrten keinen Zeitgewinn.
- Veränderte Streckendaten oder Fahrregeln verwerfen den alten Bericht.

## 8. Spätere Erweiterungen

Rampen und Steilkurven bilden die erste Grundlage. Danach folgen Reifen, Feuerringe und seitlich versetzte Landungen.
Versetzte Landungen können sich links und rechts abwechseln. Sie brauchen eine eigene Richtungsanforderung und einen klaren Eingabebereich.
Dieser Entwurf vergibt dafür noch keine zusätzliche Steuerung und keine automatische Lenkfreigabe.

Die Elementkennung und die Landedaten lassen sich erweitern. Sie brauchen dafür keine Abzweigungen.
Ein Looping verlangt später eine dreidimensionale Streckenrichtung mit einer eindeutigen Oberseite.
Die heutige Zuordnung im Bodenriss genügt dafür nicht. Der erste Ausbau baut deshalb noch keine Loopingberechnung ein.
Steinschlag braucht eine frühe Ankündigung. Er darf keine Prüfung blitzschneller Reaktionen erzeugen.

„Mittel“ soll später weniger Rettung bieten. „Schwer“ darf zusätzlich die persönliche Lautstärke für den Lenkeinschlag verwenden.
Zu hohes oder zu niedriges Tempo darf dann einen Sprung oder eine Landung verhindern.
Die höheren Stufen dürfen nicht hauptsächlich die Verzögerung der Spracherkennung bestrafen.
Der Entwurf behauptet keine neue Latenzmessung. Eine Latenzmessung würde die tatsächliche Zeit bis zur Eingabewirkung erfassen.

## 9. Offene Produktentscheidung und Selbstprüfung

Die zentrale offene Produktentscheidung betrifft den vorgeschlagenen Zeitverlust.
Soll eine gerettete Fahrt unter vergleichbaren Bedingungen immer langsamer bleiben als eine saubere Fahrt?
Der Entwurf empfiehlt diese Regel mit tatsächlichem Zeitverlust. Sie schützt den Unterschied zwischen sauberer Fahrt und Rettung.

Die übrigen Entwurfsentscheidungen bilden einen zusammenhängenden Vorschlag zur Prüfung.
Konkrete Grenzwerte erfordern Fahrversuche. Sie bilden eine Abnahmebedingung, keine bereits vorhandene Messung.

Die Selbstprüfung prüfte die Vorgaben gegen die beschriebenen Regeln und die gelesenen Quelldateien.
Sie trennte ausdrücklich den garantierten bisherigen Flug vom späteren tempoabhängigen Flug.
Sie prüfte die Grenzen zwischen Tempobefehl, Rufhilfe, Kurvenfreigabe und endgültigem Absturz.
Sie beschränkte den ersten Ausbau auf die vorhandenen Strecken und die unteren Stufen.
Sie stellte keine erfolgreichen Spieltests für die neuen Regeln fest. Diese Regeln existieren bisher nur in diesem Entwurf.

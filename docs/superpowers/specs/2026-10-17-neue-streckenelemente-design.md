# Neue Streckenelemente und austauschbare Blender-Modelle

Datum: 17. Oktober 2026

Status: Schriftlicher Entwurf zur Prüfung durch Stefan. Die Umsetzung hat noch nicht begonnen.

Branch: `codex/neue-streckenelemente`

## 1. Ziel und bestätigter Umfang

Stefan möchte neue Streckenelemente auf der Grundlage der beiden unteren Hilfestufen.
Der erste Ausbau umfasst Kuppen, Steilkurven, Sprungrampen, Landungen und einen Looping.
Eine neue Teststrecke verbindet diese Elemente mit Geraden und Kurven.
Die bestehenden Strecken behalten ihre bisherigen Fahrregeln.

Blender bleibt das Werkzeug für die späteren Modelle.
Die aktuelle Arbeit in Blender läuft unabhängig von diesem Ausbau.
Wir entwickeln die Fahrfunktion zunächst mit vorhandenen Modellen oder einfachen Ersatzmodellen.
Später genügt die Zuordnung eines passenden Blender-Modells im Modellverzeichnis.
Der Austausch verlangt keine Änderung am Fahrprogramm und keine Änderung an der Streckendatei.

Der Entwurf übernimmt die bestätigte Trennung von Streckenverlauf, Fahrregeln, Straßenmodellen und Landschaftsmodellen.
Er konkretisiert die Anschlussbedingungen aus dem [Entwurf zu den Hilfestufen](2026-10-17-hilfestufen-und-streckenpruefung-design.md), besonders dessen Abschnitt 7.

## 2. Ausgangslage

Das bestehende Modellpaket enthält neun Streckenteile.
Darunter sind eine Kuppe, zwei Steilkurven, eine Sprungrampe, eine Landerampe und ein Looping.
Die [Anleitung des Modellpakets](../../../assets/stuntcar_kit/README.md) beschreibt Maße und Anschlüsse.
Die bestehende Modellprüfung meldete am 17. Oktober 2026 insgesamt 2.881 Prüfungen ohne Fehler.
Diese Prüfung belegt noch keine befahrbaren Loopings.

Die bisherige Streckenberechnung ordnet das Auto über den Bodenriss zu.
Die Darstellung dreht das Auto über getrennte Winkel.
Die Kamera verwendet eine feste Richtung nach oben.
Das bisherige Sprungmodell gibt die Höhe entlang der Strecke vor.
Diese Verfahren reichen für den neuen räumlichen Verlauf und den tempoabhängigen Flug nicht aus.

## 3. Aufbau und Zuständigkeiten

| Teil | Aufgabe | Darf keine eigene Kopie enthalten von |
|---|---|---|
| Streckendaten | Elementfolge, Anschlüsse, Fahrflächen und Anforderungen beschreiben | Bewegungsberechnung |
| Räumlicher Streckenverlauf | Position und Ausrichtung entlang der Strecke liefern | Modellmaterialien |
| Fahrmodell | Bewegung, Kontakt, Flug, Landung und Hilfen berechnen | Landschaftsdarstellung |
| Straßenmodellverzeichnis | Passende sichtbare Modelle zuordnen und prüfen | Tempogrenzen und Lenkregeln |
| Landschaftsmodellverzeichnis | Landschaftsmodelle und ihre Platzierung zuordnen | Verdeckte Fahrhilfen |
| Auto und Kamera | Den berechneten Zustand verständlich darstellen | Zusätzliche Bewegung des Autos entlang der Strecke |
| Fahrprüfung | Dieselbe Bewegung mit festgelegten Eingaben ausführen | Eigenständige vereinfachte Fahrregeln |

Ein gemeinsamer Fahrzustand verbindet diese Teile.
Er enthält Position, Geschwindigkeit, Ausrichtung, Elementkennung, Streckenfortschritt und Bewegungszustand.
Er enthält außerdem aktive Hilfen, verbleibende Hilfsdauer und Ereignisse für die Darstellung.
Die Bewegungszustände unterscheiden Bodenkontakt, Flug und endgültigen Absturz.
Eine Landung bildet einen geprüften Übergang vom Flug zum Bodenkontakt.

## 4. Streckenformat und räumlicher Verlauf

### 4.1 Bestehende Strecken

Dateien mit `format_version: 1` behalten die bisherige Berechnung.
Die Auswahl einer neuen Strecke aktiviert keine neuen Fahrregeln für alte Strecken.
Alte Einstellungen und die beiden unteren Hilfestufen bleiben lesbar.
Die neue Teststrecke verwendet `format_version: 2`.
Unbekannte Versionen erzeugen eine verständliche Fehlermeldung.

### 4.2 Neue Streckendaten

Eine neue Strecke enthält eine geordnete Liste von Elementen.
Jedes Element besitzt eine eindeutige Kennung innerhalb der Strecke.
Jedes Element verweist auf eine versionierte Formbeschreibung.
Diese Beschreibung gehört zu den Fahrdaten und bleibt unabhängig vom sichtbaren Modell.

| Angabe | Bedeutung |
|---|---|
| Elementkennung und Elementart | Ordnen Eingaben, Hilfen und Prüfergebnisse eindeutig zu. |
| Formkennung und Formversion | Bestimmen Länge, Breite, räumlichen Verlauf und Fahrfläche. |
| Lage und Anschlüsse | Verbinden das Element mit seinem Vorgänger und Nachfolger. |
| Eingabeanforderung | Unterscheidet eine Kurve mit Richtungsbefehl von einem Element ohne Zusatzbefehl. |
| Hinweisbereich und Hilfsgrenzen | Bestimmen Vorlauf, unterstützte Zustände und Ende einer Hilfe. |
| Absprung und Landebereich | Beschreiben die erlaubten Übergänge zwischen Boden und Flug. |
| Tempoangaben und Prüfbezug | Nennen Mindesttempo, Höchsttempo, Zieltempo und ihre Gültigkeit. |
| Darstellungskennung | Wählt einen passenden Eintrag aus dem Straßenmodellverzeichnis. |

Die Datei nennt Straßenstil und Landschaftsstil getrennt.
Beispielsweise kann dieselbe Fahrbahn eine andere Oberfläche und eine andere Landschaft erhalten.
Die erste Umsetzung braucht dafür keine neue Stilauswahl im Spielmenü.

### 4.3 Position und Ausrichtung

Der Streckenverlauf verwendet die tatsächliche räumliche Länge in Metern.
Eine Abfrage liefert Position, Vorwärtsrichtung, Rechtsrichtung und Richtung zur Fahrbahnoberseite.
Die drei Richtungen stehen senkrecht aufeinander und besitzen die Länge eins.
Die Fahrbahnoberseite kann im Looping nach unten zeigen.
Die Richtung nach oben in der Spielwelt ersetzt diese Angabe nicht.

Die Zuordnung des Autos berücksichtigt seine bisherige Elementkennung und seinen bisherigen Fortschritt.
Sie sucht zuerst im aktuellen Element und an den erlaubten Übergängen.
Eine räumlich nahe Fahrbahn darf das Auto nicht auf einen anderen Teil des Loopings versetzen.
Neustarts verwenden einen ausdrücklich bezeichneten Startpunkt.
Eine Landung sucht nur in den zulässigen Landeflächen des aktuellen Sprungs.

Benachbarte Elemente müssen Position, Fahrtrichtung und Fahrbahnoberseite passend verbinden.
Der erste Ausbau verlangt höchstens einen Millimeter Positionsabweichung und 0,1 Grad Richtungsabweichung an den Anschlüssen.
Diese Werte sind Abnahmeanforderungen. Sie sind keine bereits gemessenen Ergebnisse.
Einheiten, ungültige Zahlen, doppelte Kennungen und widersprüchliche Anschlüsse prüft der Lader vor dem Start.

## 5. Verbindliche Regeln für austauschbare Modelle

### 5.1 Gemeinsame Maße

Eine Einheit entspricht einem Meter.
Im Spiel zeigt die lokale Y-Achse zur Fahrbahnoberseite.
Die lokale Richtung −Z zeigt in Fahrtrichtung.
Die erste Modellfamilie verwendet eine sechs Meter breite Fahrbahn.
Der Import gleicht die Blender-Achsen einmal an diese Spielachsen an.
Die Prüfung kontrolliert das Ergebnis nach dem Import.

Die Anschlüsse heißen `Entry` und `Exit`.
Beide Anschlüsse enthalten eine Position und eine vollständige Ausrichtung.
Eine kleine Godot-Szene fasst das importierte Modell und seine Anschlüsse zusammen.
So hängt die Fahrfunktion nicht von der inneren Struktur einer Blender-Datei ab.

### 5.2 Modellverzeichnis

Jeder Eintrag nennt eine stabile Darstellungskennung und eine Modellversion.
Er nennt den Pfad zur Godot-Szene, die unterstützte Formkennung und deren Formversion.
Er nennt außerdem die erwarteten Anschlüsse, Maße und die zulässige Rolle des Modells.
Die Rollen unterscheiden Straßenmodell und Landschaftsmodell.
GLB ist das vorgesehene Austauschformat aus Blender.
Das Spiel benötigt zum Laden keine laufende Blender-Anwendung.

Materialien und sichtbare Unterteile dürfen sich zwischen Modellen unterscheiden.
Das Fahrprogramm sucht keine beliebigen Objektnamen innerhalb des importierten Modells.
Es verwendet nur die vereinbarten Angaben der umgebenden Godot-Szene.
Eine neue Modellversion erhält eine eigene Datei.
Der Austausch ändert gezielt den Verzeichniseintrag und erlaubt damit auch die Rückkehr zur vorherigen Version.

### 5.3 Fahrfläche und sichtbares Modell

Die Formbeschreibung bestimmt die befahrbare Fläche und die Fläche für Zusammenstöße.
Ein sichtbares Straßenmodell bringt keine zusätzliche aktive Fläche für Zusammenstöße mit.
Die Einbindung deaktiviert solche Flächen aus importierten Modellen.
Das verhindert doppelte Flächen und unsichtbare Hindernisse nach einem Modellwechsel.

Ein passendes Modell muss derselben Form folgen.
Nur passende Endpunkte genügen nicht: Auch die Fahrfläche zwischen den Anschlüssen muss passen.
Die Importprüfung vergleicht gekennzeichnete Fahrflächen mit der Formbeschreibung.
Sie prüft beide Ränder und die Mitte über den ganzen Verlauf.
Die zulässige Abweichung beträgt höchstens zwei Zentimeter an den geprüften Stellen.
Der Bericht nennt den Abstand der Prüfstellen und die Grenzen dieser Stichprobe.

Die Bildprüfung kontrolliert zusätzlich sichtbare Lücken, Überschneidungen und verdeckte Fahrbahnen.
Der Import verändert keine Form durch heimliches Strecken oder Stauchen.
Ein Modell mit anderem Radius, anderer Breite oder anderer Rampenrichtung verlangt eine neue Formversion.
Dann braucht die Strecke eine neue Fahrprüfung.

Landschaftsmodelle dienen zunächst der Darstellung.
Die Strecke beschreibt erforderlichen Boden und feste Hindernisse getrennt als Flächen für Zusammenstöße.
Ein Felsmodell darf deshalb nicht allein durch seinen Austausch das Fahrverhalten verändern.
Die Platzierungsprüfung hält Fahrbahn, Landebereiche und den vorgesehenen Kamerabereich frei.

### 5.4 Austausch aus Blender

1. Erstelle das Modell anhand der passenden Formvorlage.
2. Exportiere das Modell als GLB.
3. Ordne die Datei einer Godot-Szene mit den vereinbarten Anschlüssen zu.
4. Trage die Szene im Modellverzeichnis ein.
5. Führe die Importprüfung und die Bildprüfung aus.
6. Aktiviere den geprüften Eintrag für den gewünschten Stil.

Ein fehlendes oder unpassendes sichtbares Modell aktiviert das passende Ersatzmodell.
Die Anzeige nennt den betroffenen Eintrag verständlich.
Fehlen dagegen gültige Fahrdaten, sperrt das Spiel die betroffene Strecke.
Ein Ersatzmodell darf keine ungültigen Fahrdaten verdecken.

## 6. Fahrregeln für die neuen Elemente

### 6.1 Gemeinsame Berechnung

Spiel und Fahrprüfung verwenden denselben Bewegungsschritt mit 60 Schritten pro Sekunde.
Die Darstellung darf häufiger oder seltener aktualisieren.
Sie verändert dadurch weder Tempo noch Hilfsdauer.
Die Berechnung übernimmt den Zustand ohne Zurücksetzen von einem Element zum nächsten.

Das Fahrmodell berücksichtigt die Schwerkraft entlang der Fahrbahn.
Es prüft den erforderlichen Kontakt zur Fahrfläche auch an Kuppen und im Looping.
Eine begrenzte zusätzliche Haltekraft gehört ausdrücklich zum Hilfsprofil, falls die unteren Stufen sie benötigen.
Das Profil begrenzt Stärke und Dauer dieser Kraft.
Eine Überschreitung führt zum Kontaktverlust und zum Flug.
Das Auto darf nicht allein durch seinen Streckenfortschritt an der Fahrbahn haften.

### 6.2 Kuppe, Steilkurve und Looping

Kuppen und Steilkurven verwenden denselben räumlichen Verlauf wie der Looping.
Eine Steilkurve behält ihre Richtungsanforderung.
Ein Looping benötigt im ersten Ausbau keinen zusätzlichen Ruf und keine neue Taste.
Das Überfahren seiner Einfahrt beginnt den Looping.
Sein seitlicher Versatz gehört zur Form und verlangt keinen gesonderten Lenkbefehl.

Die Hilfe bereitet das notwendige Tempo bereits vor der Einfahrt vor.
Mindesttempo und Höchsttempo hängen vom Zustand und von der gewählten Hilfestufe ab.
Die Fahrprüfung ermittelt geeignete Bereiche für die gesamte Durchfahrt.
Eine bloße Formel für den höchsten Punkt ersetzt diese Prüfung nicht.
Zu geringer Kontakt oder ein verfehlter Ausgang gilt als fehlgeschlagene Fahrt.

### 6.3 Sprung und Landung

Beim Absprung übernimmt das Auto seine tatsächliche Position und Geschwindigkeit.
Die Rampenrichtung bestimmt die anfängliche Flugrichtung.
Die Schwerkraft verändert die Geschwindigkeit während des Flugs.
Unterschiedliche Absprungtempi können unterschiedliche Landepunkte erzeugen.

Eine Landung erfordert Kontakt mit dem vorgesehenen Landebereich.
Die Prüfung berücksichtigt Position, Bewegungsrichtung, Ausrichtung und zulässige Aufprallgeschwindigkeit.
Sie prüft auch den Weg zwischen zwei Rechenschritten.
Das Auto darf dadurch eine Landefläche bei hohem Tempo nicht überspringen.
Eine verfehlte Landung bleibt ein Fehler.
Das Spiel setzt das Auto nicht unbemerkt auf die Zielrampe.

Bremskräfte durch Reifen wirken nur bei Bodenkontakt.
Eine Hilfskraft im Flug benötigt eine eigene Grenze und ein sichtbares Ereignis.
Der erste Ausbau verwendet dafür höchstens einen begrenzten Zusatzschub.
Er erhält keine unsichtbare freie Verschiebung zur Landung.

## 7. Die beiden unteren Hilfestufen

„Sehr leicht“ und „Leicht“ bleiben die einzigen Stufen dieses Ausbaus.
Die vorhandenen Regeln für Kurvenfreigaben und leise Rufe gelten weiter.
Eine Eingabe gibt höchstens die zugeordnete Kurve frei.
Eine Rampe oder ein Looping gibt keine folgende Kurve frei.
Ein Tempobefehl zählt nicht zusätzlich als Richtungsbefehl.

Beide Stufen können das Tempo vor einem neuen Element innerhalb ihrer festen Grenzen anpassen.
„Sehr leicht“ erhält einen größeren geprüften Hilfsbereich als „Leicht“.
Die endgültigen Kraftgrenzen stehen in versionierten Hilfsprofilen.
Die Umsetzung bestimmt diese Werte durch die Fahrprüfung, bevor sie eine Strecke freigibt.
Dieser Entwurf behauptet dafür noch keine sicheren Zahlenwerte.

Eine Hilfe braucht ausreichenden Vorlauf und einen unterstützten Ausgangszustand.
Sie darf eine fehlende Kurvenfreigabe oder einen endgültigen Absturz nicht aufheben.
Beschleunigen, Bremsen und wiederholte Tempowechsel gehören zur Prüfung der Hilfsgrenzen.
Eine besondere Rettung darf in vergleichbaren Gesamtfahrten keinen Zeitvorteil erzeugen.
Die Anzeige unterscheidet gewöhnliche Führung, besondere Rettung und einen nicht mehr rettbaren Zustand.

## 8. Tempoangaben und Prüfberichte

Jedes relevante Element kann Mindesttempo, Höchsttempo und Zieltempo enthalten.
Ein unbekannter Wert bleibt ausdrücklich unbekannt.
Die Anzeige darf aus fehlenden Werten kein unbegrenztes Sicherheitsversprechen ableiten.

Ein geprüfter Bereich nennt Hilfestufe, Anfahrzustand, Eingabeanforderung und geltende Fahrregeln.
Der Prüfbericht enthält Versionen und Prüfsummen der Strecke, der Formbeschreibungen und der Hilfsprofile.
Er enthält auch die Flächen für Zusammenstöße und den verwendeten Rechenschritt.
Änderungen dieser Daten machen den Bericht ungültig.

Ein reiner Modellwechsel erhält den Bericht zur Fahrberechnung.
Er verlangt jedoch erneut eine Importprüfung und eine Bildprüfung.
Die Freigabe der sichtbaren Strecke verlangt beides: gültige Fahrdaten und eine geprüfte Darstellung.
Die Anzeige verwendet dieselben Tempoangaben wie die Fahrprüfung.

Der Bericht unterscheidet saubere Fahrt, Rettung möglich und Rettung nicht möglich.
Er nennt Eingaben, Zeiten, Kontakte, Hilfskräfte und Fehlergründe.
Die Prüfung ganzer Strecken setzt das Tempo zwischen Elementen nicht zurück.
Dadurch zeigt sie auch einen zu kurzen Beschleunigungsweg zwischen Kurve und Rampe.

## 9. Auto und Kamera

Das Auto übernimmt die vollständige räumliche Ausrichtung aus dem Fahrzustand.
Im Looping zeigt seine Oberseite zeitweise nach unten.
Die Darstellung erzeugt keine andere Fahrzeugposition als die Fahrberechnung.
Kleine sichtbare Bewegungen dürfen die tatsächliche Spur und einen verfehlten Kontakt nicht verdecken.

Die Kamera folgt der räumlichen Fahrtrichtung.
Sie übernimmt eine stetig fortgeführte Ausrichtung entlang der Strecke.
Sie verwendet an senkrechten Stellen keine instabile Berechnung mit einer festen Richtung nach oben.
Im Looping folgt sie der Drehung des Streckenverlaufs ohne plötzlichen Seitenwechsel.
Am Ausgang geht sie stetig in die normale Ausrichtung über.

Der erste Ausbau verwendet eine feste Kameraregel für beide unteren Stufen.
Er erhält keinen zusätzlichen Kameramodus.
Die Bildprüfung erfasst Einfahrt, senkrechten Abschnitt, höchsten Punkt und Ausfahrt.
Ein Spielversuch prüft Orientierung und Wohlbefinden während der vollständigen Fahrt.

## 10. Erste Teststrecke und Abnahme

Die Teststrecke enthält eine Gerade, eine Kuppe, eine Steilkurve, einen Sprung mit Landung und einen Looping.
Weitere Geraden schaffen den erforderlichen Vorlauf zwischen diesen Elementen.
Mindestens eine weitere Kurve nach einem Stuntelement prüft die neue Eingabeanforderung.
Die Strecke verwendet zunächst die vorhandenen Formen und passende Ersatzmodelle.

| Prüfung | Erforderliches Ergebnis |
|---|---|
| Bestehende Strecken | Die vorhandenen Fahrprüfungen für beide unteren Stufen bestehen weiterhin. |
| Räumliche Anschlüsse | Lage und Ausrichtung bleiben innerhalb der festgelegten Anschlussgrenzen. |
| Looping-Zuordnung | Das Auto wechselt nicht auf einen räumlich nahen, falschen Streckenabschnitt. |
| Kontaktgrenzen | Prüfungen unmittelbar vor, auf und nach der Grenze ergeben den richtigen Zustand. |
| Unterschiedliche Absprungtempi | Sie erzeugen unterschiedliche Flugbahnen ohne versteckte Zielkorrektur. |
| Ungültige Landung | Das Auto verfehlt den Landebereich oder scheitert an dessen Kontaktgrenzen. |
| Vollständige Fahrt | Beide unteren Stufen erreichen mit passenden Eingaben das Ziel. |
| Fehlende Kurveneingabe | Ein vorheriger Sprung oder Looping ersetzt den notwendigen Befehl nicht. |
| Späte Eingaben und Tempowechsel | Die Hilfe hält ihre angegebenen Grenzen ein. |
| Rettungsvergleich | Eine absichtlich ausgelöste Rettung erzeugt keinen Zeitvorteil. |
| Pause und Neustart | Alte Eingaben und alte Hilfsereignisse wirken nicht weiter. |
| Gleiche Eingaben | Spiel und Fahrprüfung liefern innerhalb derselben Laufzeit dieselben Fahrzustände. |
| Zwei Darstellungen | Derselbe Ablauf liefert bei beiden Modellzuordnungen dieselben Fahrzustände und Ereignisse. |
| Fehlendes Modell | Das passende Ersatzmodell erhält die Spielbarkeit. |
| Falsche Form | Die Prüfung weist den Modelltausch zurück. |
| Veränderte Fahrdaten | Der alte Fahrbericht gilt nicht mehr. |
| Kamera | Kein plötzlicher Seitenwechsel und keine ungültige Ausrichtung im Looping. |

Die erste Austauschprüfung benötigt keine neue Blender-Datei.
Zwei vorhandene oder einfache Darstellungen können denselben Austauschweg prüfen.
Eine spätere Blender-Datei muss denselben Importvertrag erfüllen.

Bei Vergleichen über verschiedene Laufzeiten nennt der Bericht die verwendeten Toleranzen.
Die Umsetzung darf Abweichungen nicht durch beliebig große Toleranzen verdecken.
Automatische Prüfungen ersetzen weder die Bildprüfung noch einen Spielversuch.

## 11. Reihenfolge der Umsetzung

Die folgende Reihenfolge beschreibt die Abhängigkeiten. Sie ersetzt keinen detaillierten Umsetzungsplan.

1. Ergänze die versionierten Formbeschreibungen und die räumlichen Streckenabfragen.
2. Ergänze das Modellverzeichnis mit Importprüfung und Ersatzmodellen.
3. Ergänze den räumlichen Bodenkontakt und die vollständige Ausrichtung des Autos.
4. Ergänze den tempoabhängigen Flug und die Landungsprüfung.
5. Ergänze die begrenzten Hilfen und die gültigen Tempoangaben.
6. Ergänze die Teststrecke und die räumliche Kameraführung.
7. Prüfe vollständige Fahrten und den Austausch der Darstellungen.

Die Arbeit verändert keine Modelle in der laufenden Blender-Sitzung.
Neue Dateien für diese Aufgabe erhalten eigene Pfade.
Die Umsetzung übernimmt fremde lokale Änderungen nicht in ihre eigenen Commits.

## 12. Grenzen dieses Ausbaus

Dieser Ausbau enthält keine neuen Hilfestufen und keine allgemeine Fahrzeugsimulation.
Er enthält keine Abzweigungen, keinen Streckeneditor und keine automatisch erzeugten Strecken.
Feuerringe, bewegliche Hindernisse und seitlich versetzte Sprunglandungen folgen in eigenen Ausbauschritten.
Die Modellzuordnung erlaubt spätere Erweiterungen, verspricht aber keinen beliebigen Formtausch ohne Prüfung.

## 13. Selbstprüfung und nächster Schritt

Der Entwurf trennt sichtbare Modelle von Fahrflächen und Fahrregeln.
Er beschreibt den Austausch aus Blender einschließlich Prüfung und Rückfall auf Ersatzmodelle.
Er erhält die bisherigen Strecken und die Regeln für leise Eingaben.
Er verlangt tempoabhängige Sprünge, räumliche Loopings und begrenzte Hilfen.
Er unterscheidet vorgeschlagene Anforderungen von bereits gemessenen Ergebnissen.

Nach Stefans Prüfung dieses Entwurfs folgt der detaillierte Umsetzungsplan.

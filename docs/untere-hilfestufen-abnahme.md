# Untere Hilfestufen: Stand der Prüfung

Stand: 17. Oktober 2026.

Die Umsetzung umfasst „Sehr leicht“ und „Leicht“ auf den vier bestehenden Strecken.
Das Spiel zeigt die Namen weiterhin auf Englisch.
Die Streckenform und die vorhandene Sprungbahn bleiben erhalten.

## Verhalten

| Teil | Ergebnis |
| --- | --- |
| Sehr leicht | Beide Richtungseingaben können eine Kurve freigeben. Ein gültiger leiser Ruf kann dies ebenfalls. |
| Leicht | Die richtige Richtung gibt eine Kurve frei. |
| Folgekurve | Sie braucht eine neue Eingabe. |
| Lautstärke | Sie verändert die Lenkhilfe nicht. Sie beeinflusst weiterhin die Tempobefehle. |
| Späte Eingabe | Die Hilfe senkt das Tempo und führt das Auto durch die Kurve. |
| Vollgas | Die angenommene Kurvenhilfe bleibt wirksam. Sehr leicht ergänzt einen begrenzten Schlingerimpuls. |
| Auswahl | Ein neuer Start übernimmt die gewählte Stufe. Eine Pause erhält die aktive Stufe. |
| Leise Rufprobe | Zwei Sekunden Raumgeräusch und drei leise Laute ergeben ein eigenes Mikrofonprofil. |
| Tempodaten | Jede Kurve und jede Rampe enthält ein erweiterbares Hinweisobjekt. |

Die Kurvenhinweise gelten für die geprüfte Hilfe bis 58 Meter pro Sekunde.
Sie beschreiben keine Grenze der Reifenhaftung ohne Hilfe.
Die Rampenwerte bleiben ungeprüft und leer (`null`).
Das vorhandene Flugmodell kann keine physikalische Mindestgeschwindigkeit bestätigen.
Das Datenformat enthält Mindesttempo, Höchsttempo, Zieltempo, Prüfstatus und Modellkennung.
Die Kurvenhilfe nutzt ein bestätigtes Höchsttempo als eigenes Ziel.
Sie erhält dabei das Spielerziel.

## Automatische Prüfung

Die Ausgangsprüfung bestand vor der Umsetzung.
Die Abschlussprüfung besteht ebenfalls.

- 21 bestehende Godot-Prüfprogramme bestehen.
- 84 Python-Tests für die Sprachsteuerung bestehen.
- Der Textkatalog und die Streckenprüfung bestehen.
- Neun neue Godot-Prüfprogramme bestehen.
- Die Streckenmatrix enthält 528 vollständige Fahrten ohne Fehler.
- Die Randprüfung enthält 128 kombinierte Anfangszustände ohne Fehler.

Die Matrix prüft beide Stufen und alle vier Strecken.
Sie prüft die Vorlaufwerte 3, 5 und 8 Sekunden.
Die Anfangstempi sind 0, 5, 10, 14, 15, 20, 22, 25, 28, 30, 35, 40, 45, 46, 50, 55 und 58 Meter pro Sekunde.
Bei Tempo 0 prüft sie zuerst den Stillstand und danach das Anfahren.
Weitere Fahrten prüfen frühe, späte und sehr späte Eingaben.
Weitere Fahrten prüfen Vollgas, Vollbremsung und wechselnde Tempobefehle.
Eine erfolgreiche Fahrt braucht keine zusätzliche Lenkeingabe innerhalb einer angenommenen Kurve.
Der kleinste seitliche Abstand zur Absturzgrenze beträgt in dieser Matrix etwa 2,04 Meter.

Die Randprüfung beginnt an zwei Stellen jeder Kurve.
Sie kombiniert beide seitlichen Grenzen mit beiden Richtungsgrenzen bei 58 Metern pro Sekunde.
Die zulässige Richtungsabweichung beträgt weniger als 20 Grad.
Der zulässige seitliche Abstand beträgt weniger als 2,4 Meter.
Die Hilfe sichert den Ausgang noch 16 Meter.

64 Vergleichspaare prüfen den Zeitverlust einer späten oder sehr späten Eingabe.
Keine Rettung bringt einen Zeitvorteil.
Der kleinste zusätzliche Zeitbedarf beträgt 1,5 Sekunden.

Die Tests verwenden Schritte von 1/60 Sekunde.
Der [Fahrbericht](untere-hilfestufen-testresultate.json) enthält jeden geprüften Fall.
Er nennt Eingaben, Positionen, Tempi, Zeiten und seitliche Abstände.
Prüfsummen benennen den genauen Stand des Fahrmodells und der Streckendaten.
Die Stichproben beweisen nicht jede mögliche Kombination.
Künftige Strecken brauchen eigene Fahrprüfungen.

## Sichtprüfung

Die echte Godot-Szene lief mit der vorhandenen Grafik auf diesem Mac.
Die Sichtprüfung umfasste die Einstellungen, die Rufübung und das Schlingern.
Das Einstellungsmenü nutzt jetzt zwei Spalten.
Alle Einträge stehen oberhalb der Bedienhinweise.
Die Bilder entstanden durch künstliche Eingaben.
Sie belegen keine menschliche Mikrofonprobe.

## Noch offene Erprobung

Es fand keine neue Probe mit einer menschlichen Stimme statt.
Es fand kein Spielversuch mit Menschen mit eingeschränkter Sprechlautstärke statt.
Die technische Prüfung ersetzt diese Erprobung nicht.

Stefan oder weitere Testpersonen müssen die angenehme Ruflautstärke am tatsächlichen Mikrofon prüfen.
Dabei müssen Raumgeräusche, Mikrofonabstand und Sprechpausen vorkommen.
Beide Stufen brauchen außerdem einen Spielversuch mit Tastatur und Sprache.
Dabei müssen die Testpersonen die Hinweise und das Schlingern beurteilen.

## Entscheidungen während der Umsetzung

1. Die Tempodaten gehören bereits zu diesem Auftrag. Rampengrenzen bleiben leer. Eine echte Sprungprüfung bleibt später nötig.
2. Fremde Änderungen bleiben außerhalb der eigenen Commits. Ihre Fehler brauchen eine getrennte Zuordnung.
3. Der Planhelfer erkennt die deutschen Aufgabenüberschriften nicht. Eine manuelle Fortschrittsliste hält die Aufgaben und Ergebnisse fest.
4. Godot nutzt einen beschreibbaren Pfad für die Prüfprotokolle. Diese Anpassung verändert das Spiel nicht.
5. Die Prüfung nutzt die vorhandene Laufzeit und die vorhandenen Sprachmodelle. Eine lokale Verknüpfung und der Zugriff auf den Test-Cache ermöglichen dies.
6. Die Randprüfung begrenzt die Annahme auf weniger als 20 Grad. Die Hilfe sichert den Ausgang noch 16 Meter. Ein stärker verdrehtes Auto erhält keine neue Zusage.
7. Langsame Fahrten erhalten ein längeres, weiterhin endliches Eingabefenster. Bei Stillstand bleibt der Hinweis deshalb länger offen.
8. Bei dicht folgenden Kurven prüft die Matrix das erste offene Fenster. Eine Vorschau-Eingabe während der vorherigen Ausgangshilfe ist nicht möglich.
9. Die fehlende Ablehnungsanzeige zählt für diese zugängliche Steuerung als wichtiger Fehler. Ihre Korrektur ergänzt eine Meldung und verändert keine Fahrregel.
10. Die vorhandenen Landschaftsarbeiten bleiben außerhalb dieses Auftrags. Die Abschlussprüfung bewertet deren Änderungen nicht.
11. Tempoabhängige Sprünge, ein allgemeiner Streckensimulator und weitere Hilfestufen folgen später. Die neuen Daten bestätigen keine künftigen Strecken.
12. Menschliche Mikrofonproben bleiben offen. Die Zugänglichkeit am tatsächlichen Gerät bleibt deshalb unbestätigt.
13. Die Änderungen bleiben im lokalen Arbeitsbaum. Andere Arbeitsbäume und veröffentlichte Versionen erhalten sie noch nicht.

## Unabhängige Abschlussprüfung

Eine unabhängige Codeprüfung fand vier wichtige Fehler und eine fehlende Rückmeldung.
Gezielte Tests bestätigten diese Fehler vor der Korrektur.

- Die Worterkennung nutzt jetzt das persönliche Geräuschniveau. Das gilt auch für „Leicht“.
- Eine mögliche Rufhilfe wartet auf die endgültige Wortprüfung derselben Äußerung.
- Das Mikrofonprofil bleibt vor einem Kurvenfenster aktiv. Ein Dauerlaut beginnt dort nicht neu.
- Die Hilfe verwendet getrennte Grenzen für Beschleunigung und Bremsung.
- „Leicht“ zeigt eine abgelehnte Richtung an. Eine richtige Eingabe entfernt diese Meldung.

Die fehlende Rückmeldung zählt für diese zugängliche Steuerung als wichtiger Fehler.
Die Korrektur ergänzt eine kurze Meldung und verändert keine Fahrregel.
Alle fünf Befunde erhalten einen Test.
Die Abschlussprüfung verschiebt keinen gefundenen Fehler auf später.
Die menschliche Erprobung bleibt davon getrennt.

# Astra-Review der ersten Umsetzung

Astra prüfte den gesamten Umbau von `d386185` bis `26a8e00` unabhängig.
Der Prüfer änderte keine Produktdatei.
Der Prüfer führte vier vorhandene Prüfeinstiege mit zusammen 104 Bedingungen erneut aus.
Diese Bedingungen bestanden. Zusätzliche Abläufe zeigten vier wichtige Fehler.
Der Prüfer meldete keinen kritischen und keinen kleinen weiteren Befund.

## Befunde und Korrekturen

| Befund | Ursache | Korrektur und Nachweis |
|---|---|---|
| Eine Teilverlängerung verliert den Schutz des Lenkwunschs. | Der Kern ersetzt den gesamten Ausführungsdatensatz durch das verlängerte Mitglied. | Der Kern erhält unveränderte Mitglieder, ihre ausdrückliche Herkunft und ihre Enden. Die Anbindungsprüfung verlängert nur das Pedal. Zwei spätere Rufe ändern links nicht in rechts. |
| Ein Quellenabbruch lässt eine angenommene Verlängerung erneut starten. | Der Kern verarbeitet die lokale Liste nach dem Abbruch weiter. | Der Kern beendet die Quelle vor der Auswahl. Er verwirft ihre angenommenen Nachrichten. Die Anbindungsprüfung misst Pedal und Zieltempo in beiden Nachrichtenfolgen. Eine weitere Prüfung schützt die übrigen Quellen. |
| Eine leere Ausschlussgruppe beendet unabhängige Aktionen. | Der Ersatzpfad behandelt die leere Gruppe wie eine gemeinsame Gruppe. | Der Ersatzpfad überspringt leere Gruppen. Die Controllerprüfung startet zwei unabhängige Aktionen und verlängert danach die erste. |
| Ein Gasbefehl entfernt die aktive Lenkbestätigung. | Jede neue Bestätigung ersetzt den gesamten Anzeigenzustand. | Der Router erhält Bestätigungen unabhängiger aktiver Mitglieder. Die echte Anzeige zeigt links auch nach Gasbeginn und regelmäßiger Pedalverlängerung. |

Die neuen Prüfungen scheiterten zuerst am jeweiligen Fehler.
Nach der Korrektur bestehen die gezielten Prüfungen.
Die Controllerprüfung umfasst jetzt 32 Bedingungen.
Die Anbindungsprüfung umfasst jetzt 24 Bedingungen.
Die Anzeigeprüfung umfasst jetzt elf Bedingungen.
Die vollständige erneute Abnahme besteht nach den Korrekturen mit 32 von 32 Aufträgen.
Zwei Erzeugungen liefern denselben aktuellen Fahrbericht.
Die vier vollständigen Fahrten mit Darstellung erreichen erneut das Ziel.

Eine zusätzliche Hilfe startet keine neue Aktion in einer noch ausdrücklich belegten Ausschlussgruppe.
Die bereits laufende ausdrückliche Aktion wirkt weiter.
Damit übernimmt eine schwächere Rufauswahl nicht deren Zuständigkeit durch eine unnötige Wiederholung.
Ein neuer ausdrücklicher Gegenbefehl darf diese Gruppe weiterhin ersetzen.

## Vom Prüfer abgegrenzte Fragen

- Neue Sprachkombinationen und Gesten gehören ausdrücklich nicht zur ersten Lieferung. Der gemeinsame Vertrag unterstützt Kombinationen bereits.
- Vorausberechnung, Referenzfahrten und Training gehören ausdrücklich nicht zur ersten Lieferung.
- Menschliche Sprachprobe und Windows-Probe bleiben offen. Automatische Prüfungen ersetzen diese Proben nicht.

Diese Abgrenzungen entsprechen dem vereinbarten Umfang.
Ihr Preis bleibt die jeweils noch fehlende Funktion oder menschliche Probe.
Die Grenze von 30 Sekunden und der Vorrang ausdrücklichen Gases stehen als bewusste Planentscheidungen im Prüfstand.

## Urteil des unabhängigen Prüfers

Der geprüfte Stand benötigt die vier Korrekturen vor der Freigabe.
Die Korrekturen betreffen Spielerhoheit, Quellenabbruch, Wiederverwendung und Anzeige.
Der abschließende Prüfstand nennt die erneute automatische Abnahme nach den Korrekturen.

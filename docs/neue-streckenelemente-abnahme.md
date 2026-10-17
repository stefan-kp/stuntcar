# Neue Streckenelemente und Prüfergebnisse

Stand: 17. Oktober 2026. Branch: `codex/neue-streckenelemente`.
Die neue Strecke heißt im Spiel „Stunt course“.
Sie steht für „Very easy“ und „Easy“ bereit.
Die Arbeit hat keine Blender-Sitzung verwendet.

## Inhalt

Die Strecke verwendet 23 Elemente auf 619,31 Metern Fahrfläche.
Hinzu kommt eine Sprunglücke von 24 Metern.
Die Strecke verbindet eine Kuppe, eine Steilkurve, einen Sprung, eine Landung und einen Looping.
Nach dem Looping folgt eine weitere Kurve.
Jede Kurve benötigt eine eigene Eingabe.
Sprung und Looping benötigen keine neue Taste.

Das Auto folgt einer räumlichen Fahrfläche.
Bei Kontaktverlust beginnt ein Flug mit Schwerkraft.
Eine Landung benötigt einen tatsächlichen Kontakt mit einer erlaubten Landefläche.
Die Kamera folgt auch senkrechten und umgekehrten Fahrzeuglagen.
Ein stärkerer gültiger Aufprall erzeugt stärkeres Einfedern und einen stärkeren Ton.
Reifenspuren und Reifenrauch benötigen Bodenkontakt.
Die Effekte verändern die Fahrberechnung nicht.

Die vier bisherigen Strecken behalten ihr vorhandenes Fahrmodell.
Die neue Fahrberechnung ergänzt Godot. Sie benötigt keine zusätzliche Physik-Engine.

## Messwerte und Abstimmung

| Prüfung | Ergebnis |
| --- | --- |
| Saubere Gesamtfahrt Sehr leicht | 32,80 Sekunden |
| Saubere Gesamtfahrt Leicht | 32,78 Sekunden |
| Untersuchte Anfangstempi | 0, 5, 14, 22, 35, 46 und 58 m/s |
| Fahrfälle | 98 Kombinationen aus Stufe, Anfangstempo und Eingabeart |
| Alte Streckenmatrix | 528 Fahrten ohne Fehler |
| Python-Prüfungen | 84 ohne Fehler |
| Sprachkatalog | 3 Prüfungen ohne Fehler |
| Untere Sprunggrenze im geprüften Absprungzustand | Zwischen 20,01416 und 20,01435 m/s |
| Obere Sprunggrenze im geprüften Absprungzustand | Zwischen 22,44147 und 22,44263 m/s |
| Geprüfte seitliche Landepositionen | 2,99 m gelingt; 3,01 m verfehlt die Fahrfläche |
| Hilfe je Element | Höchstens 10 Sekunden bei Sehr leicht; 9 Sekunden bei Leicht |
| Simulierte Dauer der Effektprüfung | 600 Sekunden mit 60 Schritten pro Sekunde |
| Höchste Anzahl der Reifenspuren | 256 |
| Fest belegte Partikel | 48 |

Die ersten Gesamtfahrten scheiterten an zwei Stellen.
Die ursprünglichen Zeitgrenzen von vier und zwei Sekunden endeten vor dem Ende der Kuppe.
Die gemessene Hilfezeit betrug dort etwa 8,38 beziehungsweise 8,35 Sekunden.
Die neuen Zeitgrenzen bleiben endlich und gelten je Element.
Ein neuer Tastendruck erneuert diese Zeit nicht.

Das ursprüngliche Sprungtempo von 20 m/s reichte knapp nicht für die Lücke.
Die Strecke fordert nun 20,5 bis 21,5 m/s und verwendet 21 m/s als Zieltempo.
Die obere Landungsgrenze bleibt bei 12 m/s normalem Aufpralltempo.
Der zulässige Winkel bleibt bei 20 Grad.
Die Abstimmung hat diese Grenzen nicht erhöht.

Dauerhaftes Beschleunigen und wechselnde Tempobefehle erreichen in der Matrix das Ziel.
Dauerhaftes Bremsen hält das Auto an.
Fehlende Kurveneingaben führen zum Abbruch.
Leicht weist die falsche Richtung zurück.
Sehr leicht erlaubt die bekannte Hilfe auch bei falscher Richtung.
Erfolgreiche späte Fahrten sind nicht schneller als die entsprechende saubere Fahrt.
Bei hohem Anfangstempo kann das Eingabefenster vor einer erst spät gesendeten Eingabe enden.
Dann gelingt keine Rettung.

## Grenzen des Fahrberichts

`tracks/reports/06_stuntlabor.json` enthält die erfolgreichen Fahrten, Eingaben und Prüfsummen.
Eine Prüfsumme kennzeichnet die genauen Fahrdaten und die Fahrberechnung.
Eine Änderung dieser Daten macht den alten Bericht ungültig.
Der Modellstil gehört nicht zu den Fahrdaten.

Der Bericht verwendet denselben Start bei fünf Metern wie das Spiel.
Versuchskennungen ändern die bestätigten Fahrzustände nicht.

Die Werte für Mindesttempo und Höchsttempo steuern die Hilfe.
Der Bericht bestätigt einzelne Fahrzustände und vollständige Eingabefolgen.
Er beweist keinen sicheren Bereich für beliebige Richtungen, Resthilfen oder Eingaben.
Die Anzeige bestätigt ein Zieltempo nur bei einem passenden geprüften Zustand.
Für andere Zustände zeigt sie keinen erfundenen sicheren Bereich.

## Bildprüfung und Aufnahmen

Der Mitschnitt liegt in `docs/stuntlabor/fahrt.mp4`.
Er enthält die Gesamtfahrt, eine späte Kurveneingabe und eine stärkere gültige Landung.
Die normalen und stärkeren Landungen erreichten etwa 4,83 und 9,36 m/s normalen Aufprall.
Die geprüften Einzelbilder zeigen die Fahrbahn und das Auto ohne verdeckte Übergänge.
Die Looping-Prüfung umfasst sechs weitere Kameralagen.

Gerät: MacBook Pro mit Apple M4 Pro und 48 GB Arbeitsspeicher.
Darstellung: Godot 4.5.1, Metal, Forward+, 1280 × 800 Bildpunkte.
Die Aufnahme umfasst 578 Bilder.
Die mittlere Wartezeit als Median auf ein gezeichnetes Bild beträgt 0,878 ms.
95 Prozent dieser Wartezeiten liegen bei höchstens 1,248 ms.
Diese Zeiten enthalten die Ablaufsteuerung und schließen das Speichern der Bilder aus.
Sie sind keine Messung der dauerhaft erreichbaren Bildrate.
Die genauen Messwerte stehen in `docs/stuntlabor/bildzeiten.json`.

Die Prüfung umfasst keine Sprach- oder Komfortversuche mit Menschen.
Ein eigener Spielversuch muss Lautstärke, Kamerabewegung und das Gefühl der Rettung bewerten.
Die aktive lokale Landschaftsarbeit blieb erhalten.
Ihre beiden zusätzlichen Prüfungen bestanden getrennt von der Streckenprüfung.

## Starten und erneut prüfen

Öffne `Starten.command` aus diesem Arbeitsordner.
Wähle unter den Strecken „Stunt course“.
Wähle „Very easy“ oder „Easy“.
Starte die Fahrt wie bisher.

```sh
.tools/voice-env/bin/python tools/spatial/run_checks.py --output /private/tmp/stuntcar-spatial-checks
.tools/voice-env/bin/python -m unittest discover -s voice/tests
.tools/voice-env/bin/python tests/test_localization_catalog.py
```

Der Prüfläufer begrenzt kleine Tests auf 90 Sekunden.
Gesamtfahrten erhalten 600 Sekunden.
Er behandelt auch Godot-Fehlermeldungen mit erfolgreichem Prozessende als Fehler.
Er schreibt die alte Fahrtenmatrix unter `/private/tmp`.
Er überschreibt keinen vorhandenen Abnahmebericht.

Die Anleitung für spätere Modelle steht in `docs/blender-streckenmodelle.md`.

## Ergebnis der unabhängigen Prüfung

Die Prüfung fand keine kritischen Fehler.
Sie fand sechs Punkte mit Folgen für die Anzeige, den Modelltausch oder die Effekte.
Gezielte Gegenbeispiele zeigten diese Punkte vor der Korrektur.
Danach bestanden alle Gegenbeispiele.

- Ein Neustart erhält nun passende bestätigte Tempohinweise.
- Die Rettungsanzeige nennt das tatsächliche Zieltempo und endet mit der Hilfe.
- Der Modelltausch beachtet die Darstellungskennung `visual_id`.
- Eine Ersatzdarstellung erzeugt einen sichtbaren Hinweis.
- Ein Streckenwechsel entfernt die bisherigen Reifenspuren.
- Ein tatsächlicher Zusatzschub erzeugt genau einen Ton.

Die Prüfung umfasste keine fremden Landschaftsänderungen.
Die gesonderten Landschaftstests bestanden trotzdem.
Die frühere große Randbewegung gehörte nicht zum neuen Fahrmodell.
Das unveränderte alte Fahrmodell bestimmt weiterhin die vier bisherigen Strecken.

## Entscheidungen bei der Umsetzung

Die Tests verwendeten zuerst leere Schnittstellen, damit fachliche Fehler vor der Umsetzung sichtbar wurden.
Ein fehlendes Skript galt nicht als solcher Nachweis.
Fremde Dateien blieben erhalten und außerhalb der Commits.
Der Aufgabenhelfer erkannte die deutschen Überschriften nicht.
Ein örtliches Aufgabenprotokoll übernahm deshalb die Zuordnung.

Die Modellprüfung verwendet die tatsächlichen Dreiecke der gespeicherten Fahrfläche.
Die alten geneigten Flächen stimmen nicht überall mit einer ideal geglätteten Fläche überein.
Die Abweichungsgrenze bleibt bei zwei Zentimetern.
Ein falscher Flächenbezug würde eine erneute Modellprüfung erfordern.

Der Prüfläufer erlaubt zusätzliche Anfangszustände für Tempo und Strecke.
Dadurch kann er die verlangten Anfangstempi prüfen.
Diese Erweiterung verändert den normalen Spielstart nicht.

Ein alter Spannungstest erwartete noch eine große Randbewegung und einen zweiten notwendigen Tastendruck.
Diese Erwartungen passten nicht zum bereits vorhandenen unteren Hilfsmodell.
Der Test prüft jetzt eine sichere Kurvenfahrt mit einer Eingabe und weitere sichere Eingaben.
Er prüft die frühere große Randbewegung nicht mehr.
Das alte Fahrmodell blieb unverändert.

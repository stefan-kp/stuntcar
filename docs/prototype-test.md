# Prüfung des ersten Prototyps

Datum: 15. Oktober 2026. Aktualisiert nach Stefans Spieltest.

Gerät: Mac mit Apple M4 Pro. Godot: `4.5.1.stable.official.f62fdbde1`. Darstellung: „Compatibility“ über OpenGL und Metal.

## Ergebnisse

| Prüfung | Ergebnis |
|---|---|
| Projektimport | Erfolgreich, keine Fehler im Importprotokoll |
| Spielregeln und Fahrmodell | 27 Prüfungen, kein Fehler |
| Tasteneingaben über die Eingabeverarbeitung | 12 Prüfungen, kein Fehler |
| Randnähe und kurze Korrekturen | 13 Prüfungen, kein Fehler |
| Ganze Spielszene ohne Richtungseingabe | Auto fällt von der Straße und fährt danach ohne Menü erneut los |
| Ganze Spielszene mit drei Richtungseingaben | Auto erreicht das Ziel |
| 30 simulierte Bilder pro Sekunde | Ziel nach 27,433 Sekunden |
| 60 simulierte Bilder pro Sekunde | Ziel nach 27,433 Sekunden |
| 120 simulierte Bilder pro Sekunde | Ziel nach 27,433 Sekunden |
| Sichtprüfung im Spielfenster | Menü, Fahrt und Tastenbelegung geprüft |
| Startdatei für macOS | Ausführbar; Spielstart erfolgreich |

Die Szenenprüfung nutzt das echte Auto, die Fahrbahn und die Bodenkollision. Sie sendet die Richtung jeweils etwa 28 Meter vor der Kurve.

Die Fahrten bei verschiedenen Bildraten laufen ohne Fenster. Sie prüfen die feste Fahrzeugberechnung. Sie messen nicht die Grafikleistung des Geräts.

## Geprüfte Fälle

- Ohne Eingabe verlässt das Auto die erste Kurve.
- Eine falsche Richtung führt von der Strecke.
- Eine zu frühe Eingabe aktiviert keine spätere Kurve.
- Drei passende Eingaben führen durch die vollständige Strecke.
- Eine einzelne Eingabe gilt nicht für die nächste Kurve.
- Eine passende Eingabe 0,25 Sekunden nach Kurvenbeginn rettet jede der drei Kurven aus der geprüften Ausgangslage.
- Wiederholte Richtungseingaben unterbrechen die Fahrt nicht.
- Die Pause über Escape hält das sichtbare Auto und die Fahrzeit an.
- Ein erneuter Versuch fährt ohne Menü sofort mit vollem Tempo weiter.
- Die Fortsetzung sendet keinen zusätzlichen Lenkbefehl.
- Gehaltene Tasten und wiederholte Tastenereignisse lösen keine neue Richtung aus.
- Gleichzeitige Tastendrücke lösen keine Richtung aus.
- Der Fensterwechsel pausiert und verwirft wartende Eingaben.
- Doppelte Tastenbelegungen verändern die bisherige Belegung nicht.
- Eine unvollständige Tastenbelegung endet nach der Frist ohne Änderung.

## Die knappe Fahrlinie

Die Fahrzeugmitte erreicht in den weiten Kurven etwa 2,13 Meter Abstand von der Fahrbahnmitte. In der engen Kurve erreicht sie etwa 1,94 Meter. Die Fahrbahn reicht auf beiden Seiten drei Meter von der Mitte nach außen.

Die äußeren Räder erreichen dadurch fast den Rand. Ein weiterer passender Tastendruck verringert den seitlichen Abstand im Vergleich zur Fahrt ohne Korrektur. Die Prüfung bestätigt dies für alle drei Kurven.

Die Fahrzeugbewegung erzeugt diesen Abstand tatsächlich. Die Darstellung verschiebt das Auto nicht unabhängig von seiner Position. Nur die leichte Neigung der Karosserie bleibt ein sichtbarer Effekt.

## Frühere Codeprüfung und Korrektur

Ein unabhängiger Prüfer fand einen Fehler bei der Pause. Ein wartender Tastendruck konnte die Pause sofort beenden.

Der neue Test stellte diesen Fehler zuerst nach. Die Eingabeverarbeitung löscht nun wartende Richtungsbefehle vor der Pause durch Escape. Der Test besteht danach.

Die Tastenbelegung zeigt außerdem die verbleibende Frist. Sie erklärt den Abbruch ohne weitere Taste.

## Bilder

- `preview-menu.png`: Startmenü und Strecke.
- `preview-drive.png`: Fahrt vor der ersten Kurve.
- `preview-settings.png`: Neue Tastenbelegung mit sichtbarer Frist.
- `preview-edge.png`: Äußere Räder am Rand.
- `preview-correction.png`: Wirkung eines weiteren kurzen Tastendrucks.

Diese Bilder stammen aus Godots tatsächlichem Spielfenster.

## Grenzen der Prüfung

Die eingeschränkte Testumgebung meldet einen Zugriff auf die Systemzertifikate als Fehler. Die Prüfungen enden trotzdem erfolgreich. Die 52 Einzelprüfungen mit normalen lokalen Benutzerrechten zeigen diese Meldung nicht. Der normale Projektimport und das Spielfenster zeigen diese Meldung nicht. Die Sprachsteuerung nutzt eine Verbindung innerhalb des eigenen Rechners. Die Fahrt braucht keine Internetverbindung.

Die Sprachsteuerung ist ergänzt. Die zusätzlichen Ergebnisse stehen unten. Es gibt noch keinen Test unter Windows oder mit speziellen Eingabegeräten.

Es gibt noch keinen Spieltest mit Menschen aus der Zielgruppe. Wir müssen die Spannung, die Wirkung der Korrekturen und den passenden Hinweisvorlauf gemeinsam prüfen.

Der größere ursprüngliche Plan enthält weitere Prüffälle. Die Variante mit zwei direkt aufeinanderfolgenden Kurven gleicher Richtung fehlt noch. Rettungen bei 0,5 Sekunden Verzögerung und seitlichen Ausgangslagen brauchen weitere Vergleiche.

## Prüfung der Sprachsteuerung

Stand: 15. Oktober 2026. Vosk 0.3.44 und sounddevice 0.5.3. Kleine Modelle: Deutsch 0.15 und Englisch 0.15.

- Zehn Prüfungen bestätigen Richtung, wiederholte Korrekturen, Tempowahl, Tempogrenzen und vollständige Fahrten bei 50 und 101 km/h.
- Neun Prüfungen bestätigen die Verarbeitung der Nachrichten, doppelte Nummern, alte Zustandsnummern, fremde Kennungen und fehlerhafte Verbindungen.
- Fünf Prüfungen verbinden die Sprachbefehle mit der echten Spielszene. Sie prüfen auch alte Befehle nach einer Pause und Mikrofonfehler während eines Falls.
- Neun Python-Prüfungen prüfen die Wörter, unbekannte Sätze, wiederholte Wörter, Stille und alte Tonblöcke nach einer Pause.
- Der neue Test stellt einen Zustandswechsel während der Erkennung nach. Alte Tonblöcke lösen danach nichts aus. Neue Tonblöcke funktionieren weiterhin.
- 24 künstliche Sprachproben liefern das erwartete Ergebnis. Darunter sind drei Sätze, die keinen Befehl auslösen dürfen.
- Die Proben nutzen macOS-Stimmen. Sie enthalten keine menschlichen Aufnahmen. Die Dateien und erwarteten Ergebnisse liegen unter `voice/tests/audio`.
- Die echte Verbindung zwischen Godot, dem Hilfsprogramm und dem MacBook-Pro-Mikrofon meldet Bereitschaft und regelmäßige Lebenszeichen.
- Die sichtbare Anzeige bestätigt „Mikrofon aktiv“. Das Bild liegt unter `preview-voice.png`.

Die gemessene Berechnung der künstlichen Proben dauerte zuletzt etwa 8 bis 379 Millisekunden je Äußerung. Dazu kommt die kurze Sprechpause von etwa 300 Millisekunden. Diese Zahlen messen nicht die vollständige Verzögerung eines Menschen am Mikrofon.

Ein Test mit Stefans Stimme steht aus. Die künstlichen Proben belegen keine Erkennungsquote für unterschiedliche Menschen oder Hintergrundgeräusche. Die geplanten längeren Mikrofontests bleiben deshalb offen.


## Schnelle Wortfolgen und Zeitmessung

Stand: 15. Oktober 2026, nach Stefans Test der ersten Sprachsteuerung.

Die alte Erkennung lieferte für „links links links links links“ keinen Befehl. Der neue Test bestätigt fünf Befehle. Der erste Befehl kommt während der Wortfolge.

- 14 Python-Prüfungen bestehen. Sie enthalten die bisherigen 24 Sprachproben und sieben neue zusammenhängende Wortfolgen.
- Die neuen Wortfolgen enthalten wiederholte Richtungen auf Deutsch und Englisch sowie einen Richtungswechsel.
- Die Prüfung enthält fünf Wörter mit 280 Wörtern pro Minute und eine Folge mit 15 Wiederholungen.
- Zwei weitere Fälle überlagern die Sprache mit einem künstlichen Störton. Die Wiederholung nach einer Pause funktioniert. Nach einer unbekannten Äußerung funktioniert der nächste Richtungsbefehl.
- 81 Godot-Einzelprüfungen bestehen. Die vollständige Fahrt erreicht das Ziel nach 27,433 Sekunden.
- Das echte MacBook-Pro-Mikrofon meldet Bereitschaft. Die neue Erkennung liefert weiterhin Rückmeldungen an die Spielszene.
- `preview-voice-stream.png` zeigt die tatsächliche Anzeige während einer künstlichen Wortfolge.

### Verzögerung bis zum ausgeführten Befehl

Die Messung spielt künstliche Tonblöcke im ursprünglichen Zeitabstand ein. Danach nutzt sie dieselbe Erkennung und Verbindung wie das Mikrofon. Die echte Spielszene führt die Befehle aus. Der Test hält das Auto an derselben Kurve und unterdrückt die Pause durch einen Fensterwechsel.

Das Modell schätzt die Wortenden anhand der vollständigen Sprachprobe. Die Messung zieht diese Zeitpunkte vom Zeitpunkt der Befehlsausführung ab. Die Ergebnisse sind Näherungen. Die Messung enthält nicht die Verzögerung des echten Mikrofons oder eine Prüfung der sichtbaren Reaktionszeit durch einen Menschen.

| Probe | Ausgeführt | Zeit nach geschätztem Wortende |
|---|---:|---:|
| Fünfmal links, 200 Wörter pro Minute, sichtbares Spiel | 5 von 5 | 105–405 ms |
| Fünfmal rechts, 200 Wörter pro Minute | 5 von 5 | 351–764 ms |
| Fünfmal links, 280 Wörter pro Minute | 5 von 5 | 75–448 ms |

Der mittlere Wert der 15 Befehle beträgt 351 ms. Der höchste Wert beträgt 764 ms. Diese kleine Messreihe belegt keine allgemeine Erkennungsquote oder feste Höchstzeit. Zehn Millisekunden erreicht die Erkennung hier nicht.

Die Rohwerte stehen in `voice-latency.json`. Die Prüfung läuft mit `tests/measure_voice_latency.gd`. Das Hilfsprogramm `voice/tests/replay_microphone.py` ersetzt nur die Mikrofonquelle.

Ein Test mit Stefans Stimme und seinem tatsächlichen Sprechtempo bleibt erforderlich. Die sichtbare Rückmeldung unterstützt diesen Test. Allgemeine Umgebungsgeräusche und andere Mikrofone brauchen weitere Prüfungen.

## Gemeinsame Steuerung prüfen

Nutze die Anleitung unter `docs/control-integration.md`.
Prüfe beide Hilfestufen mit Links, Rechts, Gas und Bremse.
Prüfe eine ausdrückliche falsche Richtung vor einer Kurve.
Die Bewegung und die Bestätigung müssen diese Richtung erhalten.
Prüfe den kalibrierten Ruf auf Sehr leicht.
Prüfe Pause, Fortsetzung, Tastenfreigabe und den Verlust des Mikrofons.
Eine alte gehaltene Taste darf nach der Pause keine Aktion starten.
Eine neue Fahrt darf keine alte Anweisung übernehmen.
Erfasse die verwendete Godot-Fassung und das tatsächliche Ergebnis.
Eine automatische Paketprüfung ersetzt keine menschliche Sprachprobe.

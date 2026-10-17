# Astra Review des Steuerungskonzepts

Datum: 17. Oktober 2026

Gegenstand: [Entwurf der gemeinsamen Steuerung](../specs/2026-10-17-gemeinsame-steuerungsschnittstelle-design.md).

Modell: Astra im bestehenden Unteragenten `astra_control_review`.
Der Review änderte keine Spielsteuerung und keine Dateien des Spiels.

## Urteil

Astra bewertet den schrittweisen Umbau als sinnvoll, mit zwei notwendigen Korrekturen.
Die gemeinsame Schnittstelle und einfache Hinweise können vor der späteren Vorausberechnung entstehen.
Eine grundlegende Änderung der Richtung ist nicht mehr erforderlich.

## Befunde und Korrekturen

| Befund | Folge | Korrektur im Entwurf |
|---|---|---|
| Gehaltene Eingaben haben keine eindeutige Reihenfolge ihrer Änderungen. | Eine ältere Nachricht kann eine neuere Stärke überschreiben oder eine beendete Aktion verlängern. | `control_revision` ordnet die Nachrichten. Beendete und ersetzte Aktionen bleiben beendet. Ein neuer Beginn braucht eine neue Kennung. |
| Ein offener Simulationsausgang erhält keinen Wert, ein bekannter Absturz dagegen −0,9. | Die bekannte Absturzvariante kann als einzige bewertete Ergänzung gewinnen. | Ein berechneter Absturz begründet keine automatische Ergänzung und keine freie Rufauswahl. Ausdrückliche Befehle bleiben ausführbar. |
| Eine Aktion kann über das Abschnittsziel hinaus wirken. | Das Erreichen der Zwischenmarke kann eine fehlende Prüfung der Restwirkung verdecken. | Die Rechnung erfasst Restwirkungen. Eine Ergänzung braucht ein Ende am Ziel oder eine geprüfte Übergabe. Andernfalls bleibt die Bewertung offen. |

Astra prüfte anschließend die Korrekturen und ihre direkten Querverweise erneut.
Astra bestätigte die Behebung der ersten beiden Lücken.
Bei der dritten Korrektur verlangte Astra zusätzlich eine passende Definition von `open`.
Der Entwurf enthält nun ausdrücklich auch erreichte Ziele mit ungeprüfter Restwirkung als offenen Ausgang.
Er trennt dafür das tatsächliche Rechenende `stop_reason` vom Ergebnis für die Auswahl `outcome_status`.
Diese letzte Textkorrektur setzt Astras konkrete Forderung um. Sie erhielt keine weitere vollständige Reviewrunde.

## Bestätigte Grenzen

Der Entwurf unterscheidet feste Spielregeln, vorgegebene Hilfsziele und einzelne erfolgreiche Proben.
Er erklärt die vorhandenen Stunt-Hilfswerte nicht zu allgemeinen sicheren Geschwindigkeitsgrenzen.
Die vorhandenen Schilder und Richtungsdaten bieten eine brauchbare Grundlage für einfache Hinweise.

Die Bewertung anhand sicherer Korridore entfällt.
Die spätere Vorausberechnung verlangt vollständige Zustandskopien und eine Prüfung der Aktualität.
Sie darf keine benötigten zukünftigen Spielerbefehle erfinden.
Die Aussage der Versuchsergebnisse bleibt auf die geprüften Fälle begrenzt.

## Umfang des Reviews

Astra las den Entwurf, den Unterschied zum Stand `5a37796`, den relevanten Spielcode und die gespeicherten Ergebnisdaten.
Astra verglich die Ergebniszahlen und die Prüfsummen der bezeichneten Quelldateien.
Astra führte die Fahrversuche nicht erneut aus.
Astra prüfte die temporären Versuchsskripte und vollständigen Suchdaten nicht unabhängig.
Fahrkomfort, Sprache, menschliche Bedienbarkeit und die Leistung mit Darstellung gehören nicht zu diesem Review.

Der Review ist eine Prüfung des Entwurfs. Er ist keine Freigabe einer fertigen Spielsteuerung.

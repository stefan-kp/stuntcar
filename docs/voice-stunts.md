# Sprachsteuerung und Fahrgefühl

Die persönliche Kalibrierung bestimmt die drei Stärken für Tempobefehle.
Die Lautstärke verändert die Lenkhilfe bei „Sehr leicht“ und „Leicht“ nicht.
Die seitlichen Pfeile bestätigen das erkannte Richtungswort.

| Befehl | Ein Balken | Zwei Balken | Drei Balken |
| --- | --- | --- | --- |
| `left` / `right` | Gleiche Kurvenhilfe | Gleiche Kurvenhilfe | Gleiche Kurvenhilfe |
| `faster` / `fast` | Kleine Tempoerhöhung | Normale Tempoerhöhung | Tempoerhöhung und kurzer Turbo |
| `slower` | Kleine Temposenkung | Normale Temposenkung | Vollbremsung bis zum Stillstand |

Nach einer Vollbremsung fährt das Auto mit `faster` wieder an.
Dafür reicht ein leiser Befehl.
Ein Bremsbefehl beendet einen laufenden Turbo.
Der Turbo dauert 1,2 Sekunden.
Ein weiterer lauter Befehl verlängert ihn nicht.
Nach 2,8 Sekunden ab dem Start kann ein neuer Turbo beginnen.
Die normale Höchstgeschwindigkeit beträgt 46 Meter pro Sekunde.
Der Turbo erlaubt kurz bis zu 58 Meter pro Sekunde.

Die Vorderreifen und die Karosserie zeigen den Lenkeinschlag.
Bei schnellen Kurven dreht sich die Karosserie sichtbar zur Kurveninnenseite.
Die Vorderreifen lenken dabei sichtbar gegen den Drift.
Reifenrauch verstärkt den Eindruck des Rutschens.
Die vorhandene Kurvenhilfe und die tatsächliche Fahrspur bleiben erhalten.
Der sichtbare Drift beginnt oberhalb von 26 Metern pro Sekunde.

Der Turbo erzeugt Auspuffflammen und erweitert den Blickwinkel.
Die Karosserie hebt sich vorne etwas an.
Die Vollbremsung senkt die Karosserie vorne ab und erzeugt Reifenrauch.
In der Luft erzeugen die Reifen keinen Rauch.
Eine Vollbremsung in der Luft wirkt nach der Landung.
Dadurch bleibt das Auto nicht im Sprung stehen.

Eine Pause hält die Zeit des Turbos an und unterbricht die sichtbaren Effekte.
Ein Neustart löscht den Turbo, die Vollbremsung und den Drift.

Die Bilder zeigen die echte Godot-Szene mit künstlich eingegebenen Befehlen:

- [Turbo](stunt-boost.png)
- [Drift](stunt-drift.png)
- [Vollbremsung](stunt-brake.png)

## Die beiden Hilfestufen

„Sehr leicht“ gleicht eine falsche Richtung aus.
Ein leiser Ruf kann die Kurve ebenfalls freigeben.
Dafür nutzt das Spiel eine eigene Rufprobe.
Die Rufprobe verlangt zwei Sekunden Raumgeräusch und drei angenehm leise Laute mit Pausen.
Die Rufprobe verlangt keine laute Kalibrierung.

„Leicht“ verlangt die richtige Richtung.
Beide Stufen brauchen eine neue Eingabe vor jeder Kurve.
Eine angenommene Eingabe gilt bis zum gesicherten Kurvenausgang.
Die Hilfe führt den Ausgang noch 16 Meter.
Eine falsche Folgeeingabe entzieht die bestehende Freigabe nicht.

Die späte Hilfe senkt das Tempo kurzzeitig.
Die Anzeige nennt das tatsächliche Tempo, das Spielerziel und das Hilfsziel.
Vollgas in einer freigegebenen Kurve bleibt auf den bestehenden Strecken möglich.
„Sehr leicht“ ergänzt bei hohem Tempo einen kurzen Schlingerimpuls.
Der Impuls verändert die tatsächliche Spur innerhalb des sicheren Bereichs.
Der Impuls verlangt keine zusätzliche Lenkeingabe.

Die bestehenden Sprünge folgen weiterhin einer festen Bahn.
Die Streckendaten enthalten bereits Felder für Mindesttempo, Höchsttempo und Zieltempo.
Ungeprüfte Rampengrenzen stehen auf `null`.
Sie gelten nicht als geprüfte Sprunggeschwindigkeiten.

Die automatische Prüfung verwendet künstliche Eingaben.
Die Erprobung mit Menschen und echten Mikrofonen steht noch aus.

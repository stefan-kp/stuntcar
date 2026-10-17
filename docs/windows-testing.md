# Windows test

Stuntcar 0.0 - Windows preview

This package is a prototype for a Windows x64 test.
The automatic package tests do not replace your play test.

Start
1. Extract the complete ZIP file into a folder.
2. Keep Stuntcar.exe, Stuntcar.pck and the voice folder together.
3. Open Stuntcar.exe.
4. Select a track.
5. Select "Voice + keyboard" or "Keyboard".
6. Select "Start drive".

You do not need to install Godot or Python.
The game uses local English speech input.
The game does not send or save microphone audio.

Keyboard
- A/D or Left/Right: tap to turn.
- W or Up: hold to accelerate.
- S or Down: hold to brake, down to a stop.
- Release the speed key to keep the current target speed.
- Settings > Change keys: assign left, right, acceleration, and brake.

Voice test
1. Select your microphone in the Windows sound settings.
2. Allow desktop apps to use the microphone in the Windows privacy settings.
3. Open "Settings" and then "Voice practice" in the game.
4. Select "Calibrate voice".
5. Say "okay" at each requested level.
6. Complete the word test.

Say "left", "right", "faster" and "slower" during a drive.
A quiet word gives a small change.
A loud "faster" gives a short turbo boost.
A loud "slower" stops the car.
Say "faster" to move again.
The game saves your settings and voice levels for the next start.

Please check
- Does the game start after you extract the ZIP?
- Do all four tracks and their preview images appear?
- Do the car, trees, road, jumps, sound and menus work?
- Do W/S and the arrow keys change the speed?
- Can you brake to a stop and then accelerate again?
- Does Change keys save all four assigned keys?
- Does the game find your microphone?
- Does one spoken word give one command?
- Do the three voice levels give the same effect as the arrow bars?
- Does a second start keep your settings and voice levels?
- Does the game run when the folder name has spaces?

Please report
- The Windows version and the graphics card.
- The microphone name.
- The steps before a fault.
- The expected result and the actual result.
- The game log, if a fault occurs.

The log is normally in:
%APPDATA%\Godot\app_userdata\Stuntcar · Erste Fahrt\logs\godot.log

The package has no digital signature.
Windows can show a message about an unknown publisher.
If this occurs, report the message before you change any security setting.

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

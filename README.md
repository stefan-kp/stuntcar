# Stuntcar · First Drive

**A racing game you control with your voice. Version 0.0.**

Say `left`, `right`, `faster`, or `slower` to drive through banked curves and over jumps. Your voice level changes the force of each command. A quiet word makes a small correction. A loud `faster` gives a turbo boost, and a loud `slower` applies the full brake.

Stuntcar takes its inspiration from Stunt Car Racer. It is an early prototype, made as a side project. We hope it is already fun to play.

![A fast curve in Stuntcar](docs/stunt-drift.png)

## Play

| Platform | Download | Status |
| --- | --- | --- |
| Windows x64 | [Download the ZIP](https://github.com/stefan-kp/stuntcar/releases/download/v0.0.0-preview.2/stuntcar-windows.zip) | Untested on Windows |
| macOS | [Run the project](#run-the-project-on-a-mac) | We develop on Mac. A separate app download is planned. |

1. Download the Windows ZIP.
2. Extract the complete ZIP into a folder.
3. Open `Stuntcar.exe`.
4. Select a track.
5. Select “Voice + keyboard” or “Keyboard”.
6. Select “Start drive”.

Keep `Stuntcar.exe`, `Stuntcar.pck`, and the `voice` folder together. The package includes everything that voice input needs. You do not need to install Godot or Python.

Use a game ZIP from the [release page](https://github.com/stefan-kp/stuntcar/releases). The GitHub “Source code” ZIP contains the project files. It is not a ready-to-run game.

## Why voice control?

We want people who cannot use a controller because of physical limitations to have more computer games they can play. Voice control is our first step towards that goal. The game should also be fun for anyone who wants to try a different way to drive.

We looked at existing solutions such as VoiceAttack. For this project, we chose to build voice control into the game. The voice commands, the force of each command, and the help through curves form part of the game design.

The voice input runs locally with Vosk. The game does not save microphone audio or send it to an internet service. You can also use the keyboard to steer, accelerate, and brake.

## The game

Four tracks take you through a forest, a mountain pass, a canyon, and a wet coast. There are jumps, banked curves, and a drift effect in fast curves. There is no time limit. After a fall, the car starts again before the curve.

| Track | Length | Main features |
| --- | --- | --- |
| First Drive | 940 m | Forest, two large jumps, three banked curves |
| High Drive | 1,250 m | Mountain pass, five curves, one jump |
| Jump Track | 1,350 m | Canyon, five curves, two jumps |
| Coast Drive | 600 m | Wet coast, three curves, one hill |

Give one direction command before each curve. The system then helps the car turn through that curve. Another command in the same direction moves the car towards the inside of the curve. A late command gives less time for a correction. A command in the wrong direction turns the car in that direction.

The car jumps without a separate command. A direction command can help the car reach the centre of the track before it lands. The camera stays level with the horizon.

## Controls

The menus and voice commands use English. Keyboard control also works with voice control. Tap a direction key to turn. Hold the acceleration or brake key to change speed. The car keeps its target speed after you release the key.

| Action | Key | Voice command |
| --- | --- | --- |
| Turn left | A or ← | `left` |
| Turn right | D or → | `right` |
| Increase speed | W or ↑ | `faster` or `fast` |
| Brake | S or ↓ | `slower` |
| Pause | Escape | `pause` in “Two checks” mode |
| Resume | D in the pause menu | `resume` or `continue` |
| Select the next menu item | A | `next` |
| Open a menu item | D | `select` |
| Start from the start menu | Select “Start drive” | `start` |

These are the default keys. Use “Settings → Change keys” to assign all four controls. The game saves the new keys after all four assignments. A custom assignment takes priority over an arrow key.

One spoken word is sufficient for a command. You can say `left left left` to make three corrections. The default mode uses one recognizer. The optional “Two checks” mode checks the same speech twice. It does not need a second spoken word.

The arrows show the direction and force of your command. The upper arrow increases speed. The lower arrow applies the brake.

| Bars | Turn | `faster` | `slower` |
| --- | --- | --- | --- |
| 1 | Small correction | Small speed increase | Small speed decrease |
| 2 | Normal correction | Normal speed increase | Normal speed decrease |
| 3 | Large correction | Short turbo boost | Full brake to a stop |

Say `faster` to move again after a full brake. A quiet command is sufficient. A brake command stops an active turbo boost.

## Set your voice levels

1. Open “Settings”.
2. Open “Voice practice”.
3. Select “Calibrate voice”.
4. Say `okay` with your normal voice.
5. Say `okay` more loudly at the next step.
6. Say `okay` very loudly at the last step.
7. Complete the word test that follows.

The display tells you when to speak again. The word test asks for `left`, `right`, `faster`, and `slower`. It shows how many commands the game recognized.

During a drive, a loud call can help if the game recognizes no command.
The game uses your microphone profile to check the volume.
At the end of the call, it applies the direction for the current or next curve if the time is correct.
Each call gives at most one command. The display shows `Voice help`.
This help stays off in menus and during the voice exercise.

The game saves your voice levels, keys, control mode, track, and sound levels. You do not need to set your voice levels after each start. Check the levels again if you change your microphone or its settings.

Allow desktop apps to use the microphone in the Windows privacy settings. On a Mac, allow microphone access when macOS asks for it. Background noise and the distance from the microphone can change the result.

## How we made it

Stuntcar is fully “vibe-coded”: we describe what we want, and AI agents write the code. We play the result and work with the agents to improve it. The game uses Godot 4.5.1 and free models, images, and sounds.

A project this small would probably not have covered the cost of traditional development. Tools with AI agents now let us make a game that we could not otherwise have made.

## What comes next

We want to improve the controls, add more tracks and loops, and offer a separate Mac app. We also plan to add gesture control as another way to play. These features are not yet available.

This is version 0.0. Try it, tell us what works, and help us make it more fun and easier to play.

## Thanks to the asset creators

This game would not exist without people who share their models, images, and sounds. Thank you to all the creators, including those who use CC0 and do not require a credit.

| Part | Creators | Source and license details |
| --- | --- | --- |
| Car Concept | Eric Chadwick and Darmstadt Graphics Group; original design by Unity Fan | [Car and surfaces](assets/quality/README.md), CC BY 4.0 |
| Trees, plants, rocks, ground, road, and sky | Poly Haven and the creators named in the source lists | [Base assets](assets/quality/README.md), [forest assets](assets/forest/README.md), CC0 |
| Engine sound | qubodup | [Audio credits](assets/audio/CREDITS.txt), CC BY 3.0 |
| Forest, wind, and impact sounds | ktokrzysiek, SketchMan3, JaggedStone, and Kenney | [Audio sources](assets/audio/README.md), CC0 |

The sources are free of charge. They use different licenses. The source lists give the creator names, source links, and our changes. The game packages include the credits and license files.

We also thank the people behind [Godot](https://godotengine.org/), [Vosk](https://alphacephei.com/vosk/), and [sounddevice](https://python-sounddevice.readthedocs.io/). The [small English Vosk model 0.15](https://alphacephei.com/vosk/models) uses Apache 2.0.

## Run the project on a Mac

A project copy needs Godot 4.5.1. Voice input also needs Python 3.11 or later for the first setup.

1. Open `project.godot` with Godot 4.5.1.
2. Open `tools/macos/Sprache einrichten.command` to set up voice input.
3. Run the project from Godot with F5.

The first voice setup needs an internet connection. After setup, the game works without an internet connection.

`Starten.command` starts the game when Godot is in `.tools/Godot.app` or `/Applications/Godot.app`. The files under `.tools` are local tools. Git does not include them. The [Mac tools guide](tools/macos/README.md) describes the other tools.

## Development

We develop the game on a Mac and build the Windows package with GitHub Actions. The project uses Godot 4.5.1 and the Forward+ graphics mode. The English interface text is in `locales/en.po`.

- [Add an interface language](locales/README.md).
- [Add a track](tracks/README.md).
- [Build the Windows package](tools/release/README.md).

Some detailed project notes are still in German.

Use these checks from the project folder on a Mac:

```sh
.tools/voice-env/bin/python -m unittest discover -s voice/tests
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/run_tests.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/run_voice_runtime_tests.gd
```

## License

The game code uses the [Apache License 2.0](LICENSE). The models, images, sounds, and libraries keep their own licenses. See the source lists above for those licenses.

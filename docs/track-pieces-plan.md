# Tracks from parametric pieces

Status: steps 1 to 3 done. Decided with Stefan on 20 October 2026.

Every track becomes a chain of pieces with parameters, such as "curve left, 90°, radius 30 m, bank 25°".
A generator turns the pieces into the drive form, the collision surface and the road mesh.
The game keeps one track format, one drive model and one curve assist.
The reference is Stunt Car Racer: an elevated road on pillars, hills, bumps, ramps with gaps, banked curves and loops.

## Decisions

- Every track is a closed circuit. The last piece must end exactly at the start.
- There is no branch piece.
- The five format 1 tracks and the fixed format 2 forms go away. New tracks replace them. Nothing has to stay compatible.
- Everything in the repository is written in English.

## Pieces

All pieces are 6 m wide and start and end level.

| Type | Parameters (limits) | Input | Status |
| --- | --- | --- | --- |
| `straight` | `length_m` 8–200, `rise_m` with at most 15° slope | none | Step 1 |
| `curve` | `direction` left/right, `angle_deg` 15–180, `radius_m` 20–80, `bank_deg` 0–45 | direction | Step 1 |
| `hill` | `length_m` 20–80, `height_m` −10 to +10 (not near 0), at most 30° slope | none | Step 1 |
| `bank` (wall curve) | `direction`, `angle_deg` 60–180, `radius_m` 15–30, `bank_deg` 30–90 | direction | Step 3 |
| `bumps` | `length_m` 20–120, `count` 2–12, `height_m` 0.2–1.5, at most 20° slope | none | Step 3 |
| `ramp` | `gap_m` 10–50, `takeoff_deg` 5–25, `height_m` −8 to +4, landing ramp at most 35° | none | Step 3 |
| `loop` | `radius_m` 8–16, `offset_m` 6–10, `side` left/right (default right) | none | Step 3 |

A straight rises along a half cosine, so both ends stay level.
A hill goes up and back down along a full cosine. A negative height makes a dip.
A curve is a flat circular arc. Its bank follows sin² over the arc, so it is zero at both ends. A wall curve is the same arc with a bank up to 90°.
Bumps are a row of full cosine waves. Above a certain speed the car lifts off at each crest and lands on the next slope.
A loop is a vertical circle whose road moves sideways by the offset (smoothstep), so the exit passes beside the entry.

A ramp is a parabolic take-off ramp of 18 m, a gap and a parabolic landing ramp. The landing ramp is 18 m long, or three quarters of the gap if that is more. `height_m` is the level of the road after the jump against the level before it.
The landing ramp starts at the angle of the flight path that just reaches it. The design speed carries the car a third of the way down the landing ramp; the builder makes it the jump's speed window (±0.5 m/s).
A loop gets the tested window of the 12 m loop (24–32 m/s, target 26), scaled with the square root of its radius.

## Closing a circuit

Two straights may have `"length_m": "fit"`. The builder then chooses both lengths so the circuit closes. The two straights must not be parallel, and each fitted length must stay within the limits of a straight.
One straight may have `"rise_m": "fit"`. It takes the rise that brings the road back to the start height.

`tools/spatial/inspect_track.gd` prints a design report for a track: the elements, places where the road comes close to itself, the speed windows of the stunts and test laps. One lap calls every curve at once, one calls 1.5 s after the hint, as a voice player does, and one does so at 30 m/s.

## Curve calls

A call for the open curve counts while the car is in the air. The car steers when it is back on the road.
A curve called in time is settled when the car enters it. The hint for the next curve can then open while the car is still in the first one, so an S-bend needs no long straight between its curves. A late call keeps the curve until the car has left it.

## Grip

No assist level holds the car on the road. The car leaves the road wherever the road falls away faster than gravity pulls the car down: over a crest, at the entry of a dip and at the top of a loop that is driven too slowly. A 12 m loop needs about 10.5 m/s.
On a bank steeper than 45° the tyres hold a side force of at most the force that presses the car onto the road. A car that is too slow slides down the wall and off the road. The builder gives such a wall curve a minimum speed 3 m/s above that limit.
The assist brings the car to the speed window of the next stunt on its own, in both levels, for as long as the help time of the level lasts.

## Flights

The road is solid for a car in flight. It can land on any element. After a lift-off from a crest or a bump the landing may be at most 10 m/s hard and 30° off; a jump keeps its own limits (12 m/s, 20°).
A harder or skewed landing, or a hit from below, wrecks the car where it hits. A wreck stays on the road; a car that leaves the road sideways falls until it meets a road or the ground.
A car that comes to a stop on a road steeper than about 45° is wrecked. Overhead, in a loop, it drops off and falls onto whatever is below.

## Format 3

```json
{
  "format_version": 3,
  "name": "I18N_TRACK_EXAMPLE_NAME",
  "description": "I18N_TRACK_EXAMPLE_DESCRIPTION",
  "scenario": "canyon",
  "start": {"height_m": 12},
  "pieces": [
    {"type": "straight", "length_m": 60},
    {"type": "hill", "length_m": 40, "height_m": 3},
    {"type": "straight", "length_m": 60},
    {"type": "curve", "direction": "right", "angle_deg": 90, "radius_m": 30, "bank_deg": 25}
  ]
}
```

A piece may set `id` and `assist`. Without `id`, the builder uses `e0`, `e1` and so on.
The builder chains the pieces and stops with an error that names the piece index and field.
An open circuit reports how far the end is from the start.

## Code

| File | Job |
| --- | --- |
| `scripts/track/pieces/piece_generator.gd` | Checks the limits of one piece and builds its form: centre points, up vectors, entry and exit pose |
| `scripts/track/pieces/circuit_builder.gd` | Chains the pieces, checks that the circuit closes, and creates a `SpatialTrack` |
| `scripts/track/visuals/road_mesh.gd` | Builds the visible road and the pillars from the drive form; the drive form alone decides contact |
| `tools/spatial/speed_windows.gd` | Finds, per assist level, the held speeds at which the car gets across each element with a speed window; `check_drives.gd` writes them into the drive report |
| `tests/pieces/test_pieces.gd` | Rebuilds the fixed forms (including loop and jump) from parameters, checks the limits and the circuit, drives one lap in both assist levels, and checks the Stunt Circuit and the Stunt Park with their reports, speed windows and road |

The forms use the layout of `tracks/forms/stunt_v1.json`, so `SpatialTrack`, the surface and flight motion and the curve assist work unchanged.

## Steps

Each step is one pull request and keeps the game playable.

1. **Straight, curve and hill from parameters.** Done. The parameters rebuild `straight_24`, `curve_left_45`, `curve_right_45`, `hill_32` and both `bank_*_90` forms within 2 mm.
2. **Procedural road with pillars.** Done. `scripts/track/visuals/road_mesh.gd` sweeps the deck, edge lines and red barriers along the drive form and puts a pillar under the road every 12 m. The first format 3 track, `tracks/08_stunt_circuit.json`, is in the menu.
3. **Ramp, bumps, loop and wall curve.** Done. The parameters also rebuild `loop_12`, `jump_launch` and `jump_landing`. A flight can land on any following piece. `tools/spatial/speed_windows.gd` computes the speed windows, and the drive report lists them. `tracks/09_stunt_park.json` uses all four new pieces.
4. **One curve assist and the landscapes.** The two assist levels run on the spatial model only. Forest, alpine, canyon and coast use the new centre line. The drive matrix runs on format 3. Curves pass their real radius to the assist instead of the fixed 28 m in `spatial_track.gd`.
5. **New tracks, old formats removed.** The eight long circuits `10_first_hop.json` to `17_switchback.json` are done: 1.2 to 2.5 km, each built around one kind of stunt, from one small jump to a lap of hills and dips. Format 1, the fixed format 2 forms and their tests still have to go.

## Open questions

- Do we count laps and measure a time?
- Is 1.5 s at top speed enough distance between two pieces with an input?
- Do we need a third level in which the player sets every speed alone, or do we stay with two levels?

"""Run the real Godot tests with bounded processes and separate logs."""
import argparse
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', default='/private/tmp/stuntcar-spatial-checks')
    parser.add_argument('--godot', default=str(ROOT / '.tools/Godot.app/Contents/MacOS/Godot'))
    parser.add_argument('tests', nargs='*')
    args = parser.parse_args()
    output = pathlib.Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
    tracked = subprocess.check_output(['git', 'ls-files', 'tests/run_*tests.gd'], cwd=ROOT, text=True).splitlines()
    tests = args.tests or sorted(set(tracked + ['tests/run_scene_test.gd'] + [str(p.relative_to(ROOT)) for p in (ROOT / 'tests/spatial').glob('test_*.gd') if p.name != 'test_base.gd']))
    results = []
    for test in tests:
        name = test.replace('/', '-')
        limit = 600 if 'full_drives' in test or 'lower_assist_tracks' in test else 90
        command = [args.godot, '--headless', '--log-file', str(output / (name + '.engine.log')), '--path', str(ROOT), '--script', test]
        if 'lower_assist_tracks' in test:
            command += ['--', '--output', str(output / 'legacy-matrix.json')]
        try:
            run = subprocess.run(command, cwd=ROOT, text=True, capture_output=True, timeout=limit)
            text = run.stdout + run.stderr
            ok = run.returncode == 0 and not any(token in text for token in ['SCRIPT ERROR', 'ERROR:', 'Parse Error'])
        except subprocess.TimeoutExpired as error:
            text = str(error)
            ok = False
        (output / (name + '.log')).write_text(text)
        results.append({'test': test, 'passed': ok, 'timeout_s': limit})
        print(('PASS ' if ok else 'FAIL ') + test, flush=True)
        if not ok:
            print(text[-1600:], flush=True)
    (output / 'results.json').write_text(json.dumps(results, indent=2) + '\n')
    return 0 if all(result['passed'] for result in results) else 1


if __name__ == '__main__':
    sys.exit(main())

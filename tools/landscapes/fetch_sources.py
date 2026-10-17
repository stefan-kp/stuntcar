"""Fetch the CC0 landscape sources from Poly Haven and verify each file."""
import concurrent.futures
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'assets/landscapes'
MODELS = ['namaqualand_boulder_02', 'namaqualand_boulder_03', 'quiver_tree_01', 'shrub_02', 'rock_07']
SURFACES = {'sand_01': 'sand', 'snow_02': 'snow'}
SKY = 'kloofendal_48d_partly_cloudy_puresky'
HEADERS = 'StuntcarAssetPreview/1.0 (local Godot evaluation)'


def fetch(url, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['curl', '-fsSL', '--retry', '3', '--max-time', '180', '-A', HEADERS, url, '-o', str(path)], check=True)


def download(job):
    target, entry = job
    if not target.exists() or hashlib.md5(target.read_bytes()).hexdigest() != entry['md5']:
        temporary = target.with_suffix(target.suffix + '.part')
        fetch(entry['url'], temporary)
        if hashlib.md5(temporary.read_bytes()).hexdigest() != entry['md5']:
            raise ValueError('Checksum mismatch: ' + str(target))
        temporary.replace(target)
    print(target.relative_to(ROOT), flush=True)
    return {'path': str(target.relative_to(ROOT)), 'url': entry['url'],
            'bytes': target.stat().st_size, 'md5': entry['md5'], 'license': 'CC0-1.0'}


def main():
    jobs = []
    for name in MODELS + list(SURFACES) + [SKY]:
        info = DEST / (name + '-source.json')
        files = ROOT / '.tools/landscape-sources' / (name + '-files.json')
        fetch('https://api.polyhaven.com/info/' + name, info)
        fetch('https://api.polyhaven.com/files/' + name, files)
        data = json.loads(files.read_text())
        if name in MODELS:
            folder = DEST / name
            entry = data['gltf']['1k']['gltf']
            jobs.append((folder / (name + '.gltf'), entry))
            for path, included in entry['include'].items():
                target = (folder / path).resolve()
                if not target.is_relative_to(folder.resolve()):
                    raise ValueError('Unexpected source path')
                jobs.append((target, included))
        elif name == SKY:
            jobs.append((DEST / 'sky/environment.hdr', data['hdri']['2k']['hdr']))
        else:
            for key, filename in [('Diffuse', 'color'), ('nor_gl', 'normal'), ('Rough', 'rough')]:
                jobs.append((DEST / SURFACES[name] / (filename + '.jpg'), data[key]['2k']['jpg']))
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        records = list(pool.map(download, jobs))
    (DEST / 'manifest.json').write_text(json.dumps(records, indent=2) + '\n')


if __name__ == '__main__':
    main()

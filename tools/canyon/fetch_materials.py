"""Fetch the selected CC0 canyon materials from the Poly Haven API."""
import concurrent.futures
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/landscapes/canyon'

def fetch(url, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['curl', '-fsSL', '--retry', '2', '--max-time', '180',
                    '-A', 'StuntcarCanyon/1.0', url, '-o', str(path)], check=True)

def download(job):
    path, record = job
    temporary = path.with_suffix(path.suffix + '.part')
    fetch(record['url'], temporary)
    if hashlib.md5(temporary.read_bytes()).hexdigest() != record['md5']:
        raise ValueError('Checksum mismatch: ' + str(path))
    temporary.replace(path)
    return {'path': str(path.relative_to(ROOT)), 'url': record['url'],
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'bytes': path.stat().st_size}

def main():
    for asset, folder, resolution in [('rock_face_03', 'textures', '4k'),
                                       ('sandy_gravel_02', 'gravel', '4k'),
                                       ('rogland_sunset', 'sky', '2k')]:
        target = OUT / folder
        source = target / 'source.json'
        files = ROOT / '.tools/canyon-downloads' / (asset + '.json')
        fetch('https://api.polyhaven.com/info/' + asset, source)
        info = json.loads(source.read_text())
        fetch('https://api.polyhaven.com/files/' + asset, files)
        data = json.loads(files.read_text())
        if folder == 'sky':
            jobs = [(target / 'environment.hdr', data['hdri'][resolution]['hdr'])]
        else:
            jobs = [(target / (key + '.jpg'), data[key][resolution]['jpg'])
                    for key in ['Diffuse', 'Rough', 'Displacement', 'nor_gl']]
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            records = list(pool.map(download, jobs))
        source.write_text(json.dumps({'id': asset, 'url': 'https://polyhaven.com/a/' + asset,
                                     'authors': info.get('authors', {}), 'license': 'CC0-1.0',
                                     'resolution': resolution, 'files': records}, indent=2) + '\n')
        print(asset, resolution, sum(item['bytes'] for item in records), flush=True)

if __name__ == '__main__':
    main()

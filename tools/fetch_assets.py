"""Download original CC0 Kenney models. Fail closed on missing assets."""
from pathlib import Path, PurePosixPath
import io, json, hashlib, urllib.request, zipfile, sys, re, os
ROOT=Path(__file__).resolve().parents[1]
URL='https://kenney.nl/media/pages/assets/marble-kit/56fd69e5ed-1716385090/kenney_marble-kit.zip'
MIRROR='https://opengameart.org/sites/default/files/kenney_marble-kit.zip'
if len(sys.argv)>1:
    data=Path(sys.argv[1]).read_bytes()
    source='local archive'
else:
    for url in (URL,MIRROR):
        try:
            with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=90) as r:
                data=r.read(30_000_000)
            if not zipfile.is_zipfile(io.BytesIO(data)): raise ValueError('not ZIP')
            source=url
            break
        except Exception as e: print(url,e)
    else: raise SystemExit('Cannot fetch licensed asset pack')
z=zipfile.ZipFile(io.BytesIO(data))
files=[n for n in z.namelist() if not n.endswith('/') and not n.startswith('__MACOSX/')]
models=[n for n in files if Path(n).suffix.lower() in ('.glb','.gltf')]
def stem(n): return re.sub(r'[^a-z0-9]+','-',Path(n).stem.lower()).strip('-')
def pick(names, pattern=None):
    for name in names:
        matches=[n for n in models if stem(n)==name]
        if matches: return sorted(matches,key=lambda n: (not n.endswith('.glb'),n))[0]
    if pattern:
        matches=[n for n in models if re.fullmatch(pattern,stem(n))]
        if matches: return sorted(matches)[0]
    raise SystemExit(f'Missing asset {names}; available: {[stem(n) for n in models]}')
selected={'track':pick(['straight-wide','straight']), 'ball':pick(['marble','marble-blue','marble-basic','ball'],r'(marble|ball)(-[a-z0-9]+)?'), 'tree':pick(['tree','tree-large']), 'marker':pick(['banner','banner-blue','banner-red','flag'],r'(banner|flag).*'), 'support':pick(['support-single-top','support-single-bottom'])}
out=ROOT/'assets'/'kenney'; out.mkdir(parents=True,exist_ok=True)
base=os.path.commonpath([str(PurePosixPath(n).parent) for n in selected.values()])
base='' if base=='.' else base
for n in files:
    p=PurePosixPath(n)
    if p.is_absolute() or '..' in p.parts: raise SystemExit('Unsafe ZIP path')
    if base and not n.startswith(base+'/'): continue
    if p.suffix.lower() not in ('.glb','.gltf','.bin','.png','.jpg','.jpeg','.webp','.ktx2','.txt','.md'): continue
    dest=out.joinpath(*p.parts); dest.parent.mkdir(parents=True,exist_ok=True); dest.write_bytes(z.read(n))
(ROOT/'assets'/'manifest.json').write_text(json.dumps({k:'res://assets/kenney/'+v for k,v in selected.items()},indent=2))
(ROOT/'assets'/'source.json').write_text(json.dumps({'author':'Kenney','license':'CC0-1.0','source':source,'archive_sha256':hashlib.sha256(data).hexdigest(),'selected':selected},indent=2))
print(selected)

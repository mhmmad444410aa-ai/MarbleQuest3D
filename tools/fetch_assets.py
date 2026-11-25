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


# Download only publisher-distributed CC0 packs and extract selected models plus
# their declared glTF dependencies. Do not copy premium/source editions.
def fetch_zip(urls, cap=160_000_000):
    for url in urls:
        try:
            with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=120) as r:
                blob=r.read(cap+1)
            if len(blob)>cap or not zipfile.is_zipfile(io.BytesIO(blob)):
                raise ValueError('invalid or oversized archive')
            return blob,url
        except Exception as exc:
            print('Download attempt:',url,exc,flush=True)
    raise SystemExit('Unable to download required free environment pack')

import struct, posixpath, urllib.parse
def token(name):
    return re.sub(r'[^a-z0-9]','',Path(name).stem.lower())

def extract_pack(pack, urls, choices):
    blob, source_url=fetch_zip(urls)
    archive=zipfile.ZipFile(io.BytesIO(blob))
    names=set(archive.namelist())
    for n in names:
        path=PurePosixPath(n)
        if path.is_absolute() or '..' in path.parts:
            raise SystemExit('Unsafe archive member')
    candidates=sorted((n for n in names if Path(n).suffix.lower() in ('.glb','.gltf') and not n.startswith('__MACOSX/')),key=lambda n:(not n.lower().endswith('.glb'),len(n),n))
    used=set()
    selected={}
    for role, exact, patterns in choices:
        found=None
        for name in exact:
            matches=[n for n in candidates if token(n)==name and n not in used]
            if matches:
                found=matches[0]; break
        if found is None:
            for pattern in patterns:
                matches=[n for n in candidates if re.fullmatch(pattern,token(n)) and n not in used]
                if matches:
                    found=matches[0]; break
        if not found:
            raise SystemExit(f'{pack}: missing {role}; models: {[token(n) for n in candidates]}')
        selected[role]=found
        used.add(found)
    target=ROOT/'assets'/'environment'/pack
    def save_member(n):
        dest=target.joinpath(*PurePosixPath(n).parts)
        dest.parent.mkdir(parents=True,exist_ok=True)
        dest.write_bytes(archive.read(n))
    for role,n in selected.items():
        save_member(n)
        raw=archive.read(n)
        if n.lower().endswith('.glb'):
            if raw[:4]!=b'glTF': raise SystemExit('Invalid GLB')
            size,kind=struct.unpack_from('<II',raw,12)
            if kind!=0x4E4F534A: raise SystemExit('Invalid GLB JSON chunk')
            doc=json.loads(raw[20:20+size])
        else:
            doc=json.loads(raw)
        for entry in doc.get('images',[])+doc.get('buffers',[]):
            uri=entry.get('uri','')
            if not uri or uri.startswith('data:'): continue
            if urllib.parse.urlparse(uri).scheme or uri.startswith('/'):
                raise SystemExit('External dependency rejected')
            relative=posixpath.normpath(posixpath.join(posixpath.dirname(n),urllib.parse.unquote(uri)))
            if relative.startswith('../') or relative not in names:
                raise SystemExit(f'Missing dependency: {relative}')
            save_member(relative)
    for n in sorted(names):
        if re.match(r'^(license|licence|readme|credits)',Path(n).stem,re.I) and Path(n).suffix.lower() in ('.txt','.md'):
            save_member(n)
    return ({k:'res://assets/environment/'+pack+'/'+v for k,v in selected.items()}, {'source':source_url,'license':'CC0-1.0','archive_sha256':hashlib.sha256(blob).hexdigest(),'selected':selected})

nature, nature_source=extract_pack('kenney-nature',[
    'https://kenney.nl/media/pages/assets/nature-kit/37ac38a37b-1677698939/kenney_nature-kit.zip'
],[
    ('cliff',['cliffrock','cliffblockrock','cliff'],[r'cliff(?:block)?rock[a-z0-9]*']),
    ('waterfall',['cliffwaterfallrock','cliffwaterfall'],[r'cliff.*waterfall.*',r'waterfall.*']),
    ('rock',['rocklargea','rocklargeb'],[r'rocklarge[a-z0-9]*']),
    ('bridge_wood',['bridgecenter','bridgecenterwood','bridgewood'],[r'bridgecenter[a-z0-9]*',r'bridge.*wood.*']),
    ('grass',['grass','grasstall','plantflattall'],[r'grass[a-z0-9]*']),
    ('flower',['flowerpurplea','floweryellowa','flowerreda'],[r'flower[a-z0-9]*']),
])
forest, forest_source=extract_pack('quaternius-nature',[
    'https://store.godotengine.org/asset/quaternius/stylized-nature-megakit/download/31/',
    'https://opengameart.org/sites/default/files/stylized_nature_megakitstandard.zip'
],[
    ('forest_tree',['commontree1','commontree2','tree1'],[r'common.*tree.*',r'.*tree.*']),
    ('forest_tree_alt',['commontree2','commontree4','pinetree1','tree2'],[r'common.*tree.*',r'.*tree.*']),
    ('forest_bush',['bushcommon','commonbush','bush1'],[r'.*bush.*']),
])
manifest_path=ROOT/'assets'/'manifest.json'
manifest=json.loads(manifest_path.read_text())
manifest.update(nature)
manifest.update(forest)
manifest_path.write_text(json.dumps(manifest,indent=2))
source_path=ROOT/'assets'/'source.json'
metadata=json.loads(source_path.read_text())
metadata['additional_packs']={'Kenney Nature Kit':nature_source,'Quaternius Stylized Nature MegaKit Standard':forest_source}
source_path.write_text(json.dumps(metadata,indent=2))
print('Environment selected:',nature,forest,flush=True)

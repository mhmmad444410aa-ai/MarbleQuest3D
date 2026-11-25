"""Original deterministic high-resolution game textures; stdlib only, no downloads."""
import math
import struct
import zlib
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "assets" / "material_art"
OUT.mkdir(parents=True, exist_ok=True)
TAU = math.tau
def chunk(name, data):
    return struct.pack(">I", len(data)) + name + data + struct.pack(">I", zlib.crc32(name + data) & 0xffffffff)
def png(name, w, h, channels, data):
    stride = w * channels
    raw = b"".join(b"\x00" + data[y*stride:(y+1)*stride] for y in range(h))
    (OUT / (name + ".png")).write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB",w,h,8,2 if channels==3 else 6,0,0,0)) + chunk(b"IDAT",zlib.compress(raw,6)) + chunk(b"IEND",b""))
def rgb(h):
    return tuple(bytes.fromhex(h))
def clamp(x):
    return max(0,min(255,int(x)))
palettes = [
    ("073f3f","43a39b","b7e9d4"), ("563415","c79130","fff0a3"),
    ("33224d","9d68c4","e4c6fb"), ("536b91","b0d4ec","f7ffff"),
    ("591124","c23149","ffd1be"), ("132c68","397ad1","b7f0ff"),
    ("07432d","159c62","c9f9aa"), ("151923","4a5269","c9d0d8"),
    ("294f76","8cdbe8","f1fcff"), ("542618","b96939","ffdab0"),
    ("726353","d5c5b3","fff8ec"), ("1a164d","6555be","94d7ff")
]
# Bake periodic spherical marble veins: longitude wraps seamlessly and the poles converge.
W,H=2048,1024
# Reuse the expensive spherical field across all materials; each finish has distinct colour and vein response.
field=bytearray(W*H)
coslon=[math.cos(TAU*x/W) for x in range(W)]
sinlon=[math.sin(TAU*x/W) for x in range(W)]
for y in range(H):
    lat=math.pi*(y+.5)/H
    r=math.sin(lat); z=math.cos(lat)
    for x in range(W):
        a=r*coslon[x]; b=r*sinlon[x]
        warp=math.sin(5*a+4*z)*.85+math.sin(8*b-3*a)*.36+math.sin(15*z+6*b)*.15
        v=math.sin(11*b+4*a+7*z+4*warp)
        v2=math.sin(23*a-15*z+5*b+warp*3)
        field[y*W+x]=clamp(128+92*v+23*v2)
for i,(dark,mid,light) in enumerate(palettes):
    d,m,l=map(rgb,(dark,mid,light))
    lut=[]
    for n in range(256):
        t=n/255
        vein=max(0,(t-(.73+(i%3)*.035))/(.27-(i%3)*.035))**1.7
        base=t**(.65+(i%4)*.16)
        lut.append(bytes(clamp((d[k]+(m[k]-d[k])*base)*(1-vein)+l[k]*vein) for k in range(3)))
    png("marble_%02d"%i,W,H,3,b"".join(lut[n] for n in field))
    print("Material marble",i,flush=True)
# Tileable weathered stone relief; mortar, warm grey slate and fine texture.
N=2048
stone=bytearray(); normal=bytearray()
def height(x,y):
    u=(x%N)/N;v=(y%N)/N
    row=int(v*4)
    a=(u*4+(row%2)*.5)%1; b=(v*4)%1
    edge=min(a,1-a,b,1-b)
    bevel=min(1,edge*45)
    waves=.08*math.sin(TAU*(u*11+v*7))+.045*math.sin(TAU*(u*29-v*19))+.025*math.sin(TAU*(u*61+v*43))
    return .14+.70*bevel+waves*bevel
heights=[height(x,y) for y in range(N) for x in range(N)]
for y in range(N):
    for x in range(N):
        h=heights[y*N+x]
        variation=math.sin(TAU*(x/N*7+y/N*3))*7+math.sin(TAU*(x/N*53-y/N*47))*5
        stone.extend(bytes(clamp(c*h+variation+24) for c in (113,110,98)))
        dx=(heights[y*N+(x+1)%N]-heights[y*N+(x-1)%N])*7
        dy=(heights[((y+1)%N)*N+x]-heights[((y-1)%N)*N+x])*7
        inv=1/math.sqrt(dx*dx+dy*dy+1)
        normal.extend(bytes((clamp(127-127*dx*inv),clamp(127-127*dy*inv),clamp(127+127*inv))))
png("stone",N,N,3,stone)
png("stone_normal",N,N,3,normal)
# Soft cloud sprite with a scalloped silhouette; true alpha, no background plate.
N=512; data=bytearray()
lobes=[(-.45,.05,.39),(-.17,-.19,.47),(.18,-.14,.49),(.48,.04,.36),(.05,.20,.41)]
for y in range(N):
    v=(y+.5)/N*2-1
    for x in range(N):
        u=(x+.5)/N*2-1
        density=max((r-math.hypot(u-a,(v-b)*1.2))/r for a,b,r in lobes)
        a=clamp(max(0,min(1,density*3))*205)
        shade=clamp(240+min(1,max(-1,-v))*14)
        data.extend(bytes((shade,shade,min(255,shade+10),a)))
png("cloud",N,N,4,data)
print("Original high-resolution materials ready",flush=True)

# Rich original decorative materials, used on deck borders and stage landmarks.
N=2048
for name,base,amp in [("gold_metal",(168,121,49),32),("moss",(56,102,44),38),("crystal",(54,143,133),52)]:
    data=bytearray()
    for y in range(N):
        v=y/N
        for x in range(N):
            u=x/N
            n=(math.sin(TAU*(u*17+v*11)+math.sin(TAU*(u*3-v*4))*1.4)*.40+
               math.sin(TAU*(u*73-v*39))* .24+
               math.sin(TAU*(u*151+v*83))* .10+
               math.sin(TAU*(u*5-v*3))*.26)
            data.extend(bytes(clamp(c+n*amp) for c in base))
    png(name,N,N,3,data)
    print("Material",name,flush=True)


# 24 original PBR-style albedo and normal maps for the playable floor surfaces.
# Periodic multiscale mineral/wood relief; deterministic, no imported copyrighted art.
import numpy as np
from PIL import Image
N=2048
u=np.arange(N,dtype=np.float32)[None,:]/N
v=np.arange(N,dtype=np.float32)[:,None]/N
finishes=[(96,111,116),(70,103,83),(145,115,80),(105,92,139),(125,84,51),(112,149,169),(103,126,80),(61,71,87),(71,113,140),(130,84,66),(143,140,126),(102,90,142)]
for i in range(24):
    t=i%12
    rng=np.random.default_rng(1207+i)
    noise=np.zeros((N,N),dtype=np.float32)
    for freq,amp in [(8,0.38),(32,0.25),(128,0.15),(512,0.075),(1024,0.035)]:
        field=rng.integers(0,256,(freq,freq),dtype=np.uint8)
        # Bicubic scale a periodic field, including wraparound boundary samples.
        tile=np.tile(field,(3,3))
        im=Image.fromarray(tile).resize((N*3,N*3),Image.Resampling.BILINEAR)
        noise+=(np.asarray(im)[N:2*N,N:2*N].astype(np.float32)/255-.5)*amp
    warp=np.sin(TAU*(u*3+v*2))*0.016
    if t in [4,9]:
        coord=(u*8+warp)%1
        seam=np.clip(np.minimum(coord,1-coord)*22,0,1)
        grain=np.sin(TAU*(u*73+v*2+noise*0.9))*0.07
        relief=0.55+noise+grain-(1-seam)*0.18
    elif t in [3,5,7,11]:
        vein=np.abs(np.sin(TAU*(u*3+v*4+noise*1.1)))
        relief=0.52+noise*0.95-np.maximum(0,0.13-vein)*0.8
    else:
        row=np.floor(v*4)
        a=(u*4+(row%2)*0.5)%1
        b=(v*4)%1
        edge=np.minimum(np.minimum(a,1-a),np.minimum(b,1-b))
        relief=0.50+noise-(1-np.clip(edge*55,0,1))*0.15
    relief=relief.astype(np.float32)
    color=np.asarray(finishes[t],dtype=np.float32)[None,None,:]
    rgb=np.clip(color*(0.85+relief[:,:,None]*0.44)+noise[:,:,None]*32,0,255).astype(np.uint8)
    Image.fromarray(rgb).save(OUT/("deck_%02d.png"%i),compress_level=4)
    dx=(np.roll(relief,-1,axis=1)-np.roll(relief,1,axis=1))*9
    dy=(np.roll(relief,-1,axis=0)-np.roll(relief,1,axis=0))*9
    inv=1/np.sqrt(dx*dx+dy*dy+1)
    norm=np.stack([127-127*dx*inv,127-127*dy*inv,127+127*inv],axis=-1)
    Image.fromarray(np.clip(norm,0,255).astype(np.uint8)).save(OUT/("deck_normal_%02d.png"%i),compress_level=4)
    print("Course surface and relief",i+1,flush=True)

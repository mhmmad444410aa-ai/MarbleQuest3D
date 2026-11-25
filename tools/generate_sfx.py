"""Original deterministic, non-musical foley. 16-bit mono WAV; no external sound license."""
import math, random, wave, struct
from pathlib import Path
OUT=Path(__file__).resolve().parents[1]/'assets'/'ui'
OUT.mkdir(parents=True,exist_ok=True)
RATE=22050
def write(name,duration,kind):
    rng=random.Random(314159+len(name))
    n=int(duration*RATE)
    data=[]
    slow=0.0
    fast=0.0
    for i in range(n):
        t=i/RATE
        raw=rng.uniform(-1,1)
        slow=.965*slow+.035*raw
        fast=.64*fast+.36*raw
        if kind=='roll':
            edge=min(1,i/120,(n-i-1)/120)
            value=(slow*.7+fast*.20+raw*.035)*edge
        elif kind in ('pickup','bonus','win'):
            bursts=[(0.0,1.0)] if kind=='pickup' else ([(0.0,1.0),(.095,.70)] if kind=='bonus' else [(0,1),(.12,.8),(.27,.9),(.41,.7)])
            value=sum(amp*math.exp(-17*(t-st))*(raw*.25+fast*.42+slow*.35) for st,amp in bursts if t>=st)
        else:
            decay=math.exp(-5*t)
            value=(slow*1.8+fast*.32+raw*.08)*decay
            if kind=='lose' and t>.17: value+=(fast*.35+slow*.8)*math.exp(-8*(t-.17))
        data.append(max(-32767,min(32767,int(value*20000))))
    with wave.open(str(OUT/(name+'.wav')),'wb') as wav:
        wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(RATE)
        wav.writeframes(struct.pack('<'+'h'*len(data),*data))
for name,duration in [('roll',1.3),('pickup',.26),('bonus',.4),('win',.85),('fall',.5),('lose',.8)]:
    write(name,duration,name)

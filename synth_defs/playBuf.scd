//PLays back a simple audio buffer to all channels
SynthDef(\playBuf, {arg out, buf; var sig; sig = PlayBuf.ar(1, buf, doneAction: 2); Out.ar([0, 1, 2], sig)}).add;
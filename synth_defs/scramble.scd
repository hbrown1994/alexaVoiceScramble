//randomly scramble buffer slices
(
SynthDef(\scramble, {
	arg buf, indices, speed, stepSpeed=0.5, sel, min, stepSize;
	var sig, noise;

	//Random walk over the vocal recording database
	noise = LFBrownNoise0.kr(speed, 0.1).linlin(-1.0, 1.0, min, BufFrames.kr(indices) - 1);

	//Read a chunk of audio starting from the audio index provided by the random walk
	sig = BufRd.ar(1, buf,
		Phasor.ar(0,1,
			BufRd.kr(1, indices, noise, 0, 1),
			BufRd.kr(1, indices, noise+1, 0, 1),
			BufRd.kr(1, indices, noise, 0, 1),
	), 0, 1);

	Out.ar([0, 1, 2], sig); //Send to all outputs
}).add;
);
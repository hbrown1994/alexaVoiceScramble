//record voice to a buffer
SynthDef(\voxRec, {
	arg thresh, buf, amp=1, gate;
	var onsets, trig, oneTrig, onsetTrig, onsetTrigInv, silence, in, sig;

	in = SoundIn.ar(~soundFlowerInput) * amp; //Input from the AVS web portal (Jitsi)

	//Noise Gate to remove microphone and ambient sound
	in = Compander.ar(in, in,
		thresh: 0.005,
		slopeBelow: 10,
		slopeAbove:  1,
		clampTime:   0.01,
		relaxTime:   0.01
	);

	//Limiter for safety from clipping
	in = Limiter.ar(in);

	in = in * gate.lag(0.05); //Gate to turn off microphone

	onsetTrig = (RMS.kr(in) < thresh); //detect sound off
	onsetTrigInv = onsetTrig.linlin(0, 1, 1, 0); //detect sound on

	//Send triggers to main routine when someone has started or has stopped speaking
	trig = SetResetFF.kr(onsetTrigInv, (Sweep.kr(Coyote.kr(in))> 3.0));
	SendTrig.kr(trig.linlin(0, 1, 1, 0));

	RecordBuf.ar(in, buf, 0, 1, 0, 1, 0, trig, 0); //Record vocal recording to a buffer
}).add;
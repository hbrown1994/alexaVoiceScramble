(
SynthDef(\alexaProcess, {
	arg out=0, input, onsetHPF=300, weights=#[0.2, 0.3, 0.5], thresh;
	var in, stretch, glitch, sig, trig, onsetTrig;

	in = SoundIn.ar(input); //Alexa's output as input to the SynthDef

	//FFT Stretch and Bend Effect
	stretch = StretchShiftFFT.ar(input, -3, 0.5, 0.5, 5, 0.5, 0.2, 3);
	//Processor modeled after Internet Connection Glitches
	glitch = InternetGlitch.ar(input, 0, 0.5, 3.0, 1, 0.1, 0.9, 300, 1, [0.3, 0.5, 0.4].normalizeSum);

	trig = FluidAmpSlice.ar(HPF.ar(in, onsetHPF), fastRampUp: 10,fastRampDown: 2205,slowRampUp: 4410,slowRampDown: 4410, onThreshold: 10,offThreshold: 5,floor: -40,minSliceLength: 4410,highPassFreq: 20); //Onset detector that detects the onset of each sound coming from the Alexa

	//Use onsets to randomly shift the signal between the orginal, stretch, and internet glitch
	sig = LinSelectX.ar(TWindex.ar(trig, weights, 1), [in, stretch, glitch]);

	//Have orginal signal play first for 5 seconds
	sig = LinSelectX.ar(Sweep.kr(Impulse.kr(0)) > 5, [in, sig]);

	onsetTrig = (RMS.kr(in) < thresh); //detect sound off
	onsetTrig = SetResetFF.kr(onsetTrig, Sweep.kr(Coyote.kr(in))> 5.0).linlin(0, 1, 1, 0);

	//Turn sound off if Alexa is silent for 5 seconds or after a minute
	//Trigger is sent to the Routine (~rout) in "alexaVoiceScramble.scd"
	SendTrig.kr(onsetTrig+(Sweep.kr(Impulse.kr(0)) > 60), value: 1.0);

	Out.ar(out, sig);
}).add;
);

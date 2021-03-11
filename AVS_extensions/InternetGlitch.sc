InternetGlitch {

	*ar {arg input, amp=(-3), freqLow=1, freqHigh=1, trigFreq, silenceLow, silenceHigh, onsetHPF, orginalOnOff, effectsWeights=#[0.3, 0.5, 0.4];
		var sig, phasor, env, env_trig, trig, freq, read_point, chunk, mouse_change, rate, windowSize, clock, gDev, windowSizeSel, comb, sigFinal, wave, in, clockInv, lastFrame, buffer;

		in = SoundIn.ar(input);

		buffer = LocalBuf(SampleRate.ir*4);
		RecordBuf.ar(in, buffer);

		clock = FluidAmpSlice.ar(HPF.ar(in, onsetHPF), fastRampUp: 10,fastRampDown: 2205,slowRampUp: 4410,slowRampDown: 4410, onThreshold: 10,offThreshold: 5,floor: -40,minSliceLength: 4410,highPassFreq: 20); //detect sound off

		gDev = TWindex.kr(clock, [0.7, 0.5, 0.3, 0.1, 0.3, 0.6], 1);
		gDev = Select.kr(gDev, [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]);
		trig = GaussTrig.kr(trigFreq, gDev);

		windowSizeSel = TWindex.kr(trig, [0.3, 0.2, 0.1, 0.2, 0.4, 0.4, 0.4], 1);
		windowSize = Select.kr(windowSizeSel, [3.125, 6.25, 12.5, 25, 50, 75, 100]);

		read_point = TBrownRand.kr(0, BufFrames.kr(buffer) -  windowSize, 1.0, 1, trig);

		freq = TBrownRand.kr(freqLow, freqHigh, 1.0, 1, trig); //warp: 1 -> exponential mapping
		freq = freq * Select.kr(windowSizeSel, [32, 16, 8, 4, 2, 1.5, 1]).lag(0.01);

		windowSize = windowSize*(SampleRate.ir/100);
		chunk = read_point+windowSize;
		rate = windowSize * (freq/SampleRate.ir);
		phasor = Phasor.ar(trig: trig, rate: rate, start: read_point, end: chunk, resetPos: read_point);

		sig = BufRd.ar(1, buffer, phasor, loop: Select.kr(TWindex.kr(trig, [0.7, 0.3]), [0, 1]));

		sig = sig * Select.kr(TWindex.kr(trig, [silenceLow, silenceHigh]), [0, 1]).lag(0.005);

		comb = CombL.ar(sig, 1.0, TRand.kr(0.01, 0.1, trig).lag(Select.kr(TWindex.kr(trig, [0.7, 0.3]), [0, TRand.kr(0.05, 0.5, trig)])),TRand.kr(0.2, 1.5, trig).lag(0.01));

		wave = WaveLoss.ar(LinSelectX.ar(TWindex.kr(trig, [0.4, 0.6]), [sig, comb]), TExpRand.kr(35.0, 15.0, trig), 40.0);

		sigFinal = LinSelectX.ar(TWindex.kr(trig, effectsWeights), [sig, comb, wave]);
		sigFinal = LinSelectX.ar(orginalOnOff, [in, sigFinal]);

		sigFinal = Mix([sigFinal]) * amp.dbamp;

		^sigFinal;
	}
}






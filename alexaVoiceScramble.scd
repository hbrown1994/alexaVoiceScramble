//Hardware Inputs:
//  2. Ouput 3 from Clarett
//  3. Alexa

//JitSi Set-up:
//  Stream From Chrome
//  Input: ThunderBolt
//  Output: SoundFlower 2ch
//  once you enter jitsi, go to settings and make sure everyone starts muted,
//    hidden, and "follow me" is checked.

//SuperCollideer Set-up:
//   Input: Soundflower (2ch)
//   Output: Focusrite Thunderbolt
//   Below Chunk Does this set up (run before boot!)

(
//Server.default.options.inDevice_("Aggregate Device 2"); //test line
Server.default.options.inDevice_("Aggregate Device 2");
Server.default.options.outDevice_("Aggregate Device 2");
Server.local.options.numInputBusChannels = 21;
Server.local.options.numOutputBusChannels = 3;
~soundFlowerInput = 20;
~focusriteInput = 2;
~focusriteOutput = 2;
~count=(-1);
);


(
(~loader = FluidLoadFolder("/Users/hunterbrown/Desktop/winter_2021/corpus/"); ~loader.play(s));
~corpus_indices = Buffer.new(s);
if(~count+PathName("/Users/hunterbrown/Desktop/winter_2021/corpus/").entries.size > 0, {~corpus = ~loader.buffer; FluidBufAmpSlice.process(s,~corpus.normalize, 0, -1, 0, -1, ~corpus_indices, 10, 2205, 4410, 4410, 10, 5, -30, 44100, 150)});
);



(
//declare globals and buffers
~count=(-1);
~rec = Buffer.alloc(s, s.sampleRate*10);
~indices = Buffer.new(s);
~hold_buf = Buffer.alloc(s, s.sampleRate*10);
~first_buf = Buffer.alloc(s, s.sampleRate*5);

//record voice to a buffer
SynthDef(\voxRec, {
	arg thresh, buf, amp=1, gate;
	var onsets, trig, oneTrig, onsetTrig, onsetTrigInv, silence, in, sig;

	//in = Mix([0, 1]);
	in = SoundIn.ar(~soundFlowerInput) * amp;

	in = Compander.ar(in, in,
		thresh: 0.005,
		slopeBelow: 10,
		slopeAbove:  1,
		clampTime:   0.01,
		relaxTime:   0.01
	);

	in = Limiter.ar(in);

	in = in * gate.lag(0.05);

	onsetTrig = (RMS.kr(in) < thresh); //detect sound off
	onsetTrigInv = onsetTrig.linlin(0, 1, 1, 0); //detect sound on

	oneTrig = Trig.kr(onsetTrigInv, BufFrames.kr(buf)/SampleRate.ir);//Sweep.kr((onsetTrig), )

	trig = SetResetFF.kr(onsetTrigInv, (Sweep.kr(Coyote.kr(in))> 3.0));
	SendTrig.kr(trig.linlin(0, 1, 1, 0));

	trig;

	RecordBuf.ar(in, buf, 0, 1, 0, 1, 0, trig, 0);
}).add;

(
SynthDef(\alexaProcess, {
	arg out=0, input, onsetHPF=300, weights=#[0.2, 0.3, 0.5], thresh;
	var in, stretch, glitch, sig, trig, onsetTrig;

	in = SoundIn.ar(input);
	stretch = StretchShiftFFT.ar(input, -3, 0.5, 0.5, 5, 0.5, 0.2, 3);
	glitch = InternetGlitch.ar(input, 0, 0.5, 3.0, 1, 0.1, 0.9, 300, 1, [0.3, 0.5, 0.4].normalizeSum);

	trig = FluidAmpSlice.ar(HPF.ar(in, onsetHPF), fastRampUp: 10,fastRampDown: 2205,slowRampUp: 4410,slowRampDown: 4410, onThreshold: 10,offThreshold: 5,floor: -40,minSliceLength: 4410,highPassFreq: 20);

	sig = LinSelectX.ar(TWindex.ar(trig, weights, 1), [in, stretch, glitch]);

	sig = LinSelectX.ar(Sweep.kr(Impulse.kr(0)) > 5, [in, sig]);

	onsetTrig = (RMS.kr(in) < thresh); //detect sound off
	onsetTrig = SetResetFF.kr(onsetTrig, Sweep.kr(Coyote.kr(in))> 5.0).linlin(0, 1, 1, 0);

	onsetTrig.poll;
	SendTrig.kr(onsetTrig+(Sweep.kr(Impulse.kr(0)) > 60), value: 1.0);

	Out.ar(out, sig);
}).add;
);

//play "question" buffer
SynthDef(\playBuf, {arg out, buf; var sig; sig = PlayBuf.ar(1, buf, doneAction: 2); Out.ar([0, 1, 2], sig)}).add;

//randomly scrub over buffer slices
(
SynthDef(\scrub, {
	arg buf, indices, gate, speed, stepSpeed=0.5, sel, min, stepSize;
	var sig;

	var noise;
	noise = Select.kr(sel, [0, LFBrownNoise0.kr(speed, 0.1).linlin(-1.0, 1.0, min, BufFrames.kr(indices) - 1)]);

	sig = BufRd.ar(1, buf,
		Phasor.ar(0,1,
			BufRd.kr(1, indices, noise, 0, 1),
			BufRd.kr(1, indices, noise+1, 0, 1),
			BufRd.kr(1, indices, noise, 0, 1),
	), 0, 1);

	sig = sig * EnvGen.kr(Env.asr(0.005, 1, 0.005), gate);

	Out.ar([0, 1, 2], sig);
}).add;
);

//routine to process buffers and play back sound
o = OSCFunc({ arg msg, time;
	[time, msg].postln;
	if(msg[3]==1.0, {if(~output.isPlaying ,{~output.free; ~rout.next;})});
	if(msg[3]==0,
		{
			~rout = Routine({
				if(~count!=(-1), {

					FluidBufAmpSlice.process(s,~rec.normalize, 0, -1, 0, -1, ~indices, 10, 2205, 4410, 4410, 8, 2, -40, (44100)*2, 150);

					~record.set(\gate, 0);

					1.wait; // too fast?
					~indices.getn(0,~indices.numFrames,{|item|item[1].postln; ~rec.copyData(~hold_buf, srcStartAt: item[1])});

					s.sync;

					~hold_buf.write("/Users/hunterbrown/Desktop/winter_2021/corpus/"++(~count+PathName("/Users/hunterbrown/Desktop/winter_2021/corpus/").entries.size).asString++".wav");//write audio to folder

					s.sync;

					~indices.getn(0,~indices.numFrames,{|item| ~end_frame = item[1]; ~rec.copyData(~first_buf, numSamples:item[1])});

					s.sync;
					//load folder to single buffer
					(~loader = FluidLoadFolder("/Users/hunterbrown/Desktop/winter_2021/corpus/"); ~loader.play(s));
					s.sync;
					~corpus = ~loader.buffer; //declare ~corpus as buffer
					s.sync;
					~play = Synth(\playBuf, [\buf, ~first_buf.normalize, \out, ~focusriteOutput]);

					FluidBufAmpSlice.process(s,~corpus.normalize,indices:~corpus_indices,fastRampUp: 10,fastRampDown: 2205,slowRampUp: 4410,slowRampDown: 4410,onThreshold: 10,offThreshold: 5,floor: -40,minSliceLength: 44100,highPassFreq: 20);

					(2.5).wait;

					~play.free;
					0.1.wait;
					~scrub = Synth(\scrub, [\buf, ~corpus.normalize, \indices, ~corpus_indices, \gate, 1, \speed, 3.5, \sel, 1, \min, 0]);

					(1).wait;


					~scrub.free;
					~output = Synth(\alexaProcess, [\out, ~focusriteOutput, \input, ~focusriteInput, \onsetHPF, 300, \weights, [0.3, 0.4, 0.5].normalizeSum, \thresh, 0.008]).register;


					~rout.yield;


					"KILL".postln;
					~record.set(\gate, 1);
					~count = ~count + 1;
				}, {~count = ~count + 1});
			}).play;
	});
},'/tr', s.addr);
);

//RUN
~record = Synth(\voxRec, [\thresh, 0.008, \buf, ~rec, \amp, 20, \gate, 1]);
Recorder(s).record(numChannels:3);



/*____________________________________-*/
~rec.play;
~record.set(\amp, 0);
~record.set(\amp, 1);

//delete corpus Files
PathName("/Users/hunterbrown/Desktop/winter_2021/corpus/").entries.do{
	arg entries;
	File.delete("/Users/hunterbrown/Desktop/winter_2021/corpus/"++(entries.fileName).asString);
};

~offCount = -1;














/*______________________________________________________________________*/
(
SynthDef(\alexaProcess, {
	arg out=0, input, onsetHPF=300, weights=#[0.2, 0.3, 0.5], thresh;
	var in, stretch, glitch, sig, trig, onsetTrig;

	in = SoundIn.ar(input);
	stretch = StretchShiftFFT.ar(0, -3, 0.5, 0.5, 5, 0.5, 0.2, 3);
	glitch = InternetGlitch.ar(0, 0, 0.5, 3.0, 1, 0.1, 0.9, 300, 1, [0.3, 0.5, 0.4].normalizeSum);

	trig = FluidAmpSlice.ar(HPF.ar(in, onsetHPF), fastRampUp: 10,fastRampDown: 2205,slowRampUp: 4410,slowRampDown: 4410, onThreshold: 10,offThreshold: 5,floor: -40,minSliceLength: 4410,highPassFreq: 20);

	sig = LinSelectX.ar(TWindex.ar(trig, weights, 1), [in, stretch, glitch]);

	sig = LinSelectX.ar(Sweep.kr(Impulse.kr(0)) > 5, [in, sig]);

	onsetTrig = (RMS.kr(in) < thresh); //detect sound off
	onsetTrig = SetResetFF.kr(onsetTrig, (Sweep.kr(Impulse.kr(0)) > 20)+(Sweep.kr(Coyote.kr(in))> 5.0)).linlin(0, 1, 1, 0);

	SendTrig.kr(onsetTrig, value: 1.0);

	Out.ar(out, sig);
}).add;
);

~output = Synth(\alexaProcess, [\out, 0, \input, ~focusriteInput, \onsetHPF, 300, \weights, [0.3, 0.4, 0.5].normalizeSum, \thresh, 0.008]);

~offCount = (-1);
f = OSCFunc({ arg msg, time;

	msg[3].postln;
	if(msg[3]==1.0, {if(~offCount>(-1.0), {~output.free; ~rout.next; msg.postln}); ~offCount = ~offCount + 1;});

},'/tr', s.addr);



~rout = Routine({
	"1".postln;
	~offCount = (-1);

	~rout.yield;

	"off".postln;
	~output.free;

}).play;

~rout.next;





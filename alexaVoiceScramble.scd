(
//AUDIO INPUTS AND Outputs
~soundFlowerInput = 20; //Set audio device inputs and outputs
~interfaceInput = 2;
~interfaceOutput = 2;

//Hardware Inputs:
//  1. Ouput 2 from Audio Interface
//  2. Alexa's 1/8th inch output

//JitSi Set-up:
//  Stream From Chrome
//  Input: Audio Interface
//  Output: SoundFlower 2ch
//  once you enter jitsi, go to settings and make sure everyone starts muted,
//    hidden, and "follow me" is checked.

//SuperCollideer Set-up:
//   Input: Soundflower (2ch)
//   Output: Audio Interface

~synth_def_path = PathName(thisProcess.nowExecutingPath).parentPath++"synth_defs/";
~database_path = PathName(thisProcess.nowExecutingPath).parentPath++"database/";

(
//Server Settings
s = Server.local;
s.newBusAllocators;
s.latency = 0.05;
ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;
Server.default.options.inDevice_("alexaDevice"); //Set Audio Device
Server.default.options.outDevice_("alexaDevice");
Server.local.options.numInputBusChannels = 21; //Set Number of Channels
Server.local.options.numOutputBusChannels = 3;
~count=0; //initiate counter for number of calls to the routine
);

//make audio buffers for recording and processing
~makeBuffers = {
	~rec = Buffer.alloc(s, s.sampleRate*10);
	~indices = Buffer.new(s);
	~hold_buf = Buffer.alloc(s, s.sampleRate*10);
	~first_buf = Buffer.alloc(s, s.sampleRate*5);
	~corpus_indices = Buffer.new(s);
};

ServerBoot.add(~makeBuffers);

s.waitForBoot({

	//load audio database
	(~loader = FluidLoadFolder("/Users/hunterbrown/Desktop/winter_2021/corpus/"); ~loader.play(s));

	s.sync;

	//Process and slice audio in database
	if(~count+PathName("/Users/hunterbrown/Desktop/winter_2021/corpus/").entries.size > 0, {~corpus = ~loader.buffer; FluidBufAmpSlice.process(s,~corpus.normalize, 0, -1, 0, -1, ~corpus_indices, 10, 2205, 4410, 4410, 10, 5, -30, 44100, 150, action: {"done".postln})});

	s.sync;

	//Load Sample Playback and Audio Processing Modules in the sub folder "synth_defs"
	PathName(~synth_def_path).entries.size.do{
		arg i=0;
		thisProcess.interpreter.executeFile(~synth_def_path++PathName(~synth_def_path).entries.at(i).fileName.asString);
		i = i + 1;
	};

	s.sync;

	(
		//Routine to process buffers and playback voice recordings
		OSCFunc({ arg msg, time;
			//[time, msg].postln; //Print messages for debugging
			if(msg[3]==1.0, {if(~output.isPlaying ,{~output.free; ~rout.next})});  //msg[3] == 1 is when Alexa is finished outputting, move routine forward

			//msg[3] == 0 is when voice is done being recorded
			if(msg[3]==0,
				{
					~rout = Routine({if(~count!=(-1), { //Declare routine and filter out first pass of routine to avoid a false start (via the ~count var)

						//After recording the user's voice into the ~rec buffer, slice this buffer into individual samples of each word spoken
						FluidBufAmpSlice.process(s,~rec.normalize, 0, -1, 0, -1, ~indices, 10, 2205, 4410, 4410, 8, 2, -40, (44100)*2, 150);

						//Turn off recording input
						~record.set(\gate, 0);

						//Wait for FluidBufAmpSlice to finsh slicing
						1.wait;

						//Temporary Buffer (~hold_buf) to store all words from orginal recording except the first two words ("Alexa" and "Skill word")
						~indices.getn(0,~indices.numFrames,{|item|item[1].postln; ~rec.copyData(~hold_buf, srcStartAt: item[1])});

						s.sync;

						//Write ~hold_buf to database
						~hold_buf.write(~database_path++(~count+PathName("/Users/hunterbrown/Desktop/winter_2021/corpus/").entries.size).asString++".wav");

						s.sync;

						//Store the first part of the question ("Alexa" and "Skill word") to an audio buffer (~first_buf) to be played back first
						~indices.getn(0,~indices.numFrames,{|item| ~end_frame = item[1]; ~rec.copyData(~first_buf, numSamples:item[1])});

						s.sync;

						//Load database to a buffer for scrambling
						(~loader = FluidLoadFolder("/Users/hunterbrown/Desktop/winter_2021/corpus/"); ~loader.play(s));

						s.sync;

						~corpus = ~loader.buffer; //Add buffer to a global variable

						s.sync;

						//play back first part of the question ("Alexa" and "Skill word")
						~play = Synth(\playBuf, [\buf, ~first_buf.normalize, \out, ~interfaceOutput]);

						//Reslice the database for smaller slices as the first part of the question plays back
						FluidBufAmpSlice.process(s,~corpus.normalize, 0, -1, 0, -1, ~corpus_indices, 10, 2205, 4410, 4410, 10, 5, -40, 44100, 20);


						(2.5).wait; //Wait for 1st part of question to playback before killing playback buffer and playing scrambled text

						~play.free; //kill plyback buffer

						0.1.wait;

						//playback scrambled database for a second
						~scramble = Synth(\scramble, [\buf, ~corpus.normalize, \indices, ~corpus_indices, \speed, 3.5, \min, 0]);

						(1).wait;

						~scramble.free; //kill scrambled playback

						//stream and process alexa's real-time output
						~output = Synth(\alexaProcess, [\out, ~interfaceOutput, \input, ~interfaceInput, \onsetHPF, 300, \weights, [0.3, 0.4, 0.5].normalizeSum, \thresh, 0.008]).register;

						~rout.yield; //Hold routine until Alexa is finished with its output. (See line 13)

						"Alexa is Done".postln;

						~record.set(\gate, 1); //Open Recording Mic

						~count = ~count + 1; //Move Count forward

					}, {~count = ~count + 1});
					}).play;
			});
		},'/tr', s.addr);
	);

	s.sync;

	~record = Synth(\voxRec, [\thresh, 0.008, \buf, ~rec, \amp, 20, \gate, 1]); //Run the system
});
);

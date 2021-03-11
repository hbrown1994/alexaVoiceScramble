# alexaVoiceScramble


To use Alexa Voice Scramble:

1. Install Software Dependencies:
- SuperCollider: https://supercollider.github.io/download
- FluComa SuperCollider Library: https://www.flucoma.org/download/
- SoundFlower: https://soundflower.en.softonic.com/mac

2. Gather Necessary Hardware:
- Audio Interface with 2 inputs and 2 outputs
- Mac Laptop
- 1 Speaker
- Alexa Device
- Cables needed to connect your audio interface to the speaker and Alexa

3. Set-Up Hardware:
- Connect the 1st output of audio interface to a speaker.
- Connect the 2nd output of your audio interface to the 2nd input of your audio interface (a loopback)
- Connect the Alexa to the 1st input of the audio interface
- Set-up speaker so that it is pointed at the Alexa.

4. Create an Aggregate Audio Device
- Create an aggregate audio device that combines your audio interface and SoundFlower 2ch. See the below guide.
- https://support.apple.com/en-us/HT202000
- Name the device "alexaDevice" (case sensitive)

5. Set-up Supercollider:
- Copy the "AVS_extensions" folder into the following directory: "~/User/Library/Application Support/SuperCollider/"
- Open the "alexaVoiceScramble.scd" file.
- Set the variable ~soundFlowerInput at the very top of the file to the 1st input of the SoundFlower (2ch) block of the Aggregate Audio Device you created.
- Set the variables ~interfaceInput and ~interfaceOutput at the very top of the file to the 1st inputs and outputs of the interface block within the Aggregate Audio Device.

6. Run the Alexa Voice Scramble:
- Open the following page: https://hbrown1994.github.io/culture-jam-test/portal.html
- Set the Jitsi input to your audio interface
- Set the Jitsi output to SoundFlower (2ch)
- Execute the "alexaVoiceScramble.scd" Supercollider file by opening the file, click the "Language" menu at the top of the screen and click "Evaluate File."

Notes:
- To see explanations of how the code works, see the comments within "alexaVoiceScramble.scd" file and all of the .scd files in the "synth_def" folder.

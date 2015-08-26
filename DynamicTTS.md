# Introduction #

Cepstral provides free demo voices to generate .wav files from text. These can be used for converting text to speech and then use it instead of session:speak() so as to overcome drawback of no TTS during session:speak().


# Details #

<li>First go to Cepstral and Download files for Lawrence link below</li>

http://downloads.cepstral.com/cepstral/i386-linux/Cepstral_Lawrence_i386-linux_5.1.0.tar.gz

<li> Install the above downloaded package to it'd default directory i.e /opt/swift</li>

<li>Now Download wavetools from sourceforge.net (You won't require them if you use a paid version of Cepstral</li>

<li>Extract wavetools archive and copy file named wavecutter to the required directory </li>

<li> Now copy the following content to a python script</li>

import os
import sys

sentence = sys.argv[1](1.md)

f = open('rec.tmp','w')

f.write(sentence)

f.close()

os.system('/opt/swift/bin/swift -n lawrence -m text -f rec.tmp -o file1.wav')

os.system('./wavcutter -i=file1.wav -o=ivr.wav -c=00:00:08.5-01:00:00')

<li> Now your script is ready any input that you provide it in string format will be converted to sound an stored in file ivr.wav you can use this file in your program instead of using sesioon:speak()</li>

<h3>Integration into Lua Script</h3>
<li>instead of session:speak() call function speak whose definition is given below</li>

function speak(message)
> os.execute('sudo /opt/swift/bin/swift -n lawrence -m text "'..message..'" -o file1.wav')

> os.execute('./wavcutter -i=file1.wav -o=/usr/local/freeswitch/sounds/en/us/callie/ivr.wav -c=00:00:08.5-01:00:00')
end

<li>Now you can pass this function any text message to get the sound file use read(ivr.wav) with appropriate arguments and filename as ivr.wav</li>
INSTALLING CMUCLTK-0.7
You will require this tool to build ur lm.DMP file which will be used while performing the TRAINING of the Acoustic Model.
First extract the cmucltk-0.7 in ur current directory and perform :
1. ./configure
2. make
3. make install
U might require to run these commands using sudo if u are not the root and might need to change the permissions of ur directory using chmod -R 777 /WorkingDirectory
After u have installed all the files u will require will be present in the /usr/local/bin directory

CREATING lm(language model) file

U will require ur lm file while Adaptation and Training
In order to create ur lm file u use QUICKLM tool (http://www.speech.cs.cmu.edu/tools/factory.html) .
Other alternatives are:
http://www.speech.cs.cmu.edu/tools/lmtool-new.html

Speech recognition engines require two types of files to recognize speech. They require an acoustic model, which is created by taking audio recordings of speech and their transcriptions (taken from a speech corpus), and 'compiling' them into a statistical representations of the sounds that make up each word (through a process called 'training'). They also require a language model or grammar file. A language model is a file containing the probabilities of sequences of words. A grammar is a much smaller file containing sets of predefined combinations of words. Language models are used for dictation applications, whereas grammars are used in desktop command and control or telephony interactive voice response (IVR) type applications.

CREATING lm.DMP file

Copy ur text file to /usr/local/bin
Ur text file will look like:-
<s> Sentence1 </s>
<s> Sentence2 </s>
<s> Sentence3 </s>
Now execute the following commands
1. cat a.txt | text2wfreq | wfreq2vocab -top 20000 > a.vocab
"
> if the cmmds doesn't run then run
export LD\_LIBRARY\_PATH=$LD\_LIBRARY\_PATH:"/usr/local/lib/"
For ubuntu u can place the command in the .bashrc and restart ur system.
For centOS u can place the command in /etc/profile
"
2. cat a.txt | text2idngram -vocab a.vocab -idngram a.idngram
3. cat a.txt | idngram2lm -vocab a.vocab -idngram a.idngram -binary a.binlm
4. binlm2arpa -binary a.binlm -arpa a.arpa
This will give u .arpa file and now to convert it to lm.DMP use
sphinx\_lm\_convert -i /usr/local/bin/a.arpa -o /usr/local/bin/a.lm.DMP
"
sphinx\_lm\_convert is found in /usr/local/src/freeswitch/libs/sphinxbase-0.7/src/sphinx\_lmtools
"

While performing TRAINING OF ACOUSTIC MODEl u will also require a phoneset file.
For this u will require a script make\_phoneset.pl

cat a.dic | make\_phoneset.pl > a.phone
This will generate ur phoneset file in the current directory.

INSTALLING SPHINXBASE-0.7 AND POCKETSPHINX-0.7

Pocketsphinx and sphinxbase are required by the UNIMRCP.
Sphinxbase needs to be installed before pocketsphinx.
Extract the sphinxbase and pocketsphinx to ur working directory and the execute the commands.
1. ./configure
"
U need to install bison for sphinxbase. For bison execute:ubuntu- sudo apt-get install bison
centos- sudo yum install bison
"
2. make
3. make install
Perform the above steps first for sphinxbase and then for pocketsphinx.

INSTALLING SPHINXTRAIN-1.0.7

U will require sphinxbase for installing sphinxtrain.
EXecute the folliowing commands
1. ./configure
"
If it generates an error then execute ./configure --with-sphinxbase=path to ur sphinxbase directory
--with-sphinxbase-build=path to ur sphinxbase directory.
"
2. make

INSTALLING UNIMRCP

Extract the unimrcp-1.0.0 and unimrcp-deps-1.0.0(unimrcp dependencies) to ur working directory.
U need to build the dependencies prior to installing unimrcp.
Use only the dependencies given in the unimrcp-deps-1.0.0
NOTE: the version of the unimrcp-deps and unimrcp should be same otherwise it won't build properly.

Build SofiaSIP
1. ./configure
"
It might generate 'rm: cannot remove `libtoolT': No such file or directory' but there is no issue regarding it so carry on with installation.
"
2. make
3. make install

Build apr
1. ./configure
2. make
3. make install

Buid apr-util
1. ./configure --with-apr=path to apr directory
2. make
3. make install

Now u can install ur unmrcp.
Change ur directory to the extracted unimrcp directory nad the perform :-
1. ./bootstrap
2. ./configure  --with-apr=/usr/local/apr --with-apr-util=/usr/local/apr --with-sofia-sip=path-to-sofia-sip-directory
--enable-pocketsphinx-plugin --with-pocketsphinx=path-to-pocketsphinx-directory --with-sphinxbase=path-to-sphinxbase-directory
3. make
"
U will get an error during this step so add
export LD\_LIBRARY\_PATH=$LD\_LIBRARY\_PATH:usr/local/apr/lib to ur .bashrc or /etc/profile depending upon ur linux version.
"
4. make install

Ur Unimrcp will be set up in /usr/local/unimrcp

ADAPTING THE  ACOUSTIC MODEL

For performing adaptation refer http://cmusphinx.sourceforge.net/wiki/tutorialadapt
Note:- Ur mllr\_transform,mllr\_solve,bw,map\_adapt,mk\_2sendump executables will be found in the bin of sphinxtrain directory(i.e path-to-sphinxtrain/bin.1686-pc-linux-gnu)
"
After u have executed ./bw command ,if u get an error of cannot locate ..mfc(i.e.example..mfc)
then add a option "-cepext mfc" along with other specified parameters while executing the bw command.
"
Take care whether u want ur acoustics for Sphinx4 or Pocketsphinx.
For sphinx4 in the ./bw remove parameter 'svspec' and change '-ts2cbfn .cont' otherwise no change for ocketsphinx.


TRAINING ACOUSTIC MODEL
For training refer to http://cmusphinx.sourceforge.net/wiki/tutorialam


INTEGRATING FREESWITCH AND UNIMRCP

FREESWITCH CHANGES
In the directory /usr/local/freeswitch/mrcp\_profile create a new xml for MRCPv2 connection with unimrcp
The new file will look like


&lt;include&gt;


> 

&lt;profile name="mrcpserver02" version="2"&gt;


> > 

&lt;param name="client-ip" value="auto"/&gt;


> > 

&lt;param name="client-port" value="8088"/&gt;


> > 

&lt;param name="server-ip" value="auto"/&gt;


> > 

&lt;param name="server-port" value="8060"/&gt;


> > 

&lt;param name="sip-transport" value="udp"/&gt;


> > 

&lt;param name="rtp-ip" value="auto"/&gt;


> > 

&lt;param name="rtp-port-min" value="4000"/&gt;


> > 

&lt;param name="rtp-port-max" value="5000"/&gt;


> > 

&lt;param name="codecs" value="PCMU PCMA L16/96/8000"/&gt;


> > 

&lt;synthparams&gt;


> > 

&lt;/synthparams&gt;


> > 

&lt;recogparams&gt;


> > > 

&lt;param name="start-input-timers" value="false"/&gt;



> > 

&lt;/recogparams&gt;



> 

&lt;/profile&gt;




&lt;/include&gt;



"
Ur client port can be any port which is not opened.
"
For MRCPv1 create a new xml



&lt;include&gt;


> 

&lt;profile name="mrcpserver01" version="1"&gt;


> > 

&lt;param name="server-ip" value="auto"/&gt;


> > 

&lt;param name="server-port" value="1554"/&gt;


> > 

&lt;param name="resource-location" value=""/&gt;


> > 

&lt;param name="speechsynth" value="speechsynthesizer"/&gt;


> > 

&lt;param name="speechrecog" value="speechrecognizer"/&gt;


> > 

&lt;param name="rtp-ip" value="auto"/&gt;


> > 

&lt;param name="rtp-port-min" value="4000"/&gt;


> > 

&lt;param name="rtp-port-max" value="5000"/&gt;


> > 

&lt;param name="codecs" value="PCMU PCMA L16/96/8000"/&gt;


> > 

&lt;synthparams&gt;


> > 

&lt;/synthparams&gt;


> > 

&lt;recogparams&gt;


> > > 

&lt;param name="start-input-timers" value="false"/&gt;



> > 

&lt;/recogparams&gt;



> 

&lt;/profile&gt;




&lt;/include&gt;



Now in /usr/local/freeswitch/conf/autoload\_configs edit the unimrcp.conf.xml and change param name="mrcpserver01/mrcpserver02"
depending upon u want to use MRCPv2 or MRCPv1.
In /usr/local/freeswitch/scripts add names.lua

session:answer()
> --freeswitch.consoleLog("INFO","Called extension is '" .. argv[1](1.md) .. "'\n")
> freeswitch.consoleLog("INFO","Called extension is \n")
> welcome= "/usr/local/unimrcp/sounds/arctic\_0001.wav"
> menu = "/usr/local/unimrcp/sounds/arctic\_0002.wav"
> nohear = "/usr/local/unimrcp/sounds/arctic\_0003.wav"
> nounderstand = "/usr/local/unimrcp/sounds/arctic\_0004.wav"
> forward = "/usr/local/unimrcp/sounds/arctic\_0005.wav"
> thankyou = "/usr/local/unimrcp/sounds/arctic\_0006.wav"
> goodbye = "/usr/local/unimrcp/sounds/arctic\_0007.wav"
> --
> grammar = "names"
> asrtag = "input"
> no\_input\_timeout = 32767
> recognition\_timeout = 5000
> confidence\_threshold = 0.1
> --
> session:streamFile(welcome)
> --session:streamFile(menu)
> --freeswitch.consoleLog("INFO","Prompt file is '" .. prompt .. "'\n")
> --
> tryagain = 1
> while (tryagain == 1) do
> --
if(session:ready()==false) then
break;
end
> > session:execute("play\_and\_detect\_speech",menu .. "detect:unimrcp {start-input-timers=false,no-nput-timeout=" .. no\_input\_timeout .. ",recognition-timeout=" .. recognition\_timeout .. "}" .. grammar)
> > xml = session:getVariable('detect\_speech\_result')
--freeswitch.consoleLog("CRIT","Tushar printing XML content \n");
--freeswitch.consoleLog("CRIT", xml .. "\n");
--freeswitch.consoleLog("CRIT","Printed XML content \n");
> > --     _,_,pre,result,suf = string.find(xml,"(.**)" .. asrtag .. ":(.**)}(._)")
--_,_,**,result,suf= string.find(xml,"(.**)_

&lt;input mode=\"speech\"&gt;

(.**)")
strt="mode=\"speech\">"
end1="

&lt;/input&gt;

"
a,b,result,d,e=string.find(xml, strt .. "(.**)" .. end1)
--freeswitch.consoleLog("CRIT", result .. "\n");

> strt1 ="confidence=\""
> ed="\">\n.**<input"
> a,b,confidence,d,e=string.find(xml, strt1 .. "(.**)" .. ed)
--freeswitch.consoleLog("CRIT", confidence .. "\n");

--regex="\\[" .. start .. "\\]\\s**(((?!\\[" .. start .. "\\]|\\[" .. end1 .. "\\]).)+)\\s**\\[" .. end1 .."\\]"
--regex="\\[" .. start .. "\\](.**?)\\[" .. end1 .. "\\]"
--regex = start .. "(.**?)" .. end1
--freeswitch.consoleLog("CRIT",regex .. "\n");
--_,_,result=string.find(xml,regex)
-- _,_,pre,confidence,suf = string.find(xml,"(.**)confidence=\"(.**)\"(.**)")**

--
--confidence = 99
> if (result == nil) then
> > freeswitch.consoleLog("CRIT","Result is 'nil'\n")
> > freeswitch.consoleLog("CRIT","Confidence is 'nil'\n")
> > session:streamFile(nohear)
> > tryagain = 1

> elseif (tonumber(confidence) < confidence\_threshold) then
> > freeswitch.consoleLog("CRIT","Result is '" .. result .. "'\n")
> > freeswitch.consoleLog("CRIT","Confidence is LOW '" .. confidence .. "'\n")
> > session:streamFile(nounderstand)
> > tryagain = 1

> else
> > freeswitch.consoleLog("CRIT","Result is '" .. result .. "'\n")
> > freeswitch.consoleLog("CRIT","Confidence is HIGH '" .. confidence .. "'\n")
> > prompt = "/home/ivr/" .. result .. ".pcm"
> > --    session:streamFile(prompt)


> tryagain = 0
> > end

> end
> --
> session:streamFile(forward)
> -- put logic to forward call here
> --
> session:streamFile(thankyou)
> session:sleep(250)
> session:streamFile(goodbye)
> session:hangup()

In the default.xml in dialplan add an entry


&lt;extension name="unimrcp"&gt;


> 

&lt;condition field="destination\_number" expression="^12345$"/&gt;


> 

&lt;action application="answer"/&gt;


> 

&lt;action application="lua" data="names.lua"/&gt;


> 

Unknown end tag for &lt;/condition&gt;




&lt;/extension&gt;



UNIMRCP CHANGES
In the /usr/local/unimrcp/conf do the following changes in the unimrcpserver.xml
> <!-- Factory of plugins (MRCP engines) -->
> > 

&lt;plugin-factory&gt;


> > > 

&lt;engine id="PocketSphinx-1" name="mrcppocketsphinx" enable="true"/&gt;



and add the follwing lines in the profiles '

&lt;mrcpv2-profile id="uni2"&gt;

 and 

&lt;mrcpv2-profile id="uni2"&gt;

' mentioned in the end
of the unimrcpserver.xml

> 

&lt;resource-engine-map&gt;


> > 

&lt;param name="speechsynth" value="Flite-1"/&gt;


> > 

&lt;param name="speechrecog" value="PocketSphinx-1"/&gt;


> > 

&lt;/resource-engine-map&gt;



Similarly, add the above lines in unimrcp.conf given at the directory /usr/local/unimrcp/conf/client-profiles.
In the data directory of the unimrcp add a new folder named 'coommunicator' and copy all the files(feat.params, mdef.txt, mdef, means, mixture\_weights, noisedict, sendump, transition\_matrices, variances) that are present in ur adapted acoustic model.
ex. while performing Adaptation the acoustic model the files will be pesent in hub4wsj\_sc\_8kadapt

Copy ur dictionary (a.dic file) to this 'data' direactory and edit the 'pocketsphinx.xml' in the 'conf' directory of unimrcp and change the parameter dictionary="default.dic" to dictionary="a.dic". Even change  

&lt;save-waveform dir="" enable="0"/&gt;

 to 

&lt;save-waveform dir="" enable="1"/&gt;

.

RUNNING THE APPLICATION
Run the unimrcpserver and call the extension using your softphone(ex. Twinkle).





# Introduction #

The Linksys SPA3102 Voice Gateway allows automatic routing of local calls from mobile phones and land lines to Voice over Internet Protocol (VoIP) service providers, and vice versa.
We have used it to route all our incoming calls to Freeswitch and then to the local pstn line. Freeswitch here records all the calls and if the call is not answered within 20 sec , transfers it to the IVR.


# Details #

SETTING UP SPA3102 :
<li>Freeswitch needs to be installed. For instructions on how to install freeswitch refer to the installation wiki.</li>
<li>To setup the linksys gateway follow the following steps :<br>
<li>disconnect your phone line and connect it to the line socket of the spa3102.</li>
<li>connect your phone to the phone socket of the spa3102</li>
<li>Use the ethernet cable to connect the SPA’s internet port up to a spare ethernet port on your home broadband router.</li>
<li>Now Dial  from the phone connected to the SPA and then press 1# to know the IP address of the linksys SPA.<br>
<a href='http://www.cisco.com/en/US/products/ps10024/products_qanda_item09186a0080a359dd.shtml'>http://www.cisco.com/en/US/products/ps10024/products_qanda_item09186a0080a359dd.shtml</a>
</li>
<li>Now open a browser and go to that IP address.<br>
The linksys page will open up.Edit the configuration setting under adminlogin -> advanced</li>
<li>Under VOICE  -> Line1 and VOICE -> PSTN line . In proxy and registration mention the IP of your Freeswitch ( i.e your own IP) and in subscriber information give a username, password. ( We gave<br>
LINE1 :<br>
Subscriber Information :<br>
Display Name:1006		User ID:1006<br>
Password:1234		Use Auth ID:1006<br>
Auth ID:1006<br>
<br>
and similarly in pstn give any username.<br>
<br>
</li>
<li>For all other settings refer to :<br>
<a href='http://www.4shared.com/file/22XUbpYM/linksys_configuration.html'>http://www.4shared.com/file/22XUbpYM/linksys_configuration.html</a>

these settings are for mtnl landline service </li>
In PSTN line -> Dialplan :<br>
The mentioned extension is that extension within freeswitch where you need to route all the incoming calls.<br>
</li>
<li>To record and transfer calls, add a dialplan SPA.xml in your /usr/local/freeswitch/conf/dialplan/default directory with the following content :<br>
<br>
<br>
<br>
<extension name="ext-1044"><br>
<br>
<br>
<blockquote>

<condition field="destination_number" expression="^4102000$">

<br>
<br>
<br>
<action application="set_audio_level" data="read 4"/><br>
<br>
<br>
</blockquote><blockquote>

<action application="set_audio_level" data="write 4"/>

<br>
<blockquote>

<action application="set" data="RECORD_TITLE=Recording ${destination_number} ${caller_id_number} ${strftime(%Y-%m-%d %H:%M)}"/>

<br>
<br>
<br>
<action application="set" data="RECORD_COPYRIGHT=(c) 1980 Factory Records, Inc."/><br>
<br>
<br>
<br>
<br>
<action application="set" data="RECORD_SOFTWARE=FreeSWITCH"/><br>
<br>
<br>
<br>
<br>
<action application="set" data="RECORD_ARTIST=Pooja"/><br>
<br>
<br>
<br>
<br>
<action application="set" data="RECORD_COMMENT= tap"/><br>
<br>
<br>
<br>
<br>
<action application="set" data="RECORD_DATE=${strftime(%Y-%m-%d %H:%M)}"/><br>
<br>
<br>
<br>
<br>
<action application="set" data="RECORD_STEREO=true"/><br>
<br>
<br>
<br>
<br>
<action application="record_session" data="/home/pooja/${strftime(%Y-%m-%d-%H-%M-%S)}_${destination_number}_${caller_id_number}.wav"/><br>
<br>
</blockquote></blockquote>

<blockquote>

<action application="set" data="ringback=${us-ring}"/>

<br>
<br>
<br>
<action application="set" data="hangup_after_bridge=true"/><br>
<br>
<br>
</blockquote><blockquote>

<action application="set" data="continue_on_fail=true"/>

<br>
<!-- this is needed to allow call_timeout to work after bridging to a gateway --><br>
<br>
<br>
<action application="set" data="ignore_early_media=true"/><br>
<br>
<br>
<!-- ring my desk extension for 10 seconds. --><br>
<br>
<br>
<action application="set" data="call_timeout=20"/><br>
<br>
<br>
<!--1006 is the routing destination --><br>
<br>
<br>
<action application="bridge" data="sofia/${domain}/1006%${domain}"/><br>
<br>
</blockquote>

<!-- if no answer by 1006 call ivr --><br>
<br>
<br>
<action application="lua" data="IIITD/optimized.lua" /><br>
<br>
<br>
<blockquote>

</condition>

<br>
<br>
<br>
</extension><br>
<br>
</blockquote>

</li>
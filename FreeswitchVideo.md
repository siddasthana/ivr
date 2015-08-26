# Introduction #

mod\_fsv implements functions to record and play back video in FreeSWITCH.


# Details #

To include mod\_fsv in freeswitch :
<li>edit modules.conf located in usr/local/src/freeswitch and uncomment applications/mod_fsv.</li>
<li>make freeswitch again by <b>make</b> and then <b>make install</b>.</li>
<li>check usr/local/freeswitch/conf/autoload_configs and make sure that mod_fsv module is loaded in file modules.conf.xml.</li>
<li>Include video codecs in freeswitch by editing vars.xml in usr/local/freeswitch/conf -<br>
<br>
<br>
<X-PRE-PROCESS cmd="set" data="global_codec_prefs=G7221@32000h,G7221@16000h,G722,PCMU,PCMA,GSM,H263,H263-1998,H264"/><br>
<br>
<br>
<br>
<br>
<X-PRE-PROCESS cmd="set" data="outbound_codec_prefs=PCMU,PCMA,GSM,H263,H263-1998,H264"/><br>
<br>
<br>
</li>
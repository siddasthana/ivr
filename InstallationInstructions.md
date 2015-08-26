<h1>Installation</h1>
<h3>Instructions to setup IVR System</h3>



<h2>Detailed Instructions for Ubuntu 11.04</h2>


<p><h3>Web Components</h3></p>
<li>Install Python, Java SDK, MySQL(and mysql header files libmysqlclient-dev, libmysqld-dev, libmysqlcppconn-dev)</li>
<li>Install Django (Package python-django in Synaptic Package Manager)</li>
<li>Install wadofstuff Django serializers (install python-setuptools then run cmd easy_install wadofstuff-django-serializers)</li>
<li>Install mysqldb python module (synaptics Package Manager : python mysqldb)</li>
<li>Create a mysql database called 'ivr', and a user 'ivr' and password 'ivr' with all privileges to it.</li>

<p><h3>Dev Environment</h3></p>
<li>Setup web components above</li>
<li>Install Eclipse</li>
<li>Install Subclipse eclipse plugin</li>
<li>Install GWT eclipse plugin</li>
<li>Checkout trunk/web into a new project Rendezvous_server. Optionally use python project plugin</li>
<li>Checkout trunk/IVR into a new project Rendezvous_IVR. Optionally use lua plugin</li>

<p><h3>Web Server</h3></p>
<li>Setup web components above</li>
<ul><li>Install Apache sudo apt-get install apache2</li></ul>
<li>Checkout trunk/web and place the code in a place you are comfortable with web server accessing it (a good place is /var/www/iiitd).<br>
</li>
<li>In the iiitd (i.e. /var/www/iiitd) directory, run 'python manage.py syncdb' to setup the mysql tables. </li>
<li>Install and configure mod_wsgi for your apache server(or Install libapache2-mod-wsgi from Synaptic for automatic installation and cofigure )</li>
<li>setup django project to interface with wsgi using these instructions(i.e. edit either httpd.conf or sites-available in /etc/apache2/ Directory)</li>
<li>Be sure that the paths in django.wsgi, settings.py, and the paths in your apache config file are all matched up</li>


<h3>IVR</h3>
<li>Download and install FreeSWITCH, with mod_shout enabled</li><ul>
<blockquote><li>Use Terminal cd /usr/local/src</li>
<li>sudo apt-get install git-core subversion build-essential autoconf automake libtool libncurses5 libncurses5-dev make libjpeg-dev</li>
<li>sudo apt-get install libcurl4-openssl-dev libexpat1-dev libgnutls-dev libtiff4-dev libx11-dev unixodbc-dev libssl-dev zlib1g-dev libzrtpcpp-dev libasound2-dev libogg-dev libvorbis-dev libperl-dev libgdbm-dev libdb-dev python-dev uuid-dev unixodbc-bin</li>
<li>sudo wget <a href='http://files.freeswitch.org/freeswitch-1.0.6.tar.gz'>http://files.freeswitch.org/freeswitch-1.0.6.tar.gz</a></li>
<li>sudo tar xvfz freeswitch-1.0.6.tar.gz</li>
<blockquote><li>cd /usr/local/src/freeswitch</li>
</blockquote><li>sudo gedit modules.conf</li>
<li>Change following lines (Remove hashes)</li><ul>
<blockquote><li>applications/mod_curl</li>
</blockquote><blockquote><li>asr_tts/mod_flite</li>
<li>formats/mod_shout</li></ul>
</blockquote><li>sudo./configure</li>
<li>sudo make all cd-sounds-install cd-moh-install</li>
<li>sudo ./make && make install</li></blockquote>

<blockquote><h4>If process(wget to last step) fails then remove both freeswitch-1.0.6.tar.gz and freeswitch-1.0.6 directory and then proceed to otherwise jump to installing Lua</h4></blockquote>

<blockquote><li>Use Terminal cd /usr/local/src</li>
</blockquote><blockquote><li>sudo git clone git://git.freeswitch.org/freeswitch.git</li>
<li>cd freeswitch</li>
<blockquote><li>sudo./bootstrap.sh</li>
</blockquote><li>sudo ./configure</li>
<li>sudo gedit modules.conf</li>
<li>Change following lines (Remove hashes)</li><ul>
<blockquote><li>applications/mod_curl</li>
</blockquote><blockquote><li>asr_tts/mod_flite</li>
<li>formats/mod_shout</li></ul>
<blockquote><li>sudo make</li>
</blockquote></blockquote><li>sudo make install</li>
<li>sudo make uhd-sounds-install</li>
<li>sudo make uhd-moh-install</li>
<li>sudo make samples</li></ul></blockquote>


<li>Download and install lua and luasql</li>
> <ul><li>luasql install from <a href='http://wiki.freeswitch.org/wiki/Installing_LuaSQL'>http://wiki.freeswitch.org/wiki/Installing_LuaSQL</a></li></ul>
<li>Open ports 5060, 5080 tcp and udp in server firewall</li><ul>
</li></ul><blockquote><li>sudo iptables -A INPUT -p tcp -d 0/0 -s 0/0 --dport 5060 -j ACCEPT</li>
> <li>sudo iptables -A INPUT -p tcp -d 0/0 -s 0/0 --dport 5080 -j ACCEPT</li>
> <li>sudo iptables -A INPUT -p udp -d 0/0 -s 0/0 --dport 5060 -j ACCEPT</li>
> <li>sudo iptables -A INPUT -p udp -d 0/0 -s 0/0 --dport 5080 -j ACCEPT</li></ul>
<li>Checkout trunk/IVR and drop the directory into /usr/local/freeswitch/scripts/IIITD (i.e. call the downloaded directory 'IIITD')</li>
<li>In FreeSWITCH's conf/dialplan/default directory, create a new dialplan for AO. Call it something like 001\_IIITD.xml, and make it look like this:
```
<extension name="incoming">
        <condition field="destination_number" expression="^30142000$">
            <action application="lua" data="IIITD/optimized.lua" />
        </condition>
 </extension>
```
The 'expression' attribute should correspond to your inbound PRI number or SIP extension (i.e. '5000', but make sure no other app is taking that extension (including in /dialplan/default.xml)). Default user ids are 1000, 1001, 1002, all with password 1234
<li>Create a DSN with name ivr for database ivr</li><ul>
<li>Install libmyodbc from Synaptic</li>
<li>In terminal type 'sudo ODBCConfig' without quote</li>
<pre><code> or use command 'ODBCManageDataSourcesQ4' without quote if ODBCConfig fails<br>
</code></pre>
<li>Create driver for MySql</li><ul>
<blockquote><li>In Driver select /usr/lib/odbc/libmyodbc.so</li>
<pre><code>for 64 bit machine path may be '/usr/lib/x86_64-linux-gnu/odbc'<br>
</code></pre>
<li>In Setup select /usr/lib/odbc/libodbcmyS.so</li></ul>
</blockquote><li>Create System DSN name = ivr database name = ivr and driver MySql</li></ul>
<li>Open /usr/local/freeswitch/scripts/IIITD/paths.lua search for term logfile and set the path where you have made a new file for logging.</li>
<p><h3>Test your installation</h3></p>
<li>Install Twinkle (a softphone, u can easily get in synaptic )</li>
<li>start your freeswitch (At terminal type"/usr/local/freeswitch/bin/freeswitch")</li>
<li>Create a profile with following parameter:</li>
<ul>domain=<Your Ip address or 127.0.0.1(If you are not on any network)></ul>
<ul>Authentication name(and user name) = any number between 1000 to 1019</ul>
<ul>password=1234</ul>
<li>In sytem settings change the sip port from 5060 to something else and RTP port from 8000 to some other port. So that it should not conflict with Freeswitch's SIP and RTP ports</li>
<li>Dial the number given in expression attribute of 0001_IIITD.xml</li>
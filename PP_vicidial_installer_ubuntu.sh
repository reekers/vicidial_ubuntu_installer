#!/bin/bash

# PP Vicidial server install script for a full box or dialer only
# Borrowed some stuff from Vicidial James opensuse script

# Some color scheme's
BLACK="tput setf 0"
BLUE="tput setf 1"
GREEN="tput setf 2"
CYAN="tput setf 3"
RED="tput setf 4"
MAGENTA="tput setf 5"
YELLOW="tput setf 6"
WHITE="tput setf 7"

User choices
function choice {
	CHOICE=''
	local prompt="$*"
	local answer
	read -p "$prompt" answer
	case "$answer" in
		[yY1] ) CHOICE='y';;
		[nN0] ) CHOICE='n';;
		*     ) CHOICE="$answer";;
	esac
}

# Simple user-feedback Function
function pause {
	read -p "`${YELLOW}`$*`${WHITE}`"
}

# The Do Or Die function! If we dont get a clean 0 exit code, consider it failed and bomb as such!
function doordie {
	eval $1
	
	if [ $? != 0 ]; then
		echo "`${RED}`ERROR! ERROR!  Something has gone horribly wrong! Processing stopped!`${WHITE}`"
		echo
		echo "Failure Area : `${MAGENTA}`$2`${WHITE}`"
		echo
		exit 1
	fi
}

echo
echo "Vicidial Installer for Ubuntu 9.04 server box"
echo 
echo "Please note that an Internet connection will be required for this script"
echo "to function."
echo
echo

choice "Do you want to continue? (y/N) : "

if [ "$CHOICE" == "y" ]; then # All code to run before here

echo
echo
echo
echo "OK. Now I will ask some simple set-up questions to determine how I should"
echo "be installed."
echo 

echo "It is highly recommend to update the base OS distribution with the updates"
echo "available for Ubuntu. If you want to run a newer kernel you will need"
echo "to recompile zaptel, wanpipe, and asterisk for the system to work."
echo
choice "Would you like to update the OS before installing ViciDial? (y/N) : "
OSUPD="$CHOICE"

choice "Will this server be used as a full box (dialer/database/webserver)? (y/N) : "
FULLBOX="$CHOICE"

if [ "$FULLBOX" == "n" ]; then
chioce "No full box, just a dialer is assumed. Is this correct? (y/N) : ";
DIALERONLY="$CHOICE"
fi

### Update OS
if [ "$OSUPD" == "y" ]; then
	echo
	echo "If during the OS Update a new kernel is downloaded then zaptel will fail compile."
	echo "You will need to reboot and re-run this script to continue installation."
	echo
	pause " --- Press Enter to continue or CTRL-C to exit ---"
	doordie "apt-get -y update" "Could not update the opereating system. Check that you are connected to the internet."
	doordie "apt-get -y --force-yes upgrade" "Could not upgrade the operating system. Check that you are connected to the internet."
	doordie "apt-get -y --force-yes linux-server" "Could not install linux-server. Check that you are connected to the internet."
fi

### Create working directory
mkdir -p /usr/src/astguiclient
cd /usr/src/astguiclient

### Lets run a basic internet sanity check before we get knee-deep in something else
doordie "wget http://download.vicidial.com/test.html" "Failed basic internet check! Check your network and/or internet connection!"

### Install pre-req's based on box type
# pre-req's for all box types
echo "Installing pre-reqs"
doordie "apt-get -y install ntp subversion nano findutils mlocate iftop irqbalance curl zip unzip libmysqlclient15-dev screen memtest86+ linux-source linux-headers-server libnewt-dev libmcrypt4 bison libncurses5-dev libusb-dev libcurl3 fxload libwww-curl-perl" "Could not add pre-requisite packages. Check that you are connected to the internet."
doordie "apt-get -y install libnet-daemon-perl libplrpc-perl libmysqlclient15off libdbd-mysql-perl mysql-common" "Could not add pre-requisite packages. Check that you are connected to the internet."
doordie "apt-get -y install sipsak lame mpg123 sox libsox-fmt-all madplay" " Coul not add sound requirements. Check that you are connected to the internet"
doordie "apt-get -y install linux-headers-$(uname -r) build-essential" "Could not add Kernel Development packages. Check that you are connected to the internet."
doordie "apt-get -y --force-yes install libmd5-perl libdigest-sha1-perl libterm-readline-perl-perl libdbi-perl libnet-telnet-perl libnet-server-perl libunicode-map8-perl libjcode-perl libspreadsheet-writeexcel-perl libole-storage-lite-perl libspreadsheet-parseexcel-perl libcurses-perl libgetopt-mixed-perl libnet-domain-tld-perl libmail-sendmail-perl" "Could not install CPAN packages. Check that you are connected to the internet."
# pre-req's full box only
if [ "$FULLBOX" == "y" ]; then
doordie "apt-get -y install apache2 apache2-mpm-prefork libploticus0-dev ploticus mytop mtop php5 php5-dev php5-cli php5-mcrypt php5-curl libapache2-mod-php5 mysql-server mysql-client php5-mysql php5-dev " "Could not install LAMP Server packages. Check that you are connected to the internet."
fi

# Create tar directory
mkdir -p /usr/src/tars
cd /usr/src/tars

### Download needed files
# Get files for all box types
if [ ! -f /usr/src/astguiclient/.gotfiles ]; then
doordie "wget http://192.168.0.223/repos/trunk.tar.gz" "Could not download trunk."
doordie "wget http://192.168.0.223/repos/ttyload.tar.gz" "Could not download ttyload.  Check that you are connected to the internet."
doordie "wget http://192.168.0.223/repos/asterisk-perl.tar.gz" "Could not download Asterisk PERL modules. Check that you are connected to the internet."
doordie "wget http://192.168.0.223/repos/asterisk-vici.tar.gz" "Could not download Asterisk v.1.4.21.2-vici. Check that you are connected to the internet."
doordie "wget http://192.168.0.223/repos/libpri.tar.gz" "Could not download libPRI. Check that you are connected to the internet."
doordie "wget http://192.168.0.223/repos/zaptel.tar.gz" "Could not download Zaptel. Check that you are connected to the internet."
doordie "wget http://192.168.0.223/repos/asterisk-core-sounds-en-ulaw-current.tar.gz" "Could not download Core ULAW sounds. Check that you are connected to the internet."
doordie "wget http://192.168.0.223/repos/asterisk-core-sounds-en-wav-current.tar.gz" "Could not download Core WAV sounds. Check that you are connected to the internet."
doordie "wget http://192.168.0.223/repos/asterisk-core-sounds-en-gsm-current.tar.gz" "Could not download core GSM sounds. Check that you are connected to the internet."
doordie "wget http://192.168.0.223/repos/asterisk-extra-sounds-en-wav-current.tar.gz" "Could not download extra WAV sounds. Check that you are connected to the internet."
doordie "wget http://192.168.0.223/repos/asterisk-extra-sounds-en-gsm-current.tar.gz" "Could not download extra GSM sounds. Check that you are connected to the internet."
doordie "wget http://192.168.0.223/repos/asterisk-moh-freeplay-gsm.tar.gz" "Could not download GSM MOH. Check that you are connected to the internet."
doordie "wget http://192.168.0.223/repos/asterisk-moh-freeplay-ulaw.tar.gz" "Could not download ULAW MOH. Check that you are connected to the internet."
doordie "wget http://192.168.0.223/repos/asterisk-moh-freeplay-wav.tar.gz" "Could not download WAV MOH. Check that you are connected to the internet."
touch /usr/src/astguiclient/.gotfiles
# Get files for full box
if [ "$FULLBOX" == "y" ]; then
doordie "wget http://192.168.0.223/repos/eaccelerator.tar.bz2"
fi
fi

# Unpack vici trunk
cd /usr/src/astguiclient
tar -xvf /usr/src/tars/trunk.tar.gz

# Install TTYLoad
cd /usr/src
tar -xzf tars/ttyload.tar.gz
cd /usr/src/ttyload-0.4.4
make
doordie "make install" "Could not compile TTY Load."
cd ../

# Give feedback about silly PERL compiling stuff
echo
echo
echo "PERL will need you to press enter twice as components are installed."
echo "You do not need to select anything just hit Enter."
echo
pause " --- Press Enter when ready to Continue; PERL Modules are being compiled next! --- "
# Give CPAN some silent settings; Make it as painless as possible
cd /tmp
wget http://192.168.0.223/repos/Config.pm
mv -f /tmp/Config.pm /etc/perl/CPAN/Config.pm
#doordie "cpan -i MD5 Digest::MD5 Digest::SHA1 readline" "Could not update CPAN pre-requisites."
#doordie "cpan -i Bundle::CPAN" "Could not update CPAN"
#doordie "cpan -fi Scalar::Util" "Could not install Scalar::UTIL"
#doordie "cpan -i DBI" "Could not install DBI"
#doordie "cpan -fi DBD::mysql" "Could not install DBD::mysql"
#doordie "cpan -fi Net::Telnet Time::HiRes Net::Server Switch Unicode::Map Jcode Spreadsheet::WriteExcel OLE::Storage_Lite Proc::ProcessTable IO::Scalar Spreadsheet::ParseExcel Curses Getopt::Long Net::Domain Mail::Sendmail" "Could not install ViciDial PERL Pre-Requisites"
doordie "cpan -i Time::HiRes Switch Proc::ProcessTable IO::Scalar "
### installing and configuring way more stuff here
# Set-up NTP with good defaults
cd /etc
if [ ! -f /usr/src/astguiclient/.ntpinstall ]; then
	doordie "wget http://192.168.0.223/repos/ntp-server.conf" "Could not download default ntp-server configuration.  Check that you are connected to the internet."
	mv -f ntp-server.conf ntp.conf
	/etc/init.d/ntp restart
	touch /usr/src/astguiclient/.ntpinstall
fi

# Insert and md5 into phpMyAdmin for a cookie value, it's funny like that
	COOKIEMD5="`date | md5sum | sed 's/ //g'`"
	cd /usr/share/htdocs/phpmyadmin
	sed "s/''; \/*/'${COOKIEMD5}'; \/*/" config.sample.inc.php > config.inc.php

# Get us some settings for MySQL that are Vici friendly
	cd /etc
	if [ ! -f /usr/src/astguiclient/.dbconfig ]; then
		doordie "wget http://192.168.0.223/repos/my-vici.cnf" "Could not download vicidial-specific my.cnf configuration. Check that you are connected to the internet."
		mv -f my-vici.cnf my.cnf
		touch /usr/src/astguiclient/.dbconfig
	fi
	
	# Start related services or restart if running
	/etc/init.d/apache2 restart
	/etc/init.d/mysql restart
	
	cd /usr/src
	tar -xvf tars/eaccelerator.tar.bz2
	cd eaccelerator-0.9.6-rc1
	phpize
	./configure
	make
	doordie "make install" "Could not install eaccelerator"
	
	# give better eaccel options
	cd /etc/php5/conf.d
	#sed 's/eaccelerator.shm_size=\"16\"/eaccelerator.shm_size=\"48\"/' eaccelerator.ini > temp
	touch temp
	echo extension="eaccelerator.so">>temp
	echo eaccelerator.shm_size="48">>temp
	echo eaccelerator.cache_dir="/var/cache/eaccelerator">>temp
	echo eaccelerator.enable="1">>temp
	echo eaccelerator.optimizer="1">>temp
	echo eaccelerator.check_mtime="1">>temp
	echo eaccelerator.debug="0">>temp
	echo eaccelerator.filter="">>temp
	echo eaccelerator.shm_max="0">>temp
	echo eaccelerator.shm_ttl="0">>temp
	echo eaccelerator.shm_prune_period="0">>temp
	echo eaccelerator.shm_only="0">>temp
	echo eaccelerator.compress="1">>temp
	echo eaccelerator.compress_level="9">>temp
	mv -f temp eaccelerator.ini
	
	# Some PHP mangling
	cd /etc/php5/apache2
	rm php.ini
	wget http://192.168.0.223/repos/php.ini
	
	if [ "$ARCH" == "x86_64" ]; then
		sed 's/extension_dir \= \/usr\/lib\/php5\/extensions/extension_dir \= \/usr\/lib64\/php5\/extensions/' php.ini > php.new
		mv -f php.new php.ini
	fi
	
	# Install Asterisk perl
	cd /usr/src
	tar -xzf tars/asterisk-perl-0.08.tar.gz
	cd /usr/src/asterisk-perl-0.08
	perl Makefile.PL
	make all
	make install
	cd ../
	
	# Set-up apache for recordings
	cd /etc/apache2/conf.d
	if [ ! -f vicirecord.conf ]; then
		wget http://192.168.0.223/repos/vicirecord.conf
	fi
	chown -R www-data /var/spool/asterisk/monitorDONE
	
	# Uncompress archives
	cd /usr/src
	doordie "tar -xzf /usr/src/tars/asterisk-vici.tar.gz" "Could not uncompress Asterisk archive."
	doordie "tar -xzf /usr/src/tars/libpri.tar.gz" "Could not uncompress libPRI archive."
	doordie "tar -xzf /usr/src/tars/zaptel.tar.gz" "Could not uncompress Zaptel archive."
	
	# Start Compiling
	cd /usr/src/libpri-1.4.10.1
	make clean
	make
	doordie "make install" "Could not install libPRI"

	# Compile Zaptel
	cd /usr/src/zaptel-1.4.12.9.svn.r4653
	make clean
	./configure
	make
	doordie "make install" "Could not install Zaptel"
	make config
	cd ..
	ln -s zaptel-1.4.12.9.svn.r4653 zaptel
	
	# Compile Asterisk finally
	cd /usr/src/asterisk-1.4.21.2
	make clean
	./configure
	doordie "make" "Could not compile Asterisk."
	make install
	
	if [ ! -f /usr/src/astguiclient/.astsamples ]; then
		make samples
		touch /usr/src/astguiclient/.astsamples
		ASTSAMPLES="y"
	fi
	
	# Set-up ramdrive recording and default sounds in ulaw/gsm/raw
	if [ ! -f /usr/src/astguiclient/.ramdrive ]; then
		echo "tmpfs   /var/spool/asterisk/monitor       tmpfs      rw                    0 0" >> /etc/fstab
		touch /usr/src/astguiclient/.ramdrive
	fi
	
	# Set the sounds in place
	cd /var/lib/asterisk/sounds
	tar -xzf /usr/src/tars/asterisk-core-sounds-en-gsm-current.tar.gz
	tar -xzf /usr/src/tars/asterisk-core-sounds-en-ulaw-current.tar.gz
	tar -xzf /usr/src/tars/asterisk-core-sounds-en-wav-current.tar.gz
	tar -xzf /usr/src/tars/asterisk-extra-sounds-en-gsm-current.tar.gz
	tar -xzf /usr/src/tars/asterisk-extra-sounds-en-ulaw-current.tar.gz
	tar -xzf /usr/src/tars/asterisk-extra-sounds-en-wav-current.tar.gz
	
	# Grab parking file, and convert audio to native formats
	wget http://192.168.0.223/repos/conf.gsm
	sox conf.gsm conf.wav
	sox conf.gsm -t ul conf.ulaw
	cp conf.gsm park.gsm
	cp conf.ulaw park.ulaw
	cp conf.wav park.wav
	cd /var/lib/asterisk
	ln -s moh mohmp3
	mkdir mohmp3
	cd mohmp3
	tar -xzf /usr/src/tars/asterisk-moh-freeplay-gsm.tar.gz
	tar -xzf /usr/src/tars/asterisk-moh-freeplay-ulaw.tar.gz
	tar -xzf /usr/src/tars/asterisk-moh-freeplay-wav.tar.gz
	rm CHANGES*
	rm LICENSE*
	rm .asterisk*
	mkdir /var/lib/asterisk/quiet-mp3
	cd /var/lib/asterisk/quiet-mp3
	sox ../mohmp3/macroform-cold_day.wav macroform-cold_day.wav vol 0.25
	sox ../mohmp3/macroform-cold_day.gsm macroform-cold_day.gsm vol 0.25
	sox -t ul -r 8000 -c 1 ../mohmp3/macroform-cold_day.ulaw -t ul macroform-cold_day.ulaw vol 0.25
	sox ../mohmp3/macroform-robot_dity.wav macroform-robot_dity.wav vol 0.25
	sox ../mohmp3/macroform-robot_dity.gsm macroform-robot_dity.gsm vol 0.25
	sox -t ul -r 8000 -c 1 ../mohmp3/macroform-robot_dity.ulaw -t ul macroform-robot_dity.ulaw vol 0.25
	sox ../mohmp3/macroform-the_simplicity.wav macroform-the_simplicity.wav vol 0.25
	sox ../mohmp3/macroform-the_simplicity.gsm macroform-the_simplicity.gsm vol 0.25
	sox -t ul -r 8000 -c 1 ../mohmp3/macroform-the_simplicity.ulaw -t ul macroform-the_simplicity.ulaw vol 0.25
	sox ../mohmp3/reno_project-system.wav reno_project-system.wav vol 0.25
	sox ../mohmp3/reno_project-system.gsm reno_project-system.gsm vol 0.25
	sox -t ul -r 8000 -c 1 ../mohmp3/reno_project-system.ulaw -t ul reno_project-system.ulaw vol 0.25
	sox ../mohmp3/manolo_camp-morning_coffee.wav manolo_camp-morning_coffee.wav vol 0.25
	sox ../mohmp3/manolo_camp-morning_coffee.gsm manolo_camp-morning_coffee.gsm vol 0.25
	sox -t ul -r 8000 -c 1 ../mohmp3/manolo_camp-morning_coffee.ulaw -t ul manolo_camp-morning_coffee.ulaw vol 0.25
	
	
	# See if we've already installed the crontab
	if [ ! -f /usr/src/astguiclient/.cronvici ]; then
		wget http://192.168.0.223/repos/cronvici
		crontab -l > rootcron
		cat cronvici >> rootcron
		crontab rootcron
		touch /usr/src/astguiclient/.cronvici
	fi
		
	# Put the init-script in place
	cd /etc/init.d
	doordie "wget http://192.168.0.223/repos/vicidial" "Could not download ViciDial init.d script. Check that you are connected to the internet."
	chmod +x /etc/init.d/vicidial
	update-rc.d -f vicidial defaults
	
	/etc/init.d/apache2 restart
	/etc/init.d/vicidial start
	
	cd /usr/src/astguiclient/trunk
	
	cd extras
	/usr/bin/mysql --execute="create database asterisk default character set utf8 collate utf8_unicode_ci;"
	/usr/bin/mysql asterisk --execute="GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES on asterisk.* TO cron@'%' IDENTIFIED BY '1234';"
	/usr/bin/mysql asterisk --execute="GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES on asterisk.* TO cron@localhost IDENTIFIED BY '1234';"
	/usr/bin/mysql asterisk --execute="\. ./MySQL_AST_CREATE_tables.sql"
	/usr/bin/mysql asterisk --execute="\. ./first_server_install.sql"
	/usr/share/astguiclient/ADMIN_area_code_populate.pl
	cp /usr/src/astguiclient/trunk/extras/performance_test_leads.txt /usr/share/astguiclient/LEADS_IN/
	/usr/share/astguiclient/VICIDIAL_IN_new_leads_file.pl --forcelistid=997 --forcephonecode=1
	mysql asterisk --execute="INSERT INTO vicidial_lists (list_id, list_name, active, list_description) VALUES ('997', 'Test List', 'N', 'Performance and Test List');"
	mysql asterisk --execute="UPDATE vicidial_users set pass='1234',full_name='Admin',user_level='9',user_group='ADMIN',phone_login='',phone_pass='',delete_users='1',delete_user_groups='1',delete_lists='1',delete_campaigns='1',delete_ingroups='1',delete_remote_agents='1',load_leads='1',campaign_detail='1',ast_admin_access='1',ast_delete_phones='1',delete_scripts='1',modify_leads='1',hotkeys_active='0',change_agent_campaign='1',agent_choose_ingroups='1',closer_campaigns='',scheduled_callbacks='1',agentonly_callbacks='0',agentcall_manual='0',vicidial_recording='1',vicidial_transfers='1',delete_filters='1',alter_agent_interface_options='1',closer_default_blended='0',delete_call_times='1',modify_call_times='1',modify_users='1',modify_campaigns='1',modify_lists='1',modify_scripts='1',modify_filters='1',modify_ingroups='1',modify_usergroups='1',modify_remoteagents='1',modify_servers='1',view_reports='1',vicidial_recording_override='DISABLED',alter_custdata_override='NOT_ACTIVE',qc_enabled='',qc_user_level='',qc_pass='',qc_finish='',qc_commit='',add_timeclock_log='1',modify_timeclock_log='1',delete_timeclock_log='1',alter_custphone_override='NOT_ACTIVE',vdc_agent_api_access='1',modify_inbound_dids='1',delete_inbound_dids='1',active='Y',download_lists='1',agent_shift_enforcement_override='DISABLED',manager_shift_enforcement_override='1',export_reports='1',delete_from_dnc='1',email='',user_code='',territory='' where user='6666';"
	touch /usr/src/astguiclient/.dbinstall
	cd ..
	
### What to run if we are all 3, skip the 7 keepalive since we aren't multi-server
if [ "$FULLBOX" == "y" ]; then
	if [ ! -f /usr/src/astguiclient/.viciinstall ]; then
		doordie "perl install.pl --web=/var/www --asterisk_server=1.4 --copy_sample_conf_files --active_keepalives=12345689" "Could not run ViciDial installer"
		/usr/share/astguiclient/ADMIN_update_server_ip.pl --old-server_ip=10.10.10.15
		touch /usr/src/astguiclient/.viciinstall
	fi
fi


if [ "$FULLBOX" == "n" ]; then
	if [ ! -f /usr/src/astguiclient/.viciinstall ]; then
		doordie "perl install.pl --web=/var/www --asterisk_server=1.4 --copy_sample_conf_files --active_keepalives=123468" "Could not run ViciDial installer"
		/usr/share/astguiclient/ADMIN_update_server_ip.pl --old-server_ip=10.10.10.15
		touch /usr/src/astguiclient/.viciinstall
	fi
fi
fi

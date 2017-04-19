#!/bin/bash

#############################################################################################
## Ubuntu 14 Install OSSEC                                                                ###
## Reference:  http://ossec-docs.readthedocs.io/en/latest/manual/installation/index.html  ###
#############################################################################################

#Test to ensure expected OS Distribution and Version
OSTEST=$(grep "Ubuntu 15.10" /etc/*release | wc -c)
if [ $OSTEST == 0 ]
then
echo "Incorrect Operating System - Expected Ubuntu 15.10"
exit 1
fi

#Test to ensure script is run as root
USERTEST=$(whoami)
if [ $USERTEST != "root" ]
then
echo "Incorrect Permissions - Run this script as root"
exit 1
fi

## Install Dependancies
apt-get -y install build-essential

## Download Package and Compare Hashes
cd /root
mkdir ossec_temp
cd /root/ossec_temp
wget -U ossec http://www.ossec.net/files/ossec-hids-2.8.1.tar.gz
wget -U ossec http://www.ossec.net/files/ossec-hids-2.8.1-checksum.txt
# NOTE: Update path to source fileas as needed to stay current
SHA1A="$(cat ossec-hids-2.8.1-checksum.txt | tail -1 | cut -d" " -f 2)"
SHA1B="$(sha1sum ossec-hids-2.8.1.tar.gz | cut -d" " -f 1)"
if [ $SHA1A != $SHA1B ]
then
echo "Download SHA1 Hash Check Failed"
echo $SHA1A
echo $SHA1B
exit 1
fi

## Extract the Package
tar -zxvf ossec-hids-*.tar.gz

## Configure preloaded-vars.conf as appropriate
## Reference http://ossec-docs.readthedocs.io/en/latest/manual/installation/install-source-unattended.html
cat << 'EOF' > /root/ossec_temp/ossec-hids-*/etc/preloaded-vars.conf
## Configuration for a Local OSSEC Install suitable for analyzing logs
## from another system
USER_LANGUAGE="en"     

# Suppress the confirmation messages 
USER_NO_STOP="y"

# USER_INSTALL_TYPE defines the installation type to
# be used during install. It can only be "local",
# "agent" or "server".
USER_INSTALL_TYPE="local"
#USER_INSTALL_TYPE="agent"
#USER_INSTALL_TYPE="server"

# USER_DIR defines the location to install ossec
USER_DIR="/var/ossec"

# If USER_ENABLE_ACTIVE_RESPONSE is set to "n",
# active response will be disabled.
USER_ENABLE_ACTIVE_RESPONSE="n"

# If USER_ENABLE_SYSCHECK is set to "y",
# syscheck will be enabled. Set to "n" to
# disable it.
USER_ENABLE_SYSCHECK="n"


# If USER_ENABLE_ROOTCHECK is set to "y",
# rootcheck will be enabled. Set to "n" to
# disable it.
USER_ENABLE_ROOTCHECK="n"

# If USER_UPDATE is set to anything, the update
# installation will be done.
USER_UPDATE="n"

# If USER_UPDATE_RULES is set to anything, the
# rules will also be updated.
USER_UPDATE_RULES="n"

### Server/Local Installation variables. ###

# USER_ENABLE_EMAIL enables or disables email alerting.
USER_ENABLE_EMAIL="n"

# USER_ENABLE_SYSLOG enables or disables remote syslog.
USER_ENABLE_SYSLOG="n"

# USER_ENABLE_FIREWALL_RESPONSE enables or disables
# the firewall response.
USER_ENABLE_FIREWALL_RESPONSE="n"

# Enable PF firewall (OpenBSD and FreeBSD only)
USER_ENABLE_PF="n"
EOF


## Install it
cd ossec-hids-*
./install.sh

## Clean up
cd /root/
rm -rf /root/ossec_temp 
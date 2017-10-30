#!/bin/bash

#################################################################################################
##### Amazon Linux Hardening Script                                                         #####
##### NOTE: This is an EXAMPLE Only. Modify as needed. Script assumes that one non-root     #####
##### User account named "User" exists.  See lines 94 and 102                               #####
##### https://www.kennethghartman.com                                                       #####
#################################################################################################

logfile=/tmp/setup.log
echo "START" > logfile
exec > $logfile 2>&1  # Log stdout and std to logfile in /tmp

# Script to configure typical Linux host after launchtime

# Check for root
[ "$(id -u)" -ne 0 ] && echo "Incorrect Permissions - Run this script as root" && exit 1

echo; echo "== Install Updates =="
yum -y update

echo; echo "== Turn on Process Accounting =="
chkconfig psacct on

echo; echo "Create a non-root user without sudo rights"
SSHUSR="User"
useradd $SSHUSR

echo; echo "== SET PASSWORD AGING CONTROLS =="
# PASS_MAX_DAYS Maximum number of days a password may be used.
# PASS_MIN_DAYS Minimum number of days allowed between password changes.
# PASS_WARN_AGE Number of days warning given before a password expires.
# PASS_MIN_LEN Minimum acceptable password length.
sed -i 's/\(^PASS_MAX_DAYS\s*\).*$/\1 90/' /etc/login.defs
sed -i 's/\(^PASS_MIN_DAYS\s*\).*$/\1 1/' /etc/login.defs
sed -i 's/\(^PASS_MIN_LEN\s*\).*$/\1 10/' /etc/login.defs
sed -i 's/\(^PASS_WARN_AGE\s*\).*$/\1 10/' /etc/login.defs

echo; echo "== CREATE SCRIPTS TO CONFIGURE FIREWALL =="
cat << 'EOF' > /root/config-firewall-block-outbound.sh
iptables -F
##--Allow inbound Loopback Traffic
iptables -A INPUT -i lo -j ACCEPT
##--Allow outbound Loopback Traffic
iptables -A OUTPUT -o lo -j ACCEPT
##--Allow inbound traffic to SSH (port 22)
iptables -A INPUT -p tcp -m tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
##--Allow inbound traffic to SMTP (port 25)
#iptables -A INPUT -p tcp -m tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
##--Allow inbound traffic to web server (80, 443)
#iptables -A INPUT -p tcp -m tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A INPUT -p tcp -m tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
##--Allow outbound SSH traffic (port 22)
iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
##--Drop all other inbound traffic
iptables -A INPUT -j DROP
##--Drop all other outbound traffic
iptables -A OUTPUT -j DROP
EOF

chmod 500 /root/config-firewall-block-outbound.sh

cat << 'EOF' > /root/config-firewall-allow-outbound.sh
iptables -F
##--Allow inbound Loopback Traffic
iptables -A INPUT -i lo -j ACCEPT
##--Allow inbound traffic to SSH (port 22)
iptables -A INPUT -p tcp -m tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
##--Allow inbound traffic to SMTP (port 25)
#iptables -A INPUT -p tcp -m tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
##--Allow inbound traffic to web server (80, 443)
#iptables -A INPUT -p tcp -m tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A INPUT -p tcp -m tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
##--Allow any Established Sessions Inbound
iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
##--Drop all other inbound traffic
iptables -A INPUT -j DROP
##--Allow all outbound traffic
iptables -A OUTPUT -j ACCEPT
EOF

chmod 500 //root/config-firewall-allow-outbound.sh

echo; echo "== ADD PUBLIC SSH Keys =="
mkdir /home/$SSHUSR/.ssh
chmod 700 /home/$SSHUSR/.ssh
chown $SSHUSR:$SSHUSR  /home/$SSHUSR/.ssh
touch  /home/$SSHUSR/.ssh/authorized_keys
chmod 600 /home/$SSHUSR/.ssh/authorized_keys
chown $SSHUSR:$SSHUSR  /home/$SSHUSR/.ssh/authorized_keys
## Add SSH Key
echo "ssh-rsa XXXX----YOUR-KEY-HERE----XXXX rsa-key-20170326" >> /home/$SSHUSR/.ssh/authorized_keys

echo; echo "== HARDEN SSH CONFIGURATION =="
##--REFERENCE: https://linux-audit.com/audit-and-harden-your-ssh-configuration/

##--Make a Copy of the Config File
cp /etc/ssh/sshd_config /root/sshd_config.bak

##--AllowTcpForwarding (YES --> NO)
echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config

##--ClientAliveCountMax (3 --> 2)
## Sets the number of	client alive messages (see below) which	may be sent without sshd(8) receiving any messages back from the client.
## If this threshold is reached while client alive messages are being sent, sshd will disconnect the client, terminating the session.
echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config

##--ClientAliveInterval (0 --> 60)
## This indicates the timeout in seconds. After x number of seconds, ssh server will send a message to the client asking for response.
## Deafult is 0 (server will not send message to client to check.).
##  Reference:  http://www.thegeekstuff.com/2011/05/openssh-options/
echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config

##--Compression (DELAYED --> NO)
echo "Compression no" >> /etc/ssh/sshd_config

##--LogLevel (INFO --> VERBOSE)
sed -i 's/#\?\(LogLevel\s*\).*$/\1 VERBOSE/' /etc/ssh/sshd_config

##--MaxAuthTries (6 --> 2)
##  Specifies the maximum number of authentication attempts permitted per connection.  Once the number of failures reaches half this
##  Value, additional failures	are logged.
echo "MaxAuthTries 2" >> /etc/ssh/sshd_config

##--MaxSessions (10 --> 2)
##  Specifies the maximum number of open shell, login or subsystem (e.g. sftp) sessions permitted per	network	connection.
echo "MaxSessions 2" >> /etc/ssh/sshd_config

##--Change LoginGraceTime  (120 --> 30)
sed -i 's/#\?\(LoginGraceTime\s*\).*$/\1 30/' /etc/ssh/sshd_config

##--Prevent root login
sed -i 's/#\?\(PermitRootLogin\s*\).*$/\1 no/' /etc/ssh/sshd_config

##--Change Port (22 --> 2222)
#sed -i 's/#\?\(Port\s*\).*$/\1 2222/' /etc/ssh/sshd_config

##--Change TCPKeepAlive (YES --> NO)
sed -i 's/#\?\(TCPKeepAlive\s*\).*$/\1 no/' /etc/ssh/sshd_config

##--Change UsePrivilegeSeparation (YES --> SANDBOX)
sed -i 's/#\?\(UsePrivilegeSeparation\s*\).*$/\1 SANDBOX/' /etc/ssh/sshd_config

##--Change X11Forwarding (YES --> NO)
sed -i 's/#\?\(X11Forwarding\s*\).*$/\1 no/' /etc/ssh/sshd_config

##--Change AllowAgentForwarding (YES --> NO)
echo "AllowAgentForwarding no" >> /etc/ssh/sshd_config

##--Allow only specific users to login via ssh
##  Usernames should be separated by space
##  You can use combination of all the Allow and Deny directivies.
##  It is processed in this order: DenyUsers, AllowUsers, DenyGroups, and finally AllowGroups
echo "AllowUsers $SSHUSR ec2-user" >> /etc/ssh/sshd_config

##--Force key-Based Authentication
sed -i 's/#\?\(PasswordAuthentication\s*\).*$/\1 no/' /etc/ssh/sshd_config
sed -i 's/#\?\(ChallengeResponseAuthentication\s*\).*$/\1 no/' /etc/ssh/sshd_config
sed -i 's/#\?AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config
service sshd restart

echo; echo "== Install Lynis =="
##--REFERENCE: https://cisofy.com/lynis/
yum -y install lynis

echo; echo "== ENABLE FIREWALL =="
/root/config-firewall-block-outbound.sh

echo "****Hardening Script Complete"
echo; echo "== SCRIPT COMPLETE"
echo; echo "== $0 has completed"


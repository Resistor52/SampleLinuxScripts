#!/bin/bash
# Install Lynis Community on CentOS, Fedora, RHEL
# Reference: https://packages.cisofy.com/community/#centos-fedora-rhel 
# Note: To get the most current version use:  git clone https://github.com/CISOfy/lynis
#       however you may not want Git on production systems

# TODO: Check for OS Type = CentOS, Fedora, RHEL & Check for Root

#Ensure dependencies are up-to-date.
yum update ca-certificates curl nss openssl

#Create the Repository
cat << EOF > /etc/yum.repos.d/cisofy-lynis.repo
[lynis]
name=CISOfy Software - Lynis package
baseurl=https://packages.cisofy.com/community/lynis/rpm/
enabled=1
gpgkey=https://packages.cisofy.com/keys/cisofy-software-rpms-public.key
gpgcheck=1
EOF

#Install Lynis 
yum makecache fast
yum -y install lynis

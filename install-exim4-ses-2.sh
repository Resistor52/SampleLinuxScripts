#!/bin/bash

#################################################################################################
##### Install EXim4 on Ubuntu 14 & Configure for AWS SES                                    #####
#####                                                                                       #####
##### NOTE: Change the Credentials in Line 89 to those provided per                         #####
##### http://docs.aws.amazon.com/ses/latest/DeveloperGuide/smtp-credentials.html            #####
##### Also fix the email addresses in line 99                                               #####
#################################################################################################

apt-get -y install exim4

cat << 'EOF' > /etc/exim4/update-exim4.conf.conf
dc_eximconfig_configtype='internet'
dc_other_hostnames='ubuntu'
dc_local_interfaces='127.0.0.1 ; ::1'
dc_readhost=''
dc_relay_domains=''
dc_minimaldns='false'
dc_relay_nets=''
dc_smarthost=''
CFILEMODE='644'
dc_use_split_config='true'
dc_hide_mailname=''
dc_mailname_in_oh='true'
dc_localdelivery='mail_spool'
EOF



cat << 'EOF' > /etc/exim4/exim4.conf
exim_path = /usr/sbin/exim4

.ifndef CONFDIR
CONFDIR = /etc/exim4
.endif

UPEX4CmacrosUPEX4C = 1

domainlist local_domains = MAIN_LOCAL_DOMAINS
domainlist relay_to_domains = MAIN_RELAY_TO_DOMAINS
hostlist relay_from_hosts = MAIN_RELAY_NETS

.ifndef MAIN_PRIMARY_HOSTNAME_AS_QUALIFY_DOMAIN
.ifndef MAIN_QUALIFY_DOMAIN
qualify_domain = ETC_MAILNAME
.else
qualify_domain = MAIN_QUALIFY_DOMAIN
.endif
.endif

# listen on all all interfaces?
.ifdef MAIN_LOCAL_INTERFACES
local_interfaces = MAIN_LOCAL_INTERFACES
.endif

.ifndef CHECK_RCPT_LOCAL_LOCALPARTS
CHECK_RCPT_LOCAL_LOCALPARTS = ^[.] : ^.*[@%!/|`#&?]
.endif

.ifndef CHECK_RCPT_REMOTE_LOCALPARTS
CHECK_RCPT_REMOTE_LOCALPARTS = ^[./|] : ^.*[@%!`#&?] : ^.*/\\.\\./
.endif

# always log tls_peerdn as we use TLS for outgoing connects by default
.ifndef MAIN_LOG_SELECTOR
MAIN_LOG_SELECTOR = +smtp_protocol_error +smtp_syntax_error +tls_certificate_verified +tls_peerdn
.endif

begin routers
send_via_ses:
driver = manualroute
domains = ! +local_domains
transport = ses_smtp
route_list = * email-smtp.us-east-1.amazonaws.com;

begin transports
ses_smtp:
driver = smtp
port = 587
hosts_require_auth = $host_address
hosts_require_tls = $host_address

begin retry
*                      *           F,2h,15m; G,16h,1h,1.5; F,4d,6h

begin authenticators
ses_login:
driver = plaintext
public_name = LOGIN
client_send = : AWS_SMPT_USER : AWS_SMTP_PASSWORD
EOF


update-exim4.conf
systemctl restart exim4.service

## Send Test Email
echo AWS-SES-MAIL-TEST | mail -r from@example.com -s TEST to@example.com

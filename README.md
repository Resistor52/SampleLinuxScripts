# Sample Linux Scripts
Here are some sample Linux Scripts that contain useful ideas for provisioning and configuring Linux Systems

* [harden-UbuntuServer14.sh](harden-UbuntuServer14.sh) - This is a sample script for hardening a Ubuntu 14 Server.  This needs to be revised for your specific use cases.  Particularly the firewall rules and the User Key.  See the comments in the file.
* [install-exim4-ses-2.sh](install-exim4-ses-2.sh) - This script will install Exim4 so that you can send emails from your server using AWS Simple Email Services.  You will need to provide your own SES SMTP Credentials.  See the comments in the script. My use case is alert emails to and from verified email accounts.  Be sure that you read up on SES before you use for other use cases, such as bulk emailing.
* [install-ossec.sh](install-ossec.sh) - This script installs OSSEC so that you can analyze security logs from another system.  You will need to modify the configuration for other use cases.

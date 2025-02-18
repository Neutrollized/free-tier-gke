#! /bin/bash

apt update
apt install -y tinyproxy

# https://serverfault.com/questions/1055510/tinyproxy-error-unable-to-connect-to-the-server-access-denied
grep -qxF 'Allow localhost' /etc/tinyproxy/tinyproxy.conf || echo 'Allow localhost' >>/etc/tinyproxy/tinyproxy.conf

# resolving "ERROR: Could not create log file /var/log/tinyproxy/tinyproxy.log.  Falling back to syslog logging"
chown -R root:tinyproxy /var/log/tinyproxy
chmod -R 770 /var/log/tinyproxy

systemctl restart tinyproxy

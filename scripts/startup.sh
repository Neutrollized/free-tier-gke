#! /bin/bash

apt update
apt install -y tinyproxy

# https://serverfault.com/questions/1055510/tinyproxy-error-unable-to-connect-to-the-server-access-denied
grep -qxF 'Allow localhost' /etc/tinyproxy/tinyproxy.conf || echo 'Allow localhost' >> /etc/tinyproxy/tinyproxy.conf
systemctl restart tinyproxy

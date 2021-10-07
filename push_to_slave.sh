#!/bin/sh -x

IF="~lion/.ssh/id_rsa"

scp -i $IF -o Port=13222 /opt/ext_radius/sbin/* lion@10.0.11.72:/opt/ext_radius/sbin/
scp -i $IF -o Port=13222 /opt/ext_radius/bin/* lion@10.0.11.72:/opt/ext_radius/bin/
scp -i $IF -o Port=13222 /opt/ext_radius/sql/* lion@10.0.11.72:/opt/ext_radius/sql/
scp -i $IF -o Port=13222 /var/www/html/ext_radius/* lion@10.0.11.72:/var/www/html/ext_radius/
scp -i $IF -o Port=13222 /opt/ext_radius/www/* lion@10.0.11.72:/opt/ext_radius/www/

cat /opt/ext_radius/etc/radius_options.pm | sed -e 's/THIS="10.0.11.71"/THIS="10.0.11.72"/' -e 's/REMOTE_DB_HOST="10.0.11.72"/REMOTE_DB_HOST="10.0.11.71"/' > /opt/ext_radius/etc/radius_options_remote.pm
scp -i $IF -o Port=13222 /opt/ext_radius/etc/radius_options_remote.pm lion@10.0.11.72:/opt/ext_radius/etc/radius_options.pm

ssh -i $IF -o Port=13222 lion@10.0.11.72 'sudo systemctl stop freeradius'
ssh -i $IF -o Port=13222 lion@10.0.11.72 'sudo systemctl stop coa_daemon'
ssh -i $IF -o Port=13222 lion@10.0.11.72 'sudo systemctl start freeradius'
ssh -i $IF -o Port=13222 lion@10.0.11.72 'sudo systemctl start coa_daemon'

#!/bin/sh -x

scp /opt/ext_radius/sbin/* 10.0.11.72:/opt/ext_radius/sbin/
scp /opt/ext_radius/bin/* 10.0.11.72:/opt/ext_radius/bin/
scp /opt/ext_radius/sql/* 10.0.11.72:/opt/ext_radius/sql/
scp /var/www/html/ext_radius/* 10.0.11.72:/var/www/html/ext_radius/
scp /opt/ext_radius/www/* 10.0.11.72:/opt/ext_radius/www/

cat /opt/ext_radius/etc/radius_options.pm | sed 's/THIS="10.0.11.71"/THIS="10.0.11.72"/' > /opt/ext_radius/etc/radius_options_remote.pm
scp /opt/ext_radius/etc/radius_options_remote.pm 10.0.11.72:/opt/ext_radius/etc/radius_options.pm

ssh 10.0.11.72 'sudo systemctl stop freeradius'
ssh 10.0.11.72 'sudo systemctl stop coa_daemon'
ssh 10.0.11.72 'sudo systemctl start freeradius'
ssh 10.0.11.72 'sudo systemctl start coa_daemon'

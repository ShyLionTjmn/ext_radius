#!/bin/sh

db_sum=`mysqldump --no-data --compact -uradius -pradius radius | sed 's/ AUTO_INCREMENT=[0-9]*//g' | md5sum`
if [ $? -ne 0 ]
then
  echo "Error getting db_sum"
  exit 1
fi


rdb_sum=`ssh 10.0.11.72 "mysqldump --no-data --compact -uradius -pradius radius" | sed 's/ AUTO_INCREMENT=[0-9]*//g' | md5sum`
if [ $? -ne 0 ]
then
  echo "Error getting db_sum"
  exit 1
fi

if [ "$db_sum" = "$rdb_sum" ]
then
  echo "DB ok"
else
  echo "DB DIFFER!"
fi

echo -n "/opt/ext_radius/etc/radius_options.pm"

opt_sum=`cat /opt/ext_radius/etc/radius_options.pm | grep -v 'THIS=' | md5sum`
if [ $? -ne 0 ]
then
  echo
  echo "Error getting sum for /opt/ext_radius/etc/radius_options.pm"
  exit 1
fi

opt_rsum=`ssh 10.0.11.72 "cat /opt/ext_radius/etc/radius_options.pm | grep -v 'THIS=' | md5sum"`
if [ $? -ne 0 ]
then
  echo
  echo "Error getting remote sum for /opt/ext_radius/etc/radius_options.pm"
  exit 1
fi

if [ "$opt_sum" = "$opt_rsum" ]
then
  echo " Ok"
else
  echo " DIFFER!"
fi

for file in /opt/ext_radius/sbin/* /opt/ext_radius/bin/* /opt/ext_radius/sql/* /opt/ext_radius/www/*
do
  echo -n $file
  sum=`md5sum $file`
  if [ $? -ne 0 ]
  then
    echo
    echo "Error getting sum for $file"
    exit 1
  fi
  rsum=`ssh 10.0.11.72 "md5sum $file"`
  if [ $? -ne 0 ]
  then
    echo
    echo "Error getting remote sum for $file"
    exit 1
  fi
  if [ "$sum" = "$rsum" ]
  then
    echo " Ok"
  else
    echo " DIFFER!"
  fi

done

for svc in freeradius coa_daemon
do
  echo "Service $svc"
  echo "  Local:  "`systemctl is-active $svc`
  echo "  Remote: "`ssh 10.0.11.72 "systemctl is-active $svc"`
done

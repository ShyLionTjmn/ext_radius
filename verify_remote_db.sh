#!/bin/sh

mysqldump --no-data --compact -uradius -pradius radius | sed 's/ AUTO_INCREMENT=[0-9]*//g' > /tmp/local_radius_db
if [ $? -ne 0 ]
then
  echo "Error getting local db"
  exit 1
fi


ssh 10.0.11.72 "mysqldump --no-data --compact -uradius -pradius radius" | sed 's/ AUTO_INCREMENT=[0-9]*//g' > /tmp/remote_radius_db
if [ $? -ne 0 ]
then
  echo "Error getting remote db"
  exit 1
fi

lsum=`cat /tmp/local_radius_db | md5sum`
rsum=`cat /tmp/remote_radius_db | md5sum`

if [ "$lsum" = "$rsum" ]
then
  echo "DB ok"
  exit
else
  diff -y /tmp/local_radius_db /tmp/remote_radius_db
fi

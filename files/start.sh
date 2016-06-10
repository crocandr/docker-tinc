#!/bin/bash

chmod 755 /etc/tinc/*/tinc-up*

for file in $( find /etc/tinc -iname "*-$SITENAME" )
do
  symlink="$( echo $file | sed s@-$SITENAME@@g )"
  ln -s $file $symlink
done

if [ ! -e /etc/tinc/$NETNAME/rsa_key.priv ]
then
  # generate key and insert into the host file automatically
  echo "" | tincd -n $NETNAME -K4096
fi

tincd -n $NETNAME -D

#/bin/bash

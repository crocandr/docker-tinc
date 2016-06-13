#!/bin/bash

chmod 755 /etc/tinc/*/tinc-up*

for file in $( find /etc/tinc -iname "*-$SITENAME" )
do
  symlink="$( echo $file | sed s@-$SITENAME@@g )"
  ln -f -s $file $symlink
done

if [ ! -e /etc/tinc/$NETNAME/rsa_key.priv ]
then
  # generate key and insert into the host file automatically
  echo "" | tincd -n $NETNAME -K4096
fi

# site conf - pub ip
PUBIP=$( curl -L http://ifconfig.co )
if [ ! -z "$PUBIP" ]
then
  sed -i "s@Address = .*@Address = $PUBIP@g" /etc/tinc/$NETNAME/hosts/$SITENAME
fi


# btsync for tinc host config sync
if [ $( grep -i BTSYNCKEY /etc/tinc/btsync.conf | wc -l ) -gt 0 ]
then
  if [ ! -z $SYNCKEY ]
  then
    key="$SYNCKEY"
  else
    key="$( /opt/btsync/btsync --generate-secret )"
  fi
  # change btsync conf
  sed -i s@--BTSYNCKEY--@$key@g /etc/tinc/btsync.conf
  sed -i s@--SITENAME--@$SITENAME@g /etc/tinc/btsync.conf
  sed -i s@--NETNAME--@$NETNAME@g /etc/tinc/btsync.conf
  echo -e "\n\nPLEASE COPY THIS BTSYNC KEY to the other hosts: $key \n\n"
  echo "$key" > /etc/tinc/btkey.txt
fi

#/opt/btsync/btsync --storage /opt/btsync/config --config /etc/tinc/btsync.conf
#/opt/btsync/btsync -c /etc/tinc/btsync.conf
#if [ ! -z $CONSULURL ]
#then
#  curl -X PUT -d "$PUBIP" $CONSULURL/v1/kv/tinc/$SITENAME/PUBIP
#  $SITEKEY="$( cat /etc/tinc/$NETNAME/rsa_key.priv )"
#  curl -X PUT -d "$SITEKEY" $CONSULURL/v1/kv/tinc/$SITENAME/SITEKEY
#  curl -X PUT -d "$SUBNET" $CONSULURL/v1/kv/tinc/$SITENAME/SUBNET
#fi

tincd -n $NETNAME -D

#/bin/bash

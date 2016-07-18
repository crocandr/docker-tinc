#!/bin/bash

CONFDIR="/etc/tinc"
TMPLDIR="templates/netname"

# site conf - pub ip
PUBIP=$( curl -L http://ifconfig.co )
if [ -z "$PUBIP" ]
then
  echo "I didnt get the public ip :("
  exit 1
fi

mkdir -p /etc/tinc/$NETNAME/hosts

# create site config
cp -f $CONFDIR/$TMPLDIR/hosts/site.tmpl $CONFDIR/$NETNAME/hosts/$SITENAME
sed -i s@--PUBIP--@$PUBIP@g $CONFDIR/$NETNAME/hosts/$SITENAME
sed -i s@--SUBNET--@$SUBNET@g $CONFDIR/$NETNAME/hosts/$SITENAME
# gen cert and insert into site config
if [ ! -e /etc/tinc/$NETNAME/rsa_key.priv ] || [ ! $( grep -i "rsa public key" /etc/tinc/$NETNAME/hosts/$SITENAME | wc -l ) -ge 1 ]
then
  # generate key and insert into the host file automatically
  echo "" | tincd -n $NETNAME -K4096
fi

# create tinc.conf
cp -f $CONFDIR/$TMPLDIR/tinc.conf.tmpl $CONFDIR/$NETNAME/tinc.conf
sed -i s@--SITENAME--@$SITENAME@g $CONFDIR/$NETNAME/tinc.conf
echo "" > /tmp/site.txt
for sitef in /etc/tinc/$NETNAME/hosts/*
do
  if [ ! $( echo $sitef | grep -i "$SITENAME" | wc -l ) -eq 1 ]
  then
    connline="$( grep RSITENAME $CONFDIR/$NETNAME/tinc.conf | sed s@^\#@@g )"
    siten=$( basename $sitef )
    echo $connline | sed s@--RSITENAME--@$siten@g >> /tmp/site.txt
  fi
done
sed -i '/RSITENAME/r /tmp/site.txt' $CONFDIR/$NETNAME/tinc.conf
#cat /tmp/site.txt >> $CONFDIR/$NETNAME/tinc.conf
rm -f /tmp/site.txt

# create tinc-up
cp -f $CONFDIR/$TMPLDIR/tinc-up.tmpl $CONFDIR/$NETNAME/tinc-up
sed -i s@--LANIP--@$LANIP@g $CONFDIR/$NETNAME/tinc-up
echo "" > /tmp/site.txt
for sitef in /etc/tinc/$NETNAME/hosts/*
do
  if [ ! $( echo $sitef | grep -i "$SITENAME" | wc -l ) -eq 1 ]
  then
    routeline="$( grep -i RSUBNET $CONFDIR/$NETNAME/tinc-up | sed s@^\#@@g )"
    rsubnet="$( egrep -i 'SUBNET.*=' $sitef | cut -f2 -d'=' | xargs )"
    rsiten=$( basename $sitef )
    echo $routeline | sed s@--RSUBNET--@$rsubnet@g | sed s@--RSITENAME--@$rsiten@g >> /tmp/site.txt
  fi
done
sed -i '/RSUBNET/r /tmp/site.txt' $CONFDIR/$NETNAME/tinc-up
#cat /tmp/site.txt >> $CONFDIR/$NETNAME/tinc-up
#rm -f /tmp/site.txt
chmod 755 $CONFDIR/$NETNAME/tinc-up


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

/opt/btsync/btsync --storage /opt/btsync/config --config /etc/tinc/btsync.conf

# force remove pid files
rm -f /var/run/tinc*pid
# start tinc
tincd -n $NETNAME -D

#/bin/bash

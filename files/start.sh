#!/bin/bash

CONFDIR="/etc/tinc"
TMPLDIR="/etc/tinc-templates"

NETNAME="site2site"

echo "STARTED: "$( date )

[ -z $PORT ] && { PORT=655; }
[ -z $ALWAYS_RENEW_KEYS ] && { ALWAYS_RENEW_KEYS="true"; }

# site conf - pub ip
if [ -z "$PUBADDR" ]
then
  PUBADDR=$( curl -s -L -k http://ifconfig.co || exit 1 )
  # failsafe PUBADDR
  [ $PUBADDR ] || PUBADDR=$( curl -s -L -k http://icanhazip.com || exit 1 )
  [ $PUBADDR ] || PUBADDR=$( curl -s -L -k http://ident.me || exit 1 )
  [ $PUBADDR ] || PUBADDR=$( curl -s -L -k http://eth0.me || exit 1 )
  
  [ -z "$PUBADDR" ] && { echo "Public ip not found :("; exit 1; }

  echo "Public IP: $PUBADDR"
fi

mkdir -p $CONFDIR/$NETNAME/hosts



if [ $ALWAYS_RENEW_KEYS == false ] && [ -f $CONFDIR/$NETNAME/hosts/$SITENAME ]
then
  echo "WARNING: found an old siteconfig, skipping key regeneration"
  echo "WARNING: be careful, if you change network config you have to delete all config file and do a full reconfiguration!"
else
  # create site config
  cp -f $TMPLDIR/templates/hosts/site.tmpl $CONFDIR/$NETNAME/hosts/$SITENAME
  sed -i s@--PUBADDR--@$PUBADDR@g $CONFDIR/$NETNAME/hosts/$SITENAME
  sed -i s@--PORT--@$PORT@g $CONFDIR/$NETNAME/hosts/$SITENAME
  sed -i s@--SUBNET--@$SUBNET@g $CONFDIR/$NETNAME/hosts/$SITENAME
fi

# create tinc.conf
cp -f $TMPLDIR/templates/tinc.conf.tmpl $CONFDIR/$NETNAME/tinc.conf
sed -i s@--SITENAME--@$SITENAME@g $CONFDIR/$NETNAME/tinc.conf
sed -i s@--PORT--@$PORT@g $CONFDIR/$NETNAME/tinc.conf
for sitef in $CONFDIR/$NETNAME/hosts/*
do
  if [ ! "$( basename $sitef )" == "$SITENAME" ]
  then
    connline="$( grep RSITENAME $CONFDIR/$NETNAME/tinc.conf | sed s@^\#@@g )"
    sitename=$( basename $sitef )
    echo $connline | sed s@--RSITENAME--@$sitename@g >> $CONFDIR/$NETNAME/tinc.conf
  fi
done

# create tinc-up
cp -f $TMPLDIR/templates/tinc-up.tmpl $CONFDIR/$NETNAME/tinc-up
sed -i s@--LANIP--@$LANIP@g $CONFDIR/$NETNAME/tinc-up
for sitef in $CONFDIR/$NETNAME/hosts/*
do
  if [ ! "$( basename $sitef )" == "$SITENAME" ]
  then
    routeline="$( grep -i RSUBNET $CONFDIR/$NETNAME/tinc-up | sed s@^\#@@g )"
    rsubnet="$( egrep -i 'SUBNET.*=' $sitef | cut -f2 -d'=' | xargs )"
    rsitename=$( basename $sitef )
    echo $routeline | sed s@--RSUBNET--@$rsubnet@g | sed s@--RSITENAME--@$rsitename@g >> $CONFDIR/$NETNAME/tinc-up 
  fi
done
chmod 755 $CONFDIR/$NETNAME/tinc-up

# private key file and private key check
privkey_err=0
[ $( grep -s -i "rsa private key" $CONFDIR/$NETNAME/rsa_key.priv | wc -l ) -ge 1 ] || { echo "private key not found in key file, creating new key..."; privkey_err=1; }

# public key check
pubkey_err=0
[ $( grep -s -i "rsa public key" $CONFDIR/$NETNAME/hosts/$SITENAME | wc -l ) -ge 1 ] || { echo "public key not found in site config, creating new key..."; pubkey_err=1; }

# gen cert and insert into site config
if [ $privkey_err -ne 0 ] || [ $pubkey_err -ne 0 ]
then
  # generate key and insert into the host file automatically
  echo "" | tincd -n $NETNAME -K4096
fi

# force remove pid files
rm -f /var/run/tinc*pid
# start tinc
tincd -n $NETNAME -D $EXTRA_PARAMS


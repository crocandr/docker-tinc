# MESH based Site2Site VPN with Tinc in Docker

## Info

  - https://www.tinc-vpn.org/

## Docker host

You have to enable TUN interface on your docker host.

```
modprobe tun
```

## Build

```
docker build -t croc/tinc .
```

## Run

The auto-config procedure:

  - start the tinc container on all site
  - wait some minutes to btsync syncronizes the host config between the nodes
  - stop the tinc container on all site
  - start the tinc container on all site


First start the *1st* container (site1):

```
docker run -tid --name=tinc --net=host --privileged -e SITENAME=site1 -e NETNAME=mycompany -e LANIP=192.168.1.254/24 -e SUBNET=192.168.1.0/24 -v /srv/tinc/config:/etc/tinc croc/tinc /opt/start.sh
```

If you don't define a `SYNCKEY` at the start, the Tinc container generates a btsync (Bittorrent Sync) key to syncronize the hosts folder. <br />
You can view this key with `docker logs tinc` or with `cat /srv/tinc/config/synckey.txt` command on docker host.

Example: `docker logs tinc | grep -i "sync key"`

```
PLEASE COPY THIS SYNC KEY to the other hosts: ADV4IAC6EJWLYMJUDNTYWDW572L3DG5HN
``` 

You have to define this synckey when you start next containers: 

*2nd*, 3rd... other containers (site2, site3 ....):

```
docker run -tid --name=tinc --net=host --privileged -e SITENAME=site2 -e LANIP=192.168.2.254/24 -e SUBNET=192.168.2.0/24 -e SYNCKEY=ADV4IAC6EJWLYMJUDNTYWDW572L3DG5HN -e NETNAME=mycompany -v /srv/tinc/config:/etc/tinc croc/tinc /opt/start.sh

docker run -tid --name=tinc --net=host --privileged -e SITENAME=site3 -e SYNCKEY=ADV4IAC6EJWLYMJUDNTYWDW572L3DG5HN -e NETNAME=mycompany -e LANIP=192.168.3.254/24 -e SUBNET=192.168.3.0/24 -e PUBIP=8.9.1.1 -v /srv/tinc/config:/etc/tinc croc/tinc /opt/start.sh

...
```

You have to use `--net=host` and `--privileged` parameters, because the conatiners needs the tun/tap interface on the docker host.

  - `/srv/tinc/config` stores your tinc config on your docker host
  - you have to define with `-e SYNCKEY=xyz.....` param the bittorrent sync key for host config sync on 2nd,3rd,4th... host (and if you restart the 1st host)
  - the `-e LANIP=...` defines the container's IP on your LAN network
  - the `-e SUBNET=...` defines your LAN network. You can use wider network address like `192.168.0.0/22` or `172.17.0.0/19` or something similar... This is your choice.
  - if you have multiple WAN connection or something other reason, you can override the automatic public ip finder mehanicsm with `-e PUBIP=8.9.1.1` parameter for your public IP



Don't forget the latest step! (check the 'Usage' chapter for more infos):

You have to restart every the tinc container on every host if the network doesn't work at the first time.

```
docker restart tinc
```

## Config

The `/opt/start.sh` script configure the tinc node on every start.

  - find the public ip
  - starts the bittorrent sync to sync the hosts config ( public IPs, Subnets, Keys )
  - configures the tinc and connect every node to every other nodes (full MESH, connect everybody to everbody )


## Usage

You have to stop and start every container on every site 2 times:

  - 1st time, the start script generates the default config, and the host's SSL key
  - 2nd time, the script reads the config of the other sites and generates the "network up" script

If you've added a new site, you have to restart (stop, wait some seconds, start) every Tinc container on every site to rewrite a config for the new site.

You can check the syncronized and rewrited site config on your docker host's folder, example in the /srv/tinc/config folder.



Good Luck!



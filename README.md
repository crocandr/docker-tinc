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
docker build -t my/tinc .
```

## PREConfig

You have to preconfig the tinc container with some template config files and others. Please copy these config files into a folder on the docker host.

```
mkdir /srv/tinc && cp -rf config /srv/tinc/config
```

Ok, now you can run the tinc vpn containers.

## Run

The auto-config procedure:

  - start the tinc container on all site
  - wait some minutes to btsync syncronizes the host config between the nodes
  - stop the tinc container on all site
  - start the tinc container on all site


First start the *1st* container (site1):

```
docker run -tid --name=tinc --net=host --privileged -e SITENAME=site1 -e NETNAME=mycompany -e LANIP=192.168.1.254/24 -e SUBNET=192.168.1.0/24 -v /srv/tinc/config:/etc/tinc my/tinc /opt/start.sh
```

If you don't define a `SYNCKEY` at the start, the Tinc container generates a btsync (Bittorrent Sync) key to syncronize the hosts folder. <br />
You can view this key with `docker logs tinc` or with `cat /srv/tinc/config/btkey.txt` command on docker host.

Example: `docker logs tinc`

```
PLEASE COPY THIS BTSYNC KEY to the other hosts: ADV4IAC6EJWLYMJUDNTYWDW572L3DG5HN
``` 

You have to define this synckey when you start next containers: 

*2nd*, 3rd... other containers (site2, site3 ....):

```
docker run -tid --name=tinc --net=host --privileged -e SITENAME=site2 -e LANIP=192.168.2.254/24 -e SUBNET=192.168.2.0/24 -e SYNCKEY=ADV4IAC6EJWLYMJUDNTYWDW572L3DG5HN -e NETNAME=mycompany -v /srv/tinc/config:/etc/tinc my/tinc /opt/start.sh

docker run -tid --name=tinc --net=host --privileged -e SITENAME=site3 -e SYNCKEY=ADV4IAC6EJWLYMJUDNTYWDW572L3DG5HN -e NETNAME=mycompany -e LANIP=192.168.3.254/24 -e SUBNET=192.168.3.0/24 -v /srv/tinc/config:/etc/tinc my/tinc /opt/start.sh

...
```

You have to use `--net=host` and `--privileged` parameters, because the conatiners needs the tun/tap interface on the docker host.

  - `/srv/tinc/config` stores your tinc config on your docker host
  - you have to define with `-e SYNCKEY=xyz.....` param the bittorrent sync key for host config sync on 2nd,3rd,4th... host (and if you restart the 1st host)
  - the `-e LANIP=...` defines the container's IP on your LAN network
  - the `-e SUBNET=...` defines your LAN network. You can use wider network address like `192.168.0.0/22` or `172.17.0.0/19` or something similar... This is your choice.

## Config

The `/opt/start.sh` script configure the tinc node on every start.

  - find the public ip
  - starts the bittorrent sync to sync the hosts config ( public IPs, Subnets, Keys )
  - configures the tinc and connect every node to every other nodes (full MESH, connect everybody to everbody )


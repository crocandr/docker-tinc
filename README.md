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

You can start the container from the image.


*1st* container (site1):

```
docker run -tid --name=tinc --net=host --privileged -e SITENAME=site1 -e NETNAME=mycompany -v /srv/tinc/config:/etc/tinc my/tinc /opt/start.sh
```

At the start, the Tinc container generates a btsync (Bittorrent Sync) key to syncronize the hosts folder.
You can view this key with `docker logs` or with `cat /srv/tinc/config/btkey.txt` command on docker host.

Example: `docker logs tinc`

```

PLEASE COPY THIS BTSYNC KEY to the other hosts: ADV4IAC6EJWLYMJUDNTYWDW572L3DG5HN

``` 

You have to define this key when you start next containers: 

*2nd*, 3rd... other containers (site2, site3 ....):

```
docker run -tid --name=tinc --net=host --privileged -e SITENAME=site2 -e SYNCKEY=ADV4IAC6EJWLYMJUDNTYWDW572L3DG5HN -e NETNAME=mycompany -v /srv/tinc/config:/etc/tinc my/tinc /opt/start.sh

docker run -tid --name=tinc --net=host --privileged -e SITENAME=site3 -e SYNCKEY=ADV4IAC6EJWLYMJUDNTYWDW572L3DG5HN -e NETNAME=mycompany -v /srv/tinc/config:/etc/tinc my/tinc /opt/start.sh

...
```

You have to use `--net=host` and `--privileged` parameters, because the conatiners needs the tun/tap interface on the docker host.

  - `/srv/tinc/config` stores your tinc config on your docker host
  - you have to define with `-e SYNCKEY=xyz.....` param the bittorrent sync key for host config sync on 2nd,3rd,4th... host (and if you restart the 1st host)

## Config

  - The start script in the docker container tries to find and define the public IP. Please check it.
  - You can change public IPs and local LAN Networks addresses on the docker host's `/srv/tinc/config/mycompany/hosts` folder

## Know bugs

### Start & Stop

You have to rerun the docker container after the stop.

```
docker stop tinc
docker start tinc
```

The docker container stands in exited status.

If you check `docker logs tinc` output, you see the problem about error.

```
...
A tincd is already running for net `mycompany' with pid 28.
```

So, you have to delete the container:

```
docker rm -v tinc
```

... and finally you have to run:

```
docker run ...
```


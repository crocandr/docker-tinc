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

## Run

You can start the container from the image.

```
docker run -tid --name=tinc --net=host --privileged -e SITENAME=site1 -e NETNAME=mycompany -v /srv/tinc/config:/etc/tinc my/tinc /bin/bash
```

You have to use `--net=host` and `--privileged` parameters, because the conatiners needs the tun/tap interface on the docker host.

  - `/srv/tinc/config` stores your tinc config on your docker host

## Config


Copy the basic config to the `/srv/tinc/config` path.

```
mkdir /srv/tinc && cp -rf config /srv/tinc/config
```

You have to change Public IP addresses for your sites in the hosts files in the `/srv/tinc/config/mycompany/hosts` folder.


You can change other default configs in the `/srv/tinc/config` folder on your host.


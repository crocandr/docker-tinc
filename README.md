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
  - synchronize the hosts file to all other sites (recommended way with `syncthing/syncthing` or `resilio/sync` container)
  - restart the tinc container on all site

I recommend to use docker-compose method on all sites, but here is a short example for docker run:

First start the *1st* container (site1):

```
docker run -tid --name=tinc --net=host --privileged -e SITENAME=site1 -e LANIP=192.168.1.254/24 -e SUBNET=192.168.1.0/24 -v /srv/tinc/config:/etc/tinc/site2site/hosts croc/tinc /opt/start.sh
```

*2nd*, 3rd... other containers (site2, site3 ....):

```
docker run -tid --name=tinc --net=host --privileged -e SITENAME=site2 -e LANIP=192.168.2.254/24 -e SUBNET=192.168.2.0/24 -v /srv/tinc/config:/etc/tinc/site2site/hosts croc/tinc /opt/start.sh

docker run -tid --name=tinc --net=host --privileged -e SITENAME=site3 -e LANIP=192.168.3.254/24 -e SUBNET=192.168.3.0/24 -e PUBADDR=8.9.1.1 -v /srv/tinc/config:/etc/tinc/site2site/hosts croc/tinc /opt/start.sh
...
```

You have to use `--net=host` and `--privileged` parameters, because the containers needs the tun/tap interface on the docker host.

  - `/srv/tinc/config` stores your tinc config on your docker host
  - the `-e LANIP=...` defines the container's IP on your LAN network
  - the `-e SUBNET=...` defines your LAN network. You can use wider network address like `192.168.0.0/22` or `172.17.0.0/19` or something similar... This is your choice.
  - if you have multiple WAN connection or something other reason, you can override the automatic public IP finder mechanism with `-e PUBADDR=8.9.1.1` parameter for your public IP



Don't forget the latest step! (check the 'Usage' chapter for more info):

You have to restart every the tinc container on every host if the network doesn't work at the first time.

```
docker restart tinc
```

### Docker-Compose

You can use `docker-compose` for starting the stack (tinc and sync solution), but do not forget the site specified config!
Change your docker-compose.yml on every site, for site-local config.

Example:

`docker-compose.yml`:
```
...
      SITENAME: "test-site"
      LANIP: "192.168.230.253/24"
      SUBNET: "192.168.230.0/19"
...
```

Start the stack (with sync):
```
docker-compose up -d
```

... and ...
  - configure the sync (resilio or syncthing or other)
  - wait for the first config sync while other site configs arrive to the all hosts (1-5-10 mins)
  - restart the tinc or the full stack with `docker-compose restart`

## Usage

You have to stop and start every container on every site 2 times:

  - 1st time, the start script generates the default config, and the host's SSL key
  - 2nd time, the script reads the config of the other sites and generates the "network up" script

If you've added a new site, you have to restart (stop, wait some seconds, start) every Tinc container on every site to rewrite a config for the new site.

You can check the syncronized and rewritten site config on your docker host's folder, example in the `/srv/tinc/config` folder.


DO NOT FORGET: Sync the config of the hosts/sites from the docker host'si! (example: `/srv/tinc/config` folder)


## Extra parameters 

  - `EXTRA_PARAMS` - You can use this parameter if you would like to run tinc in debug mode (example: `-d 3` ) or something similar.
  Check the man page of tinc, and use that parameter.
  - `PORT` - tinc uses 655 tcp and udp port by default. You can change this with this paramter. If you use tinc behind a firewall, do not forget to forward this port to the tinc server. (Tinc use udp by default, but it is not availble automatically changes to tcp mode)

## Extra stuff

### Git-syncer

I recommend sync the Tinc's config files with Resilio or Syncthing BitTorrent based sync tools (more simpler and easier), but I've written a Git-based sync container.
This is a basic container that will be upload and download the Tinc's config to a Git repo (Github, Bitbucket, Gogs, Gitlab, etc.)

Copy the `docker-compose_gitsyncer.yml` compose file to docker-compose.yml and chage the parameters (for tinc and for the git repo too!)

When the tinc stack is started, the git-syncer container will be uploading the latest site config to the Git repository.
Sorry, but this is not a daemon! You have to restart this container or the stack (`docker-compose restart`) when the site config was changed.
This is restart is the biggest disadvantage, and I think is not to stable for a long time.
I strongly recommend, use another sync method to syncronize Tinc's config files.




Check my Github page and Wiki site for more information and examples.

Good Luck!

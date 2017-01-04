FROM ubuntu:xenial

RUN apt-get update && apt-get install -y tinc vim tar less ifupdown net-tools curl unzip

# btsync for config sync
#RUN curl -L -o /opt/btsync.tar.gz https://download-cdn.getsync.com/stable/linux-x64/BitTorrent-Sync_x64.tar.gz
RUN curl -L -o /opt/resilio.tar.gz https://download-cdn.resilio.com/stable/linux-x64/resilio-sync_x64.tar.gz
RUN mkdir /opt/resilio
RUN tar xzf /opt/resilio.tar.gz -C /opt/resilio

# template files copy
COPY config /etc/tinc-templates

COPY files/start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

VOLUME /etc/tinc

#ENTRYPOINT /opt/start.sh

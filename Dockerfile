FROM ubuntu:xenial

RUN apt-get update && apt-get install -y tinc vim tar less ifupdown net-tools

COPY files/start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

VOLUME /etc/tinc

#ENTRYPOINT /opt/start.sh

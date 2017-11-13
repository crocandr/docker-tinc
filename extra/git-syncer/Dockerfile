FROM ubuntu:xenial

RUN apt-get update && apt-get install -y git rsync

COPY files/start.sh /opt/start.sh
RUN chmod 755 /opt/*.sh

ENTRYPOINT /opt/start.sh

FROM ubuntu

RUN apt-get update && apt-get install -y tinc vim tar

COPY files/start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

VOLUME /etc/tinc

#ENTRYPOINT /opt/start.sh

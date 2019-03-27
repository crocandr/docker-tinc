FROM archlinux/base

RUN pacman -Sy --noconfirm tinc vim tar less net-tools curl unzip

# template files copy
COPY config /etc/tinc-templates

COPY files/start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

VOLUME /etc/tinc

ENTRYPOINT /opt/start.sh

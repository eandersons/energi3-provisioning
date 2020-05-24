FROM ubuntu:latest

RUN apt-get update && apt-get upgrade --assume-yes &&\
 apt-get install --assume-yes curl git less logrotate nano wget

WORKDIR /root

RUN ["git", "clone", "https://github.com/eandersons/energi3-provisioning.git"]

WORKDIR energi3-provisioning/scripts/linux/setup

# Install Energi3 Core Node
RUN chmod +x energi3-setup-install.sh && ./energi3-setup-install.sh

# Install Energi3 Core Node Monitor
COPY --chown=root:root ["configs/nodemon.conf", "/var/multi-masternode-data/nodebot/"]
RUN cp /root/energi3/bin/nodemon.sh /var/multi-masternode-data/nodebot/ &&\
 echo "*/1 * * * * /bin/bash -i\
 /var/multi-masternode-data/nodebot/nodemon.sh cron" >\
 /etc/cron.d/energi3_core_node_monitor

WORKDIR /root/energi3-provisioning/Docker

RUN ["chmod", "+x", "energi3-core-run.sh"]

# https://github.com/energicryptocurrency/energi3/blob/master/Dockerfile
# https://github.com/energicryptocurrency/energi3/blob/master/containers/docker/master-ubuntu/Dockerfile
EXPOSE 39795
EXPOSE 39796
EXPOSE 39797/tcp
EXPOSE 39797/udp

ENTRYPOINT ["./energi3-core-run.sh"]

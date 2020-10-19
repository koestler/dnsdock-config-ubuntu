FROM ubuntu:20.04
RUN apt-get update && apt-get --no-install-recommends -y install network-manager iptables iproute2

COPY ./entrypoint.sh /entrypoint.sh

CMD ["/entrypoint.sh"]

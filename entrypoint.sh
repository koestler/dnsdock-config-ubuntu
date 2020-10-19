#!/bin/bash

set -e

echo "This is the ubuntu dnsdock configuration service"

DNSDOCK_LINK=`ip a | grep 172.16.53.1 | grep -oE '[^ ]+$'`
echo "dnsdock network interface is: $DNSDOCK_LINK"

iptables_remove_rules() {
    echo "delete iptables rules made by dnsdock-config"
    iptables -S        | grep "dnsdock" | sed 's/^-A//' | while read rule; do iptables -D $rule; done
}

iptables_add_rules() {
    echo "add iptable rules (add dnsdock-config as comment)"

    iptables -I DOCKER-USER -s 172.16.53.2/32 \
             -j ACCEPT \
             -m comment --comment "dnsdock-config"

    iptables -I DOCKER-USER -d 172.16.53.2/32 \
             -j ACCEPT \
             -m comment --comment "dnsdock-config"
}

resolvectl_config() {
    echo "set resolve config"

    resolvectl dns $DNSDOCK_LINK 172.16.53.2
    resolvectl domain $DNSDOCK_LINK "~docker"
}

iptables_remove_rules
iptables_add_rules
resolvectl_config

echo "use nmcli to monitor network changes"

nmcli device monitor | while read LOGLINE
do
    # whenever "conneected" or "disconnected" is found, make sure our resolve config is applied since
    # the network managers seems to clear it whenever a new interface is connected
    echo "new line: $LOGLINE"
    if grep -qE "(dis)?connected" <<< "$LOGLINE"; then
        resolvectl_config
        # there might be some changes triggered by ipv6 dns beeing advertised later; wait 5s and run the config again
        sleep 3
        resolvectl_config
    fi
done

echo "finish"

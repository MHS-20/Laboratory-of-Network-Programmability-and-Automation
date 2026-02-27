#!/bin/bash
sudo ip netns add H1
sudo ip netns add H2
sudo ip netns add H3
sudo ip netns add H4
sudo ip netns add R1

sudo ovs-vsctl add-br SW1

# H1
sudo ip link add veth1 address 00:00:00:11:11:11 type veth peer name eth-H1
sudo ip link set veth1 netns H1
sudo ip netns exec H1 ip link set veth1 up
sudo ovs-vsctl add-port SW1 eth-H1
sudo ip link set eth-H1 up

# H2
sudo ip link add veth2 address 00:00:00:12:12:12 type veth peer name eth-H2
sudo ip link set veth2 netns H2
sudo ip netns exec H2 ip link set veth2 up
sudo ovs-vsctl add-port SW1 eth-H2
sudo ip link set eth-H2 up

# H3
sudo ip link add veth3 address 00:00:00:21:21:21 type veth peer name eth-H3
sudo ip link set veth3 netns H3
sudo ip netns exec H3 ip link set veth3 up
sudo ovs-vsctl add-port SW1 eth-H3
sudo ip link set eth-H3 up

# H4
sudo ip link add veth4 address 00:00:00:22:22:22 type veth peer name eth-H4
sudo ip link set veth4 netns H4
sudo ip netns exec H4 ip link set veth4 up
sudo ovs-vsctl add-port SW1 eth-H4
sudo ip link set eth-H4 up

# ROUTER R1
sudo ip link add veth-R1-1 address 00:00:00:aa:aa:aa type veth peer name eth-R1-1
sudo ip link set veth-R1-1 netns R1
sudo ip netns exec R1 ip link set veth-R1-1 up
sudo ovs-vsctl add-port SW1 eth-R1-1
sudo ip link set eth-R1-1 up

sudo ip link add veth-R1-2 address 00:00:00:bb:bb:bb type veth peer name eth-R1-2
sudo ip link set veth-R1-2 netns R1
sudo ip netns exec R1 ip link set veth-R1-2 up
sudo ovs-vsctl add-port SW1 eth-R1-2
sudo ip link set eth-R1-2 up

sudo ip link set SW1 up

# IP ADDRESSES
sudo ip netns exec H1 ip addr add 10.0.1.1/24 dev veth1
sudo ip netns exec H2 ip addr add 10.0.1.2/24 dev veth2
sudo ip netns exec H3 ip addr add 10.0.2.1/24 dev veth3
sudo ip netns exec H4 ip addr add 10.0.2.2/24 dev veth4
sudo ip netns exec R1 ip addr add 10.0.1.254/24 dev veth-R1-1
sudo ip netns exec R1 ip addr add 10.0.2.254/24 dev veth-R1-2

# IP FORWARDING
sudo ip netns exec R1 sysctl -w net.ipv4.ip_forward=1

# at level two, at start the destination MAC is the one of the router, 
# so the switch will forward the packet to the router,
# then it will be updated to the one of the destination host
# but at lelvel three, the destination IP is always the one of the destination host

# at the same time, when going into the other network, 
# the source MAC will be updated to the one of the router, 
# but the source IP is always the one of the source host

# DEFAULT GATEWAY
sudo ip netns exec H1 ip route add default via 10.0.1.254
sudo ip netns exec H2 ip route add default via 10.0.1.254
sudo ip netns exec H3 ip route add default via 10.0.2.254
sudo ip netns exec H4 ip route add default via 10.0.2.254

# TEST CONNECTIVITY
sudo ip netns exec H1 ping 10.0.1.2
sudo ip netns exec H1 ping 10.0.2.1
sudo ip netns exec H1 ping 10.0.2.2
# USING NAT
ip netns add H11
ip netns add H12
ip netns add H21
ip netns add H22
ip netns add R1
ovs-vsctl add-br SW1
ovs-vsctl add-br SW2

ip link add veth0 address "00:00:00:11:11:11" type veth peer name eth-H11
ip link set veth0 netns H11
ip netns exec H11 ip link set veth0 up
ovs-vsctl add-port SW1 eth-H11
ip link set eth-H11 up

ip link add veth0 address "00:00:00:12:12:12" type veth peer name eth-H12
ip link set veth0 netns H12
ip netns exec H12 ip link set veth0 up
ovs-vsctl add-port SW1 eth-H12
ip link set eth-H12 up

ip link add veth0 address "00:00:00:21:21:21" type veth peer name eth-H21
ip link set veth0 netns H21
ip netns exec H21 ip link set veth0 up
ovs-vsctl add-port SW2 eth-H21
ip link set eth-H21 up

ip link add veth0 address "00:00:00:22:22:22" type veth peer name eth-H22
ip link set veth0 netns H22
ip netns exec H22 ip link set veth0 up
ovs-vsctl add-port SW2 eth-H22
ip link set eth-H22 up

ip link add veth1 address "00:00:00:aa:aa:aa" type veth peer name eth-N1
ip link set veth1 netns R1
ip netns exec R1 ip link set veth1 up
ovs-vsctl add-port SW1 eth-N1
ip link set eth-N1 up

ip link add veth2 address "00:00:00:bb:bb:bb" type veth peer name eth-N2
ip link set veth2 netns R1
ip netns exec R1 ip link set veth2 up
ovs-vsctl add-port SW2 eth-N2
ip link set eth-N2 up

ip netns exec H11 ip addr add 10.0.1.1/24 dev veth0
ip netns exec H12 ip addr add 10.0.1.2/24 dev veth0

ip netns exec H21 ip addr add 192.168.0.1/24 dev veth0
ip netns exec H22 ip addr add 192.168.0.2/24 dev veth0

ip netns exec R1 ip addr add 10.0.1.254/24 dev veth1 
ip netns exec R1 ip addr add 192.168.0.254/24 dev veth2

ip netns exec R1 sysctl -w net.ipv4.ip_forward=1
ip netns exec R1 iptables -t nat -A POSTROUTING -o eth-N2 -j MASQUERADE # bidirectional
ip netns exec R1 iptables -t nat -o veth1 -A POSTROUTING -o eth-N2 -j MASQUERADE # only on one side

ip netns exec H11 ip route add default via 10.0.1.254
ip netns exec H12 ip route add default via 10.0.1.254
ip netns exec H21 ip route add default via 192.168.0.254
ip netns exec H22 ip route add default via 192.168.0.254
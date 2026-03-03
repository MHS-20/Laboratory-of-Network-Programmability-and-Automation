#!/bin/bash

# ── Namespaces ────────────────────────────────────────────
ip netns add H11
ip netns add H12
ip netns add H21
ip netns add H22
ip netns add R1
ip netns add R2
ip netns add R3

# ── Switches ──────────────────────────────────────────────
ovs-vsctl add-br SW1
ovs-vsctl add-br SW2

# ── Hosts on SW1 ──────────────────────────────────────────
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

# ── Hosts on SW2 ──────────────────────────────────────────
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

# ── R1 ↔ SW1 ──────────────────────────────────────────────
ip link add veth-R1-sw address "00:00:00:aa:aa:aa" type veth peer name eth-R1-sw
ip link set veth-R1-sw netns R1
ip netns exec R1 ip link set veth-R1-sw up
ovs-vsctl add-port SW1 eth-R1-sw
ip link set eth-R1-sw up

# ── R2 ↔ SW2 ──────────────────────────────────────────────
ip link add veth-R2-sw address "00:00:00:bb:bb:bb" type veth peer name eth-R2-sw
ip link set veth-R2-sw netns R2
ip netns exec R2 ip link set veth-R2-sw up
ovs-vsctl add-port SW2 eth-R2-sw
ip link set eth-R2-sw up

# ── R1 ↔ R3 (192.168.0.0/30) ─────────────────────────────
ip link add veth-R1-R3 address "00:00:00:cc:cc:01" type veth peer name veth-R3-R1 address "00:00:00:cc:cc:02"
ip link set veth-R1-R3 netns R1
ip link set veth-R3-R1 netns R3
ip netns exec R1 ip link set veth-R1-R3 up
ip netns exec R3 ip link set veth-R3-R1 up

# ── R2 ↔ R3 (192.168.0.4/30) ─────────────────────────────
ip link add veth-R2-R3 address "00:00:00:dd:dd:01" type veth peer name veth-R3-R2 address "00:00:00:dd:dd:02"
ip link set veth-R2-R3 netns R2
ip link set veth-R3-R2 netns R3
ip netns exec R2 ip link set veth-R2-R3 up
ip netns exec R3 ip link set veth-R3-R2 up

# ── IP Addresses ──────────────────────────────────────────
# Hosts
ip netns exec H11 ip addr add 10.0.1.1/24 dev veth0
ip netns exec H12 ip addr add 10.0.1.2/24 dev veth0
ip netns exec H21 ip addr add 10.0.2.1/24 dev veth0
ip netns exec H22 ip addr add 10.0.2.2/24 dev veth0

# R1
ip netns exec R1 ip addr add 10.0.1.254/24   dev veth-R1-sw   # LAN side → SW1
ip netns exec R1 ip addr add 192.168.0.1/30  dev veth-R1-R3   # WAN side → R3

# R2
ip netns exec R2 ip addr add 10.0.2.254/24   dev veth-R2-sw   # LAN side → SW2
ip netns exec R2 ip addr add 192.168.0.5/30  dev veth-R2-R3   # WAN side → R3

# R3
ip netns exec R3 ip addr add 192.168.0.2/30  dev veth-R3-R1   # toward R1
ip netns exec R3 ip addr add 192.168.0.6/30  dev veth-R3-R2   # toward R2

# ── IP Forwarding ─────────────────────────────────────────
ip netns exec R1 sysctl -w net.ipv4.ip_forward=1
ip netns exec R2 sysctl -w net.ipv4.ip_forward=1
ip netns exec R3 sysctl -w net.ipv4.ip_forward=1

# ── NAT ───────────────────────────────────────────────────
ip netns exec R1 iptables -t nat -A POSTROUTING -o veth-R1-R3 -j MASQUERADE
ip netns exec R2 iptables -t nat -A POSTROUTING -o veth-R2-R3 -j MASQUERADE

# ── Routing ───────────────────────────────────────────────
# Hosts: default GW = their local router
ip netns exec H11 ip route add default via 10.0.1.254
ip netns exec H12 ip route add default via 10.0.1.254
ip netns exec H21 ip route add default via 10.0.2.254
ip netns exec H22 ip route add default via 10.0.2.254

# R1: unknown traffic → R3
ip netns exec R1 ip route add default via 192.168.0.2

# R2: unknown traffic → R3
ip netns exec R2 ip route add default via 192.168.0.6

# R3: explicit routes to each LAN
ip netns exec R3 ip route add 10.0.1.0/24 via 192.168.0.1   # via R1
ip netns exec R3 ip route add 10.0.2.0/24 via 192.168.0.5   # via R2

# ── Test Connectivity ─────────────────────────────────────
ip netns exec H11 ping -c3 10.0.1.2    # H11 → H12 (same LAN)
ip netns exec H11 ping -c3 10.0.2.1    # H11 → H21 (cross LAN)
ip netns exec H11 ping -c3 10.0.2.2    # H11 → H22 (cross LAN)
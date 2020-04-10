#!/bin/bash

# enable debug output for each executed command
# to disable: set +x
set -x
# exit if any command fails
set -e

# Mount the bpf filesystem
sudo mount -t bpf bpf /sys/fs/bpf/

# Compile the bpf_sockops_v4 program
clang -O2 -g -target bpf -I/usr/include/linux/ -I/usr/src/linux-headers-5.0.0-23/include/ -c bpf_sockops_v4.c -o bpf_sockops_v4.o

# Load and attach the bpf_sockops_v4 program
sudo bpftool prog load bpf_sockops_v4.o "/sys/fs/bpf/bpf_sockops"
sudo bpftool cgroup attach "/sys/fs/cgroup/unified/" sock_ops pinned "/sys/fs/bpf/bpf_sockops"

# Extract the id of the sockhash map used by the bpf_sockops_v4 program
# This map is then pinned to the bpf virtual file system
MAP_ID=$(sudo bpftool prog show pinned "/sys/fs/bpf/bpf_sockops" | grep -o -E 'map_ids [0-9]+' | cut -d ' ' -f2-)
sudo bpftool map pin id $MAP_ID "/sys/fs/bpf/sock_ops_map"

# Load and attach the bpf_tcpip_bypass program to the sock_ops_map
clang -O2 -g -Wall -target bpf -I/usr/include/linux/ -I/usr/src/linux-headers-5.0.0-23/include/ -c bpf_tcpip_bypass.c -o bpf_tcpip_bypass.o
sudo bpftool prog load bpf_tcpip_bypass.o "/sys/fs/bpf/bpf_tcpip_bypass" map name sock_ops_map pinned "/sys/fs/bpf/sock_ops_map"
sudo bpftool prog attach pinned "/sys/fs/bpf/bpf_tcpip_bypass" msg_verdict pinned "/sys/fs/bpf/sock_ops_map"

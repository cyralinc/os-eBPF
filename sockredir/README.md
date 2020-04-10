# Socket data redirection using eBPF

> This is BPF code that demonstrates how to bypass TCPIP for socket data without modifying the applications. This code is a companion to this [blog](https://cyral.com/blog/how-to-ebpf-accelerating-cloud-native) post. 

The goal of this project is to show how to setup an eBPF network acceleration using socket data redirection when the communicating apps are on the same host.


## Testing

A simple bash script [load.sh](https://github.com/cyralinc/os-eBPF/blob/develop/sockredir/load.sh) is included that performs the following tasks:

1. Compiles the sockops BPF code, using LLVM Clang frontend, that updates the sockhash map
2. Uses bpftool to attach the above compiled code to the cgroup so that it gets invoked for all the socket operations such as connection established, etc. in the system.
3. Extracts the id of the sockhash map created by the above program and pins the map to the virtual filesystem so that it can be accessed by the second eBPF program 
4. Compiles the tcpip_bypass code that performs the socket data redirection bypassing the TCPIP stack
5. Uses bpftool to attach the above eBPF code to sockhash map 

After running the script you should be able to verify the eBPF program is loaded in the kernel.

### Verifying BPF programs are loaded in the kernel

You can list all the BPF programs loaded and their map ids:

```bash
#sudo bpftool prog show
99: sock_ops  name bpf_sockops_v4  tag 8fb64d4d0f48a1a4  gpl
	loaded_at 2020-04-08T15:54:36-0700  uid 0
	xlated 688B  jited 399B  memlock 4096B  map_ids 45
103: sk_msg  name bpf_tcpip_bypas  tag 550f6d3cfcae2157  gpl
	loaded_at 2020-04-08T15:54:36-0700  uid 0
	xlated 224B  jited 151B  memlock 4096B  map_ids 45
```

You should be able to view the SOCKHASH map also pinned onto the filesystem:

```bash
#sudo tree /sys/fs/bpf/
/sys/fs/bpf/
├── bpf_sockops
├── bpf_tcpip_bypass
└── sock_ops_map

0 directories, 3 files


#sudo bpftool map show id 45 -f
45: sockhash  name sock_ops_map  flags 0x0
	key 24B  value 4B  max_entries 65535  memlock 0B
```

### Verifying application programs are bypassing the TCPIP stack

#### Turn on tracing logs (if not enabled by default)
```bash
#echo 1 > /sys/kernel/debug/tracing/tracing_on
```
#### You can cat the kernel live streaming trace file, trace_pipe, in a shell to monitor the trace of the TCP communication through eBPF
```bash
#cat /sys/kernel/debug/tracing/trace_pipe
nc-1935  [000] ....   840.199017: 0: <<< ipv4 op = 4, port 48712 --> 1000
nc-1935  [000] .Ns1   840.199043: 0: <<< ipv4 op = 5, port 1000 --> 48712
```

#### We can use a TCP listener spawned by SOCAT to mimic an echo server, and netcat to sent a TCP connection request.
```bash
sudo socat TCP4-LISTEN:1000,fork exec:cat
nc localhost 1000 # this should produce the trace in the kernel file trace_pipe
```

## Cleanup

Running the [unload.sh](https://github.com/cyralinc/os-eBPF/blob/develop/sockredir/unload.sh) script detaches the eBPF programs from the hooks and unloads them from the kernel.

## Building

You can build on any Linux kernel with eBPF support. We have used Ubuntu Linux 18.04 with kernel 5.3.0-40-generic

## Ubuntu Linux

To prepare a Linux development environment for eBPF development, various packages and kernel headers need to be installed. Follow the following steps to prepare your development environment:
1. Install Ubuntu 18.04
2. sudo apt-get install -y make gcc libssl-dev bc libelf-dev libcap-dev clang gcc-multilib llvm libncurses5-dev git pkg-config libmnl-dev bison flex graphviz
3. sudo apt-get install iproute2
4. Download the Linux kernel source
	1. You will need to update source URIs in /etc/apt/source.list
	2. Perform the following:
		```bash
		sudo apt-get update
		sudo apt-get source linux-image-$(uname -r)
		```
		If it fails to download the source, try:
		```bash
		sudo apt-get source linux-image-unsigned-$(uname -r)
		```
	3. More information on Ubuntu [wiki](https://wiki.ubuntu.com/Kernel/BuildYourOwnKernel)
5. We will use the UAPI $kernel_src_dir/include/uapi/linux/bpf.h in the eBPF code
6. Compile and install bpftool from source. It is not yet packaged as part of the standard distributions of Ubuntu. 
	1. cd $kernel_src_dir/tools/bpf/bpftools
	2. make 
	3. make install.
7. You might also need to install libbfd-dev

DPDK-Replay
===========

## 1. Description of the software
This tool can replay a pcap capture at wire speed on several 10Gbps links by means of DPDK APIs.
It retreives the traffic from a file in pcap format and send it on the network interface(s).
It can achieve high speed when the disks are fast.

* For information about DPDK please read: http://dpdk.org/doc
* For information about this Readme file and DPDK-Replay please write to [martino.trevisan@studenti.polito.it](mailto:martino.trevisan@studenti.polito.it)

## 2. Requirements
* A machine with DPDK supported network interfaces.
* A Debian based Linux distribution with kernel >= 2.6.3
* Linux kernel headers: to install type
```bash
	sudo apt-get install linux-headers-$(uname -r)
```
* Several package needed before installing this software:
  * DPDK needs: `make, cmp, sed, grep, arch, glibc.i686, libgcc.i686, libstdc++.i686, glibc-devel.i686, python`
  * DPDK-Replay needs: `git, libpcap-dev, libpcap` 

## 3. Installation

### 3.1 Install DPDK
Install DPDK 1.8.0. With other versions is not guaranted it works properly.
Make the enviroment variable `RTE_SDK` and `RTE_TARGET` to point respectively to DPDK installation directory and compilation target.
For documentation and details see http://dpdk.org/doc/guides/linux_gsg/index.html
```bash
	wget http://dpdk.org/browse/dpdk/snapshot/dpdk-1.8.0.tar.gz
	tar xzf dpdk-1.8.0.tar.gz
	cd dpdk-1.8.0
	export RTE_SDK=$(pwd)
	export RTE_TARGET=x86_64-native-linuxapp-gcc
	make install T=$RTE_TARGET
	cd ..
```
**NOTE:** if you are running on a i686 machine, please use `i686-native-linuxapp-gcc` as `RTE_TARGET`

### 3.2 Install DPDK-Replay
Get it from the git repository. Remind to set `RTE_SDK` and `RTE_TARGET`.
```bash
	git clone https://github.com/marty90/DPDK-Replay
	cd DPDK-Replay
	make
	cd ..
```

## 4. Configuration of the machine
Before running DPDK-Dump there are few things to do:

### 4.1 Reserve a big number of hugepages to DPDK
The commands below reserve 1024 hugepages. The size of each huge page is 2MB. Check to have enough RAM on your machine.
```bash
	sudo su
	echo 1024 >/sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
	mkdir -p /mnt/huge
	mount -t hugetlbfs nodev /mnt/huge
```
### 4.2 Set CPU on performance governor
To achieve the best performances, your CPU must run always at the highest speed. You need to have installed `cpufrequtils` package.
```bash
	sudo cpufreq-set -r -g performance
```
### 4.3  Bind the interfaces you want to use with DPDK drivers
It means that you have to load DPDK driver and associate it to you network interface.
Tstat-DPDK reads packets from all the interfaces bound to DPDK.
Remember to set `RTE_SDK` and `RTE_TARGET` when executing the below commands.
```bash
	sudo modprobe uio
	sudo insmod $RTE_SDK/$RTE_TARGET/kmod/igb_uio.ko
	sudo $RTE_SDK/tools/dpdk_nic_bind.py --bind=igb_uio $($RTE_SDK/tools/dpdk_nic_bind.py --status | sed -rn 's,.* if=([^ ]*).*igb_uio *$,\1,p')
```
In this way all the DPDK-supported interfaces are working with DPDK drivers.
To check if your network interfaces have been properly set by the Intel DPDK enviroment run:
```bash
	sudo $RTE_SDK/tools/dpdk_nic_bind.py --status
```
You should get an output like this, which means that the first two interfaces are running under DPDK driver, while the third is not:
```
Network devices using DPDK-compatible driver
============================================
0000:04:00.0 'Ethernet Controller 10-Gigabit X540-AT2' drv=igb_uio unused=
0000:04:00.1 'Ethernet Controller 10-Gigabit X540-AT2' drv=igb_uio unused=
Network devices using kernel driver
===================================
0000:03:00.0 'NetXtreme BCM5719 Gigabit Ethernet PCIe' if=eth0 drv=tg3 unused=igb_uio *Active*
```
**NOTE:** If for any reason you don't want to bind all the DPDK-supported interfaces to DPDK enviroment, use the `dpdk_nic_bind.py` as described in the DPDK getting started guide.

## 5. Usage
To start DPDK-Replay just execute `./build/dpdk-replay`. If not specified it uses all the port bound to DPDK drivers and will send the same traffic on them.
Root priviledges are needed.
The are few parameters:
```bash
	./build/dpdk-dump -c COREMASK -n NUM [-w PCI_ADDR] -- -f file [-s sum] [-R rate] [-B buffer_size] [-C max_pkt] [-t times] [-T timeout]
```
The parameters have this meaning:
* `COREMASK`: The core where to bind the program. **It needs 1 core**
* `NUM`: Number of memory channels to use. It's 2 or 4.
* `PCI_ADDR`: The port(s) where to send. If not present, it sends the same traffic to every port.
* `file`: input file in pcap format
* `sum`: when using multiple interfaces, sum this number to IP addresses each time a packet is sent on the interface.
* `rate`: rate to send on the wire. If not specified it sends at wire speed.
* `buffer_size`: Internal buffer size. Default is 1 Milion packets.
* `max_pkt`: quit after sending max_pkt packets on every interface.
* `times`: how many times to send a packet on each interface. Default is 1. 
* `timeout`: timeout of the replay in seconds. Quit after it is reached. 

The parameters before `--` are DPDK enviroment related. See its guide for further explaination.

Here some example of command lines:

* It starts replaying `capture.pcap` on all DPDK interfaces at wire speed.
```bash
	sudo ./build/dpdk-replay -c 0X01 -n 4 -- -f /mnt/traces/capture.pcap
```

* It starts replaying `capture.pcap` on the two specified interfaces at 8 Gbps on each link.
```bash
	sudo ./build/dpdk-replay -c 0X01 -n 4 -w 2:00.0 -w 2:00.1 -- -f /mnt/traces/capture.pcap -r 8
```

* It starts replaying `capture.pcap` on the two specified interfaces at wire speed. On the second interface, 1 is added to source and destination IP address.
```bash
	sudo ./build/dpdk-replay -c 0X01 -n 4 -w 2:00.0 -w 2:00.1 -- -f /mnt/traces/capture.pcap -s 1
```

The system approximately each one seconds prints statistics about its performances.
```
Rate:    9.999Gbps     1.405Mpps [Average rate:   10.000Gbps     1.436Mpps]
```

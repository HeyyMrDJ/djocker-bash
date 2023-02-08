export btrfs_path='/var/djocker'                                                                    # set btrfs image path

###### Install Function
install() {
sudo /bin/bash -c "echo 127.0.0.1 $(hostname) >> /etc/hosts"                                        # Push hostname to hosts file for network namespace to resolve


#### Networking Prereqs
sudo sysctl -w net.ipv4.ip_forward=1                                                                # Enable IP Forwarding
sudo iptables -t nat -A POSTROUTING -o bridge0 -j MASQUERADE                                        # PAT for bridge interface

sudo ip link add bridge0 type bridge                                                                # Create bridge, set IP, set status of bridge to up
sudo ip addr add 10.0.0.1/24 dev bridge0
sudo ip link set bridge0 up

#### DJocker Prereqs
fallocate -l 1G ~/btrfs.img                                                                         # Preallocate space for btrfs image
mkfs.btrfs ~/btrfs.img                                                                              # Create btrfs filesystem on preallocated image
sudo mkdir /var/djocker
sudo mount -o loop ~/btrfs.img /var/djocker                                                         # Loop device is used when mounting a file as a filesystem instead of mounting a device.

}

#### Create DJ Pen
create() {
pen_id=$1                                                                                           # Set Pen Name
ip_addr=$2                                                                                          # Set last IP octet for Pen
mac=:$2                                                                                             # Set last MAC address numbers for Pen

#### Network Stuff
sudo ip link add dev veth0_"$pen_id" type veth peer name veth1_"$pen_id"                            # Create virtual network interface for namespace
sudo ip link set dev veth0_"$pen_id" up                                                             # Set virtual network interface to up
sudo ip link set veth0_"$pen_id" master bridge0                                                     # Set bridge0 as the virtual interface as the master?
sudo ip netns add netns_"$pen_id"                                                                   # Create network namespace    
sudo ip link set veth1_"$pen_id" netns netns_"$pen_id"                                              # Set virtual interface inside the network namspace
sudo ip netns exec netns_"$pen_id" ip link set dev lo up                                            # Set loopback interface for namespace to up
sudo ip netns exec netns_"$pen_id" ip link set veth1_"$pen_id" address 02:42:ac:11:00"$mac"         # Set virtual interface mac address
sudo ip netns exec netns_"$pen_id" ip addr add 10.0.0."$ip_addr"/24 dev veth1_"$pen_id"             # Set virtual interface IP address
sudo ip netns exec netns_"$pen_id" ip link set dev veth1_"$pen_id" up                               # Set virtual interface status to up
sudo ip netns exec netns_"$pen_id" ip route add default via 10.0.0.1                                # Set default gateway for virtual interface

#### File System stuff
sudo btrfs subvolume snapshot "$btrfs_path/" "$btrfs_path/$pen_id" > /dev/null                      # Create snapshot for new pen

#### Create needed files, copy binaries and required libraries
sudo mkdir $btrfs_path/$pen_id/etc
sudo mkdir $btrfs_path/$pen_id/bin
sudo mkdir $btrfs_path/$pen_id/lib
sudo mkdir $btrfs_path/$pen_id/lib64
sudo cp /bin/sh $btrfs_path/$pen_id/bin/
sudo cp /bin/ls $btrfs_path/$pen_id/bin/
sudo cp /lib/x86_64-linux-gnu/libc.so.6 $btrfs_path/$pen_id/lib/
sudo cp /lib64/ld-linux-x86-64.so.2 $btrfs_path/$pen_id/lib64/
sudo cp /lib/x86_64-linux-gnu/libselinux.so.1 $btrfs_path/$pen_id/lib/
sudo cp /lib/x86_64-linux-gnu/libpcre2-8.so.0 $btrfs_path/$pen_id/lib/
sudo cp /lib/x86_64-linux-gnu/libpthread.so.0 $btrfs_path/$pen_id/lib/
sudo touch $btrfs_path/$pen_id/etc/resolv.conf
sudo chmod 777 $btrfs_path/$pen_id/etc/resolv.conf

echo 'nameserver 8.8.8.8' > "$btrfs_path/$pen_id"/etc/resolv.conf                                   # Set nameserver for pen
}

#### Go into Pen
exec() {
    
    sudo ip netns exec netns_$1 unshare  \                                                          # chroot to btrfs snapshot mount within network namespace
    sudo chroot "$btrfs_path/$1" /bin/sh
}

#### Port Forward traffic to pen
port_forward() {
    sudo iptables -t nat -A PREROUTING -p tcp --dport $2 -j DNAT --to-destination $1:$3
}


#################################### Commands here
$1 $2 $3 $4
#################################################

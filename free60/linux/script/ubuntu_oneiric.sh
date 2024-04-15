#!/bin/bash
# set the date to anything except 1/1/1970 since this causes issues
# time is now also set after first boot by .bashrc script below
date -s 1/1/2024
# if /dev/sda is mounted then paritions get wiped by dd but sfdisk fails!
swapoff /dev/sda1
umount /mnt/ubuntu
# partition and mkfs hdd (all data is lost!)
dd if=/dev/zero of=/dev/sda bs=512 count=1
sfdisk /dev/sda << EOF
,124,S
,,L
EOF
dd if=/dev/zero of=/dev/sda2 bs=512 count=1
mkfs.ext3 /dev/sda2
mkswap /dev/sda1
sync; sync; sync
swapon /dev/sda1
# setup paths
mkdir /mnt/ubuntu
mount /dev/sda2 /mnt/ubuntu
cd /mnt/ubuntu
mkdir /mnt/ubuntu/work
cd /mnt/ubuntu/work
# download extract and run debootstrap
wget http://ftp.nl.debian.org/debian/pool/main/d/debootstrap/debootstrap_1.0.134_all.deb
ar -xf debootstrap_1.0.134_all.deb
cd /mnt/ubuntu
zcat < /mnt/ubuntu/work/data.tar.gz | tar xv
export DEBOOTSTRAP_DIR=/mnt/ubuntu/usr/share/debootstrap
export PATH=$PATH:/mnt/ubuntu/usr/sbin
debootstrap --arch powerpc oneiric /mnt/ubuntu http://old-releases.ubuntu.com/ubuntu/
# create needed files on hdd
echo Xenon > /mnt/ubuntu/etc/hostname
cat > /mnt/ubuntu/etc/fstab << EOF
/dev/sda2     /          ext3     defaults   0   0
/dev/sda1     none    swap    sw           0   0
proc            /proc    proc    defaults  0   0
EOF
cat > /mnt/ubuntu/etc/network/interfaces << EOF
iface lo inet loopback
auto lo
auto eth0
iface eth0 inet dhcp
EOF
cat > /mnt/ubuntu/etc/apt/sources.list << EOF
# Main
deb http://old-releases.ubuntu.com/ubuntu/ oneiric main restricted
deb http://old-releases.ubuntu.com/ubuntu/ oneiric universe multiverse
# Updates
deb http://old-releases.ubuntu.com/ubuntu/ oneiric-updates main restricted
deb-src http://old-releases.ubuntu.com/ubuntu/ oneiric-updates restricted
deb http://old-releases.ubuntu.com/ubuntu/ oneiric-updates universe multiverse
# Security
deb http://old-releases.ubuntu.com/ubuntu/ oneiric-security main restricted
deb-src http://old-releases.ubuntu.com/ubuntu/ oneiric-security main restricted
deb http://old-releases.ubuntu.com/ubuntu/ oneiric-security universe multiverse
deb-src http://old-releases.ubuntu.com/ubuntu/ oneiric-security universe multiverse
EOF
#Change root-pwd to "xbox" inside chroot
chroot /mnt/ubuntu echo "root:xbox" | chroot /mnt/ubuntu /usr/sbin/chpasswd
# Add user: xbox with password: xbox and add it to the sudo-group
chroot /mnt/ubuntu /usr/sbin/useradd -m -d /home/xbox -p paRRy2CC47LXY xbox
chroot /mnt/ubuntu /usr/sbin/adduser xbox sudo

# create .second_stage script on hdd
cat >> /mnt/ubuntu/root/.second_stage << EOF
#!/bin/bash
date -s 1/1/2009
apt-get update
apt-get install ntp wget openssh-server locales -y --force-yes
dpkg-reconfigure locales
apt-get install ubuntu-desktop -y
echo "AVAHI_DAEMON_START=0" > /etc/default/avahi-daemon
/etc/init.d/networking restart
cd /usr/lib/xorg/modules/drivers/
wget -O xenosfb_drv.so http://file.libxenon.org/free60/linux/xenosfb/xenosfb_drv.so_oneiric
cd /etc/X11/
wget http://file.libxenon.org/free60/linux/xenosfb/xorg.conf
rm -r -f /work/
echo "Installation completed."
echo "To boot the system: Reboot and load the kernel with correct root= params."
echo "You should be greeted by a fresh install of Ubuntu 11.10 Oneiric"
EOF
chmod a+x /mnt/ubuntu/root/.second_stage

# Execute second part of installation in the chroot environment
mount -t proc none /mnt/ubuntu/proc
mount --rbind /dev /mnt/ubuntu/dev
cp -L /etc/resolv.conf /mnt/ubuntu/etc/resolv.conf

chroot /mnt/ubuntu /root/.second_stage
umount /mnt/ubuntu/dev /mnt/ubuntu/proc /mnt/ubuntu

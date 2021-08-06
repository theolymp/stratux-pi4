#!/bin/bash
#set -x

rfkill unblock 0
ifconfig wlan0 up

timedatectl set-timezone Europe/Berlin

# prepare libs
apt install parted zip unzip zerofree build-essential automake autoconf libncurses-dev pkg-config libjpeg62-turbo-dev libconfig9 hostapd isc-dhcp-server tcpdump git cmake libtool i2c-tools libusb-1.0-0-dev libfftw3-dev python-serial jq -y

# disable swapfile
systemctl disable dphys-swapfile
apt purge dphys-swapfile -y

# cleanup
apt autoremove -y
apt clean

# install wiringPi 2.60 (required for Pi4B)
cd /root
rm -rf /root/WiringPi
git clone https://github.com/WiringPi/WiringPi
cd WiringPi
./build
rm -rf /root/WiringPi
ldconfig

# install latest golang
cd /root
wget https://golang.org/dl/go1.16.6.linux-arm64.tar.gz
rm -rf /root/go
rm -rf /root/go_path
tar xzf *.gz
rm *.gz

# install librtlsdr
cd /root
rm -rf /root/rtl-sdr
git clone https://github.com/osmocom/rtl-sdr.git
cd rtl-sdr
mkdir build
cd build
cmake ../
make -j8 && make install
rm -rf /root/rtl-sdr
ldconfig

# install kalibrate-rtl
cd /root
rm -rf /root/kalibrate-rtl
git clone https://github.com/steve-m/kalibrate-rtl
cd kalibrate-rtl
./bootstrap && CXXFLAGS='-W -Wall -O3'
./configure
make -j8 && make install
rm -rf /root/kalibrate-rtl

# install stratux-radar-display
echo
read -t 1 -n 10000 discard
read -p "Install Radar Display? [y/n]"
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  cd /root
  rm -rf /root/stratux-radar-display
  apt install libatlas-base-dev zlib1g-dev libfreetype6-dev liblcms2-dev libopenjp2-7 libtiff5 python3-pip python3-pil espeak-ng espeak-ng-data libespeak-ng-dev libbluetooth-dev -y
  pip3 install luma.oled websockets py-espeak-ng pybluez pydbus numpy
  pip3 install --upgrade PILLOW
  git clone https://github.com/TomBric/stratux-radar-display.git
fi

# clone stratux
cd /root
rm -r /root/stratux
git clone --recursive https://github.com/VirusPilot/stratux.git /root/stratux
cd /root/stratux

# copy various files from /root/stratux/image
cd /root/stratux/image
cp -f config.txt /boot/config.txt # modified in https://github.com/VirusPilot/stratux
cp -f bashrc.txt /root/.bashrc
cp -f rc.local /etc/rc.local # modified in https://github.com/VirusPilot/stratux
cp -f modules.txt /etc/modules
cp -f motd /etc/motd
cp -f logrotate.conf /etc/logrotate.conf
cp -f rtl-sdr-blacklist.conf /etc/modprobe.d/
cp -f stxAliases.txt /root/.stxAliases
cp -f dhcpd.conf /etc/dhcp/dhcpd.conf
cp -f hostapd.conf /etc/hostapd/hostapd.conf
cp -f interfaces /etc/network/interfaces
cp -f isc-dhcp-server /etc/default/isc-dhcp-server
cp -f sshd_config /etc/ssh/sshd_config

#rootfs overlay stuff
cp -f overlayctl init-overlay /sbin/
overlayctl install
# init-overlay replaces raspis initial partition size growing.. Make sure we call that manually (see init-overlay script)
touch /var/grow_root_part
mkdir -p /overlay/robase # prepare so we can bind-mount root even if overlay is disabled

# Optionally mount /dev/sda1 as /var/log - for logging to USB stick
echo -e "\n/dev/sda1             /var/log        auto    defaults,nofail,noatime,x-systemd.device-timeout=1ms  0       2" >> /etc/fstab

#Set the keyboard layout to DE and pc101
sed -i /etc/default/keyboard -e "/^XKBLAYOUT/s/\".*\"/\"de\"/"
sed -i /etc/default/keyboard -e "/^XKBMODEL/s/\".*\"/\"pc101\"/"

# prepare services
systemctl enable isc-dhcp-server
systemctl enable ssh
systemctl disable dhcpcd
systemctl disable hciuart
systemctl disable hostapd
systemctl disable apt-daily.timer
systemctl disable apt-daily-upgrade.timer

sed -i 's/INTERFACESv4=""/INTERFACESv4="wlan0"/g' /etc/default/isc-dhcp-server

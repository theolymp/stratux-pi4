#!/bin/bash
#set -x

function update_base {
    apt update
    apt full-upgrade -y
}

function install_dep {
    apt install libncurses-dev -y
    apt install pkg-config -y
    apt install libjpeg8-dev -y
    apt install libconfig9 -y
    apt install hostapd -y
    apt install dnsmasq -y
    apt install tcpdump -y
    apt install git -y
    apt install cmake -y
    apt install autoconf -y
    apt install libtool -y
    apt install i2c-tools -y
    apt install librtlsdr0 -y
    apt install librtlsdr-dev -y
    apt install rtl-sdr -y
    apt install golang -y
    apt install libfftw3-dev -y
    wget https://project-downloads.drogon.net/wiringpi-latest.deb
    dpkg -i *.deb
    rm *.deb
    ldconfig
}

function prepare_network {
    cp -f /root/stratux-pi4/hostapd.conf /etc/hostapd/hostapd.conf
    cp -f /root/stratux-pi4/dnsmasq.conf /etc/dnsmasq.conf
    cp -f /root/stratux-pi4/wlan0 /etc/network/interfaces.d/
    systemctl enable dhcpcd
    systemctl unmask hostapd
    systemctl enable hostapd
    systemctl enable dnsmasq
    touch /var/lib/dhcp/dhcpd.leases
	touch /etc/hostapd/hostapd.user
}

function prepare_stratux {
    export PATH=/usr/lib/go/bin:${PATH}
    export GOROOT=/usr/lib/go
    export GOPATH=/usr/lib/go_path
    # clone stratux
    rm -r /root/stratux
    git clone -b ogn-rx-eu https://github.com/b3nn0/stratux.git
    cd /root/stratux
    # replace dump1090 with dump1090-fa
    rm -r /root/stratux/dump1090
    git clone --branch stratux https://github.com/Determinant/dump1090-fa-stratux.git dump1090
    git submodule update --init --recursive goflying
    # copy dump1090 link file
    cp -f /root/stratux-pi4/dump1090 /usr/bin/
    chmod 755 /usr/bin/dump1090
    # enable i2c
    cp -f /root/stratux-pi4/config.txt /boot/config.txt
    cp -f /root/stratux-pi4/modules /etc/modules
    # replace Makefile
    cp -f /root/stratux-pi4/Makefile /root/stratux/Makefile
    # copy stratux service file
    cp -f /root/stratux-pi4/stratux.service /lib/systemd/system/stratux.service
    chmod 644 /lib/systemd/system/stratux.service
    ln -fs /lib/systemd/system/stratux.service /etc/systemd/system/multi-user.target.wants/stratux.service
    # copy various files from ./stratux/image
    cd /root/stratux/image
    cp -f motd /etc/motd
    cp -f 99-uavionix.rules /etc/udev/rules.d
    cp -f 10-stratux.rules /etc/udev/rules.d
    cp -f logrotate.conf /etc/logrotate.conf
    cp -f rtl-sdr-blacklist.conf /etc/modprobe.d/
    cp -f rc.local /etc/rc.local
}

update_base
install_dep
prepare_network
prepare_stratux
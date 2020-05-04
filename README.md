# stratux-pi4
Build a Stratux Europe on a Pi4B (Pi3B tested as well) based on a fresh Raspbian Buster Lite image.

This started as a script just for myself to build a Stratux Europe for a passive cooled Pi4B, based on:
- https://github.com/b3nn0/stratux
- https://project-downloads.drogon.net/wiringpi-latest.deb (only v2.52 works with Pi4B)
- http://download.glidernet.org/arm/rtlsdr-ogn-bin-ARM-latest.tgz (only ARM version works with Pi4B)
- https://github.com/Determinant/dump1090-fa-stratux (based on dump1090-fa)
- https://osmocom.org/projects/rtl-sdr/ (apt version used for dump1090-fa)
- Raspbian Buster Lite
- Raspberry Pi4B (also tested on Pi3B)

## Steps required:
- Pi4B connected to LAN
- boot from a fresh Raspbian Buster Lite Image with ssh enabled
- login as `pi` user
```
sudo su
cd ~/
apt update
apt full-upgrade
```
If you haven't yet programed your SDRs, please first follow the instructions under "Remarks - SDR programming" below for each SDR individually or otherwise just continue here:
```
apt install git -y
git clone https://github.com/VirusPilot/stratux-pi4.git
cd stratux-pi4
./install.sh (press y a couple of times)
```

After reboot please reconnect LAN and/or WiFi and Stratux should work right away.

## Limitations/Modifications
- Network configuration: dnsmasq instead of isc-dhcp-server
- Settings Page: WiFi configuration is not working !! (contributions to change that are welcome)
- WiFi IP: 192.168.1.1 (required for FLARM NMEA and SkyDemon)
- WiFi SSID: stratux-pi4
- WiFi Password: stratux-pi4
- fancontrol service disabled
- selfupdate won't work
- green LED behavior set to Pi defaults (blinking in case of SD card activity)
- commandline aliases not available
- BladeRF 2.0 Micro support disabled
- https://github.com/steve-m/kalibrate-rtl not installed

## not yet implemented/added:
- flexible pathnames (currently hardcoded)
- as soon as https://github.com/flightaware/dump1090/pull/61 is accepted, switch to https://github.com/flightaware/dump1090

## Remarks - SDR programming (1)
During boot, Stratux tries to identify which SDR to use for which traffic type (ADS-B, FLARM/OGN) - this is done by reading the "Serial number" entry in each SDRs. You can check or modify these entries as described below, it is recommended for programming to only plug in one SDR at a time, connect the appropriate antenna and label this combination accordingly, e.g. "868" for FLARM/OGN.
```
apt install rtl-sdr -y
rtl_eeprom
```
will report something like the following:
```
Current configuration:
__________________________________________
Vendor ID:              0x0bda
Product ID:             0x2838
Manufacturer:           Realtek
Product:                RTL2838UHIDIR
Serial number:          stx:868:0
Serial number enabled:  yes
IR endpoint enabled:    yes
Remote wakeup enabled:  no
__________________________________________
```
This SDR is obviosly programmed for Stratux (stx), FLARM/OGN (868MHz), and a ppm correction of "0", the ppm can be modified later, see below. If your SDR comes pre-programed (it would be labled with e.g. with "1090") there is no need to program it.

You can program the `Serial number` entry with the following command:
```
rtl_eeprom -s stx:1090:0
```
to prepare it e.g. for ADS-B (1090MHz) use. A reboot is necessary to activate the new serial number.

At this point you can already test your SDR and receive ADS-B traffic with the following command:
```
rtl_adsb -V"
```
Or listen to you favorite FM radio station (my station below is at 106.9MHz) by pluging in a headset and run the following command:
```
rtl_fm -M fm -f 106.9M -s 32000 -g 60 -l 10 - | aplay -t raw -r 32000 -c 1 -f S16_LE".
```
## Remarks - SDR programming (2)
During boot, Stratux furthermore reads the ppm correction from the SDR `Serial number`, e.g. if the `Serial number` is `stx:1090:28` then the ppm used by Stratux is +28. If the appropriate ppm for the SDR is unknown, here are the steps to find out (again it is useful to have only one SDR plugged in to avoid confusion):
```
cd /root/stratux/ogn/rtlsdr-ogn
./gsm_scan
```
For the ppm measurement using `gsm_scan`, please follow https://github.com/glidernet/ogn-rf/blob/6d6cd8a15a5fbff122542401180ea7e58af9ed92/INSTALL#L42

Once you have found the appropriate ppm (e.g. +16 for the FLARM/OGN SDR), the SDR `Serial number` needs to be programmed once again:
```
rtl_eeprom -s stx:868:16
```
## Remarks - FLARM/OGN frequency usage outside of Europe
- ogn-rf seems to set the FLARM/OGN frequency according to the device's GPS position with the exception of China (470 MHz) and India (866 MHz) which still needs to be implemented

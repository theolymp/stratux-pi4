
LFLAGS=-X main.stratuxVersion=`git describe --tags --abbrev=0` -X main.stratuxBuild=`git log -n 1 --pretty=%H`

BUILDINFO+=-ldflags "$(LFLAGS)"

BUILDINFO_STATIC=-ldflags "-extldflags -static $(LFLAGS)"

$(if $(GOROOT),,$(error GOROOT is not set!))

all:
	make xdump978 xdump1090 xgen_gdl90 fancontrol www

xgen_gdl90:
	go get -t -d -v ./main ./godump978 ./uatparse ./sensors
	export CGO_CFLAGS_ALLOW="-L/root/stratux" && go build $(BUILDINFO) -p 4 main/gen_gdl90.go main/traffic.go main/gps.go main/network.go main/managementinterface.go main/sdr.go main/ping.go main/uibroadcast.go main/monotonic.go main/datalog.go main/equations.go main/sensors.go main/cputemp.go main/lowpower_uat.go main/ogn.go main/flarm.go main/flarm-nmea.go main/networksettings.go main/xplane.go

fancontrol:
	go get -t -d -v ./main
	go build $(BUILDINFO) -p 4 main/fancontrol.go main/equations.go main/cputemp.go

xdump1090:
	cd dump1090 && make BLADERF=no

xdump978:
	cd dump978 && make lib
	sudo cp -f ./libdump978.so /usr/lib/libdump978.so

www:
	cd web && make

install:
	cp -f libdump978.so /usr/lib/libdump978.so
	cp -f gen_gdl90 /usr/bin/gen_gdl90
	chmod 755 /usr/bin/gen_gdl90

	#rm -f mnt/etc/rc*.d/hostapd
	#rm -f mnt/etc/network/if-pre-up.d/hostapd
	#rm -f mnt/etc/network/if-post-down.d/hostapd
	#rm -f mnt/etc/init.d/hostapd
	#rm -f mnt/etc/default/hostapd
	#rm -f /etc/network/if-up.d/wpasupplicant
	#rm -f /etc/network/if-pre-up.d/wpasupplicant
	#rm -f /etc/network/if-down.d/wpasupplicant
	#rm -f /etc/network/if-post-down.d/wpasupplicant

	#rm -f /var/run/ogn-rf.fifo
	#mkfifo /var/run/ogn-rf.fifo

	#touch /etc/stratux.conf
	#chmod a+rw /etc/stratux.conf

clean:
	rm -f gen_gdl90 libdump978.so fancontrol ahrs_approx
	cd dump1090 && make clean
	cd dump978 && make clean

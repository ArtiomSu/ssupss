problem here is docker cant switch the driver from usbhid to the ups driver lmao.

Haven't found a solution to it yet.

# Run and Build

Add a rules file to `/usr/lib/udev/rules.d/62-nut-usbups.rules`

with the device id from 

```sh
lsusb | grep USP
Bus 003 Device 011: ID 0764:0501 Cyber Power System, Inc. CP1500 AVR UPS
```

```txt
# Bus 003 Device 011: ID 0764:0501 Cyber Power System, Inc. CP1500 AVR UPS

ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0764", ATTR{idProduct}=="0501", ATTR{driver}=="usbhid", RUN+="/usr/bin/usb_modeswitch -v 0764 -p 0501"

ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0764", ATTR{idProduct}=="0501", MODE="664", GROUP="nut"
```



```sh
paru -S usb_modeswitch
doas chmod 644 /usr/lib/udev/rules.d/62-nut-usbups.rules
doas groupadd nut # if not already there
doas udevadm control --reload-rules && doas udevadm trigger
```

then unplug and plug back in the usb

```sh
docker-compose build
docker-compose up
```
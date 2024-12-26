# Stupid Simple UPS Setup (SSUPSS)

This guide + script is perfect if you want just a simple nut server setup that shuts down your server once your UPS charge % reaches a certain point. This is needed if your server is using zfs in particular as there could be a few gigs in ram that need to be flushed. Also this gives some time to shutdown your vms properly.

Supports logging + cleaning logs.

You can also send out notifications if you want, you just need to add the path to your notification script. I send notifications to telegram via a simple curl request but thats outside of the scope for this repo.

#### Why did I create this?

I wanted a simple nut setup, and followed the standard guide where you setup the monitor and stuff that shuts down the pc after the ups reaches a certain point. It can also do alot more which is pretty cool but not needed for my simple usecase.

So anyway that setup worked ok for about a month, then all of a sudden the pc started to randomly shut down for no apparent reason. Disabling the nut server fixed the problem, but I never found out what caused it in the first place. So I decided to get rid of as many variables as possible and this is how this project was born.

I have plans to run this whole thing within docker for an even easier setup but I ran into some issues so that's currently on pause. Also ran into issues getting it to run on a proxmox lxc container, so that's out of the question for now too.

# Setup

This setup assumes that you are using a debian based OS. Other linux flavours should work too but not tested. And you are using a Cyberpower UPS, you might need to tweak the config for other UPSs, in particular which driver to use. usbhid-ups should do most of the UPSs.

1. `apt install nut`

2. edit `/etc/nut/nut.conf`

	```txt
	MODE=standalone
	```

3. edit `/etc/nut/ups.conf`

	```sh
	pollinterval = 15
	maxretry = 3

	offdelay = 120
	ondelay = 240

	[cyberpower]
		driver = usbhid-ups
		port = auto
		desc = "CyperPower 1600"
		vendorid = 0764
		productid = 0501
	```

	`desc` can be anything you want.
	
	To get the vendor and product id you will need to get them by running `lsusb` if lsusb is not installed you can get it by `apt install usbutils`.

	Once you run `lsusb` look for your UPS. Mine looks like this

	```
	Bus 001 Device 002: ID 0764:0501 Cyber Power System, Inc. CP1500 AVR UPS
	```
	Note the `vendorid` is the first 4 numbers before the `:` after the `ID`. And the `productid` is the last 4 number there.

4. edit `/etc/nut/upsd.conf`

	```txt
	LISTEN 127.0.0.1 3493
	```

5. make sure the rest of the files in `/etc/nut/` are commented out.

6. then start the service `sudo systemctl start nut-server` and if you want it running on startup do `sudo systemctl enable nut-server`

7. test if everything is working by running `upsc cyberpower@localhost`

8. download the `checkUps.sh` script from this repo and save it to preferably `/root/scripts/`.
	
	Modify the script to your liking. I would recommend putting it in test mode first otherwise it could shutdown your pc for some strange reason and you would be confused

9. add a cron job for this script to run every minute.

	```sh
	crontab -e

	* * * * * /root/scripts/checkUps.sh >> /var/log/check_ups.log 2>&1
	```

10. since we are logging to a file its best to delete it after a while so create `/etc/logrotate.d/check_ups` with the following contents

	```txt
	/var/log/check_ups.log {
		daily
		rotate 3
		compress
		delaycompress
		missingok
		notifempty
		create 640 root root
	}
	```

	you can then check if this config is ok by running `logrotate -d /etc/logrotate.conf` and checking the output. This will keep the logs for only 3 days to not polute the filesystem.

# Video Guide

#### Setting this up on the raspbery pi

[![part1](https://img.youtube.com/vi/j-guBGFqv5Q/0.jpg)](https://www.youtube.com/watch?v=j-guBGFqv5Q)
# Raspberry PI - Bluetooth Audio Receiver (A2DP)

Raspbian Jessie 4.4.50-v7+ #970 SMP, Bluez-5 + PulseAudio-5

Based on [davidedg's great guide](https://github.com/davidedg/NAS-mod-config/blob/master/bt-sound/bt-sound-Bluez5_PulseAudio5.txt).

## PREREQUISITES

You will need:
- a Raspberry PI with an USB BT dongle connected (or Raspberry PI 3 with built in BT adapter)
- power adapter (or powered USB hub)
- an empty SD card
- last but not least an audio cable connected to speaker :)

Preparation:
1. Download the [Raspbian Jessie Lite](https://www.raspberrypi.org/downloads/raspbian/) system image.
2. Write it to the SD card following this [instructions](https://www.raspberrypi.org/documentation/installation/installing-images/README.md).
3. Place a file named 'ssh', without any extension, onto the smaller (FAT) partition of the SD card.
4. Plug it all together, and power on the PI
5. Log in to your system trough SSH following [this guide](https://www.raspberrypi.org/documentation/remote-access/ssh/windows.md). The default username is "pi" and password is "raspberry".

## INSTALLATION

Get the latest updates and install BlueZ-5 and PulseAudio-5 with Bluetooth support.

```bash
sudo apt-get update && sudo apt-get upgrade
sudo apt-get update && sudo apt-get dist-upgrade
sudo apt-get --no-install-recommends install pulseaudio pulseaudio-module-bluetooth bluez
```

If your dongle is a based on a BCM203x chipset, install the firmware.

```bash
sudo apt-get bluez-firmware
```

## PERMISSIONS

Authorize users (each user that will be using PA must belong to group pulse-access)

```bash
sudo adduser root pulse-access
sudo adduser pi pulse-access
```

Authorize PulseAudio - which will run as user pulse - to use BlueZ D-BUS interface:

```bash
sudo nano /etc/dbus-1/system.d/pulseaudio-bluetooth.conf
```

and copy the following lines to the SSH window (in PuTTY use right click)

```xml
<busconfig>
  <policy user="pulse">
    <allow send_destination="org.bluez"/>
  </policy>
</busconfig>
```

then press Ctr+O to save the file, and Ctrl+X to exit.

## CONFIGURE PULSEAUDIO

Not strictly required, but you may need: `sudo nano /etc/pulse/daemon.conf` and change "resample-method" to either:

- trivial: lowest cpu, low quality
- src-sinc-fastest: more cpu, good resampling
- speex-fixed-N: N from 1 to 7, lower to higher CPU/quality

Enable the bluetooth-discover and bluetooth-policy modules with

```bash
sudo nano /etc/pulse/system.pa
```

and putting this lines to the end of the file:

```
### Bluetooth Support
.ifexists module-bluetooth-discover.so
load-module module-bluetooth-discover
.endif
.ifexists module-bluetooth-policy.so
load-module module-bluetooth-policy
.endif
```

Create a systemd service for running pulseaudio in System Mode as user "pulse"

```bash
sudo nano /etc/systemd/system/pulseaudio.service
```

with this lines:

```ini
[Unit]
Description=Pulse Audio

[Service]
Type=simple
ExecStart=/usr/bin/pulseaudio --system --disallow-exit --disable-shm --exit-idle-time=-1

[Install]
WantedBy=multi-user.target
```

and then reload modules

```bash
sudo systemctl daemon-reload
sudo systemctl enable pulseaudio.service
```

## CONFIGURE BLUETOOTH

Change the adapter name and class. You can find more about device classes [here](http://bluetooth-pentest.narod.ru/software/bluetooth_class_of_device-service_generator.html).

```bash
sudo nano /etc/bluetooth/main.conf
```

```
Name = %h
Class = 0x20043C
```

Restart bluetooth and check its status (those errors are fine)

```bash
sudo systemctl restart bluetooth
sudo systemctl status bluetooth
	● bluetooth.service - Bluetooth service
	   Loaded: loaded (/lib/systemd/system/bluetooth.service; enabled)
	   Active: active (running) since Thu 2015-08-13 23:58:53 CEST; 28s ago
		 Docs: man:bluetoothd(8)
	 Main PID: 5604 (bluetoothd)
	   Status: "Running"
	   CGroup: /system.slice/bluetooth.service
			   └─5604 /usr/lib/bluetooth/bluetoothd

	Aug 13 23:58:53 nasivadaras bluetoothd[5604]: Bluetooth daemon 5.23
	Aug 13 23:58:53 nasivadaras bluetoothd[5604]: Starting SDP server
	Aug 13 23:58:53 nasivadaras bluetoothd[5604]: Bluetooth management interface 1.9 initialized
	Aug 13 23:58:53 nasivadaras bluetoothd[5604]: Sap driver initialization failed.
	Aug 13 23:58:53 nasivadaras bluetoothd[5604]: sap-server: Operation not permitted (1)
	Aug 13 23:58:53 nasivadaras systemd[1]: Started Bluetooth service.
```

Now use bluetoothctl to power on the device, pair, trust and connect with bt devices.
It will be fine if connect will fail - it's pulseaudio that will do the actual connect.

```bash
sudo bluetoothctl
[NEW] Controller 00:00:00:00:00:00 raspberrypi [default]
[bluetooth]# power on
[bluetooth]# agent on
[bluetooth]# default-agent
[bluetooth]# scan on
	[NEW] Device xx:xx:xx:xx:xx:xx Device Name
[bluetooth]# pair xx:xx:xx:xx:xx:xx
[bluetooth]# trust xx:xx:xx:xx:xx:xx
...
[bluetooth]# scan off
[bluetooth]# exit
```

## TEST

PulseAaudio should pick up the bluetooth devices that it can handle systemctl start pulseaudio.service

```bash
sudo systemctl -l status pulseaudio.service
● pulseaudio.service - Pulse Audio
   Loaded: loaded (/etc/systemd/system/pulseaudio.service; disabled)
   Active: active (running) since Fri 2015-08-14 01:05:19 CEST; 2min 21s ago
 Main PID: 1708 (pulseaudio)
   CGroup: /system.slice/pulseaudio.service
           └─1708 /usr/bin/pulseaudio --system --disallow-exit --disable-shm

Aug 14 01:05:19 nasivadaras systemd[1]: Started Pulse Audio.
Aug 14 01:05:19 nasivadaras pulseaudio[1708]: W: [pulseaudio] main.c: Running in system mode, but --disallow-module-loading not set!
Aug 14 01:05:19 nasivadaras pulseaudio[1708]: W: [pulseaudio] main.c: OK, so you are running PA in system mode. Please note that you most likely shouldn't be doing that.
Aug 14 01:05:19 nasivadaras pulseaudio[1708]: W: [pulseaudio] main.c: If you do it nonetheless then it's your own fault if things don't work as expected.
Aug 14 01:05:19 nasivadaras pulseaudio[1708]: W: [pulseaudio] main.c: Please read http://pulseaudio.org/wiki/WhatIsWrongWithSystemMode for an explanation why system mode is usually a bad idea.
Aug 14 01:05:19 nasivadaras pulseaudio[1708]: E: [pulseaudio] bluez4-util.c: org.bluez.Manager.GetProperties() failed: org.freedesktop.DBus.Error.UnknownMethod: Method "GetProperties" with signature "" on interface "org.bluez.Manager" doesn't exist
```

```bash
sudo systemctl status bluetooth.service
● bluetooth.service - Bluetooth service
   Loaded: loaded (/lib/systemd/system/bluetooth.service; enabled)
   Active: active (running) since Fri 2015-08-14 00:25:52 CEST; 40min ago
     Docs: man:bluetoothd(8)
 Main PID: 971 (bluetoothd)
   Status: "Running"
   CGroup: /system.slice/bluetooth.service
           └─971 /usr/lib/bluetooth/bluetoothd

Aug 14 00:43:45 nasivadaras bluetoothd[971]: Endpoint unregistered: sender=:1.6 path=/MediaEndpoint/A2DPSource
Aug 14 00:43:45 nasivadaras bluetoothd[971]: Endpoint unregistered: sender=:1.6 path=/MediaEndpoint/A2DPSink
Aug 14 00:43:45 nasivadaras bluetoothd[971]: Endpoint registered: sender=:1.7 path=/MediaEndpoint/A2DPSource
Aug 14 00:43:45 nasivadaras bluetoothd[971]: Endpoint registered: sender=:1.7 path=/MediaEndpoint/A2DPSink
Aug 14 00:44:32 nasivadaras bluetoothd[971]: /org/bluez/hci0/dev_00_1D_DF_BE_10_4C/fd2: fd(21) ready
Aug 14 01:05:08 nasivadaras bluetoothd[971]: Endpoint unregistered: sender=:1.7 path=/MediaEndpoint/A2DPSource
Aug 14 01:05:08 nasivadaras bluetoothd[971]: Endpoint unregistered: sender=:1.7 path=/MediaEndpoint/A2DPSink
Aug 14 01:05:19 nasivadaras bluetoothd[971]: Endpoint registered: sender=:1.8 path=/MediaEndpoint/A2DPSource
Aug 14 01:05:19 nasivadaras bluetoothd[971]: Endpoint registered: sender=:1.8 path=/MediaEndpoint/A2DPSink
Aug 14 01:05:54 nasivadaras bluetoothd[971]: /org/bluez/hci0/dev_00_1D_DF_BE_10_4C/fd3: fd(21) ready
```

That's all. Reboot the PI with `sudo reboot` and enjoy your brand new bluetooth reciever! :)

## IF SOMETHING GOES WRONG

- Check the audio output with: `aplay /path/to/any/test/sound.wav`
- Check the loaded bluetooth modules with: `pactl list short |grep bluez`
- Also see the logs with: `dmesg |grep Blue' and 'dmesg |grep input`

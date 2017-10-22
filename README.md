# Docker container stack: hostap + dhcp server 

Designed to work on **Raspberry Pi 3** (arm) using as base image alpine linux (very small size).

# Idea

A Raspberry Pi is as versatile as any computer and using Docker you can better manage your setup. If you want to use your Raspberry Pi as a network server or a router, then being able to use it's WiFi as an Access Point (AP) is probably useful to you.

The WiFi signal of the Raspberry Pi 3 is noticeable weaker then my other WiFi Access Points so that is something to bear in mind. If most of the time you use wireless devices on the same room it will work fine. 

# Requirements

A Raspberry Pi 3 with Docker installed. I'm running it on Raspbian Lite.

You can check the Raspberry Pi 3's WiFi module support AP mode:

```
# iw list
...
        Supported interface modes:
                 * IBSS
                 * managed
                 * AP
...
```

If you want to, you can set country regulations. For excample, to use Spain set:

```
# iw reg set ES
country ES: DFS-ETSI
        (2400 - 2483 @ 40), (N/A, 20), (N/A)
        (5150 - 5250 @ 80), (N/A, 23), (N/A), NO-OUTDOOR
        (5250 - 5350 @ 80), (N/A, 20), (0 ms), NO-OUTDOOR, DFS
        (5470 - 5725 @ 160), (N/A, 26), (0 ms), DFS
        (57000 - 66000 @ 2160), (N/A, 40), (N/A)
```
FYI : I didn't change this from the default setting on my Pi 3.

# Build / run

For modification, testings, etc.. there is already a `Makefile`. So you can `make run` to start a sample ssid with a simple password. 

```
docker build -t yvgit/rpi-hostap git://github.com/YVgit/rpi-hostap.git
```


I've already uploaded the image to docker hubs, so you can run it from ther like this:

```
sudo docker run -d -t \
  -e INTERFACE=wlan0 \
  -e CHANNEL=6 \
  -e SSID=runssid \
  -e APADDR=192.168.254.1 \
  -e SUBNET=192.168.254.0 \
  -e WPA_PASSPHRASE=passw0rd \
  -e OUTGOINGS=eth0 \
  --privileged \
  --net host \
  yvgit/rpi-hostap:latest
```

But before this, hostap usually requires that wlan0 interface to be already up, so before `docker run` take the interface up:

```
/sbin/ifconfig wlan0 192.168.254.1/24 up
```
By default, this is up on the Raspberry Pi 3 so you can skip this step.


# Todo 

Improve README.md


#!/bin/bash

set +e

CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_hostname rlabred003
else
   echo rlabred003 >/etc/hostname
   sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\trlabred003/g" /etc/hosts
fi
FIRSTUSER=`getent passwd 1000 | cut -d: -f1`
FIRSTUSERHOME=`getent passwd 1000 | cut -d: -f6`
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom enable_ssh
else
   systemctl enable ssh
fi
if [ -f /usr/lib/userconf-pi/userconf ]; then
   /usr/lib/userconf-pi/userconf 'pi2' '$5$BzPsS.C7b8$X.F3bMsyqyzNSzf9EUynKOZz5uQwkInGi5d1dlnSbhD'
else
   echo "$FIRSTUSER:"'$5$BzPsS.C7b8$X.F3bMsyqyzNSzf9EUynKOZz5uQwkInGi5d1dlnSbhD' | chpasswd -e
   if [ "$FIRSTUSER" != "pi2" ]; then
      usermod -l "pi2" "$FIRSTUSER"
      usermod -m -d "/home/pi2" "pi2"
      groupmod -n "pi2" "$FIRSTUSER"
      if grep -q "^autologin-user=" /etc/lightdm/lightdm.conf ; then
         sed /etc/lightdm/lightdm.conf -i -e "s/^autologin-user=.*/autologin-user=pi2/"
      fi
      if [ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
         sed /etc/systemd/system/getty@tty1.service.d/autologin.conf -i -e "s/$FIRSTUSER/pi2/"
      fi
      if [ -f /etc/sudoers.d/010_pi-nopasswd ]; then
         sed -i "s/^$FIRSTUSER /pi2 /" /etc/sudoers.d/010_pi-nopasswd
      fi
   fi
fi
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_wlan 'labred' 'e046f323c3280a8a99a852e58dfdee1ac2fe23c0903e2d6fed8f075138fa73e0' 'MX'
else
cat > /etc/dhcpcd.conf <<'DHCPCDEOF'
# A sample configuration for dhcpcd.
# See dhcpcd.conf(5) for details.

# Allow users of this group to interact with dhcpcd via the control socket.
#controlgroup wheel

# Inform the DHCP server of our hostname for DDNS.
rlabred003

# Use the hardware address of the interface for the Client ID.
clientid
# or
# Use the same DUID + IAID as set in DHCPv6 for DHCPv4 ClientID as per RFC4361.
# Some non-RFC compliant DHCP servers do not reply with this set.
# In this case, comment out duid and enable clientid above.
#duid

# Persist interface configuration when dhcpcd exits.
persistent

# Rapid commit support.
# Safe to enable by default because it requires the equivalent option set
# on the server to actually work.
option rapid_commit

# A list of options to request from the DHCP server.
option domain_name_servers, domain_name, domain_search, host_name
option classless_static_routes
# Respect the network MTU. This is applied to DHCP routes.
option interface_mtu

# Most distributions have NTP support.
#option ntp_servers

# A ServerID is required by RFC2131.
require dhcp_server_identifier

# Generate SLAAC address using the Hardware Address of the interface
#slaac hwaddr
# OR generate Stable Private IPv6 Addresses based from the DUID
slaac private

# Example static IP configuration:
interface wlan0
static ip_address=172.30.2.3/20
#static ip6_address=fd51:42f8:caae:d92e::ff/64
static routers=172.30.15.254
static domain_name_servers=148.206.191.1 8.8.8.8 8.8.4.4

# It is possible to fall back to a static IP if DHCP fails:
# define static profile
#profile static_eth0
#static ip_address=192.168.1.23/24
#static routers=192.168.1.1
#static domain_name_servers=192.168.1.1

# fallback to static profile on eth0
#interface eth0
#fallback static_eth0
DHCPCDEOF

cat >/etc/wpa_supplicant/wpa_supplicant.conf <<'WPAEOF'
country=MX
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
ap_scan=1

update_config=1
network={
	ssid="labred"
	psk=e046f323c3280a8a99a852e58dfdee1ac2fe23c0903e2d6fed8f075138fa73e0
}

WPAEOF
   chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
   rfkill unblock wifi
   for filename in /var/lib/systemd/rfkill/*:wlan ; do
       echo 0 > $filename
   done
fi
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_keymap 'us'
   /usr/lib/raspberrypi-sys-mods/imager_custom set_timezone 'America/Mexico_City'
else
   rm -f /etc/localtime
   echo "America/Mexico_City" >/etc/timezone
   dpkg-reconfigure -f noninteractive tzdata
cat >/etc/default/keyboard <<'KBEOF'
XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS=""

KBEOF
   dpkg-reconfigure -f noninteractive keyboard-configuration
fi
rm -f /boot/firstrun.sh
sed -i 's| systemd.run.*||g' /boot/cmdline.txt
exit 0

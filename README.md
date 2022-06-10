# ikbdop
Contains a simple shell program to enable or disable Internal Keyboard of a laptop in Linux.

## Xorg / X11 HowTo
copy ikbdop.sh to your local device (maybe into ~/.local/bin/) and use it to disable and re-enable the Keyboard while using the X Display Server.

## Current Wayland HowTo (simple shell script for setup & use - work in progress)

This is currently work in Progress... you are free to contribute.

## Current Wayland HowTo (manual setup - tested and working)
This is currnetly still in development and/or testing and i am open for contributions

### Check if you are really running Wayland
`~$ sudo pgrep wayland --count` will tell you if there are running processes whose name contains wayland.
Your are most likely running wayland if the result is greater than 0.

### Find out what exactly you want to disable
Use `~$ sudo libinput list-devices` to get an overview over all input-devices that wayland can access.
You can also use `~$ sudo evtest` to determine which device is which.
Generally "AT Translated Set 2 keyboard" is almost always the internal keyboard and "SynPS/2 Synaptics TouchPad" is the internal TouchPad.
Please take note which device you want to disable and what exact "/dev/input/eventX"-Path it has.

If you know what to search for you can use for example `~$ sudo libinput list-devices | grep --after-context 1 "AT Translated Set 2 keyboard" | grep Kernel | awk '{print $2}'` to get the "/dev/input/eventX"-Path without having to copy-paste.

![grafik](https://user-images.githubusercontent.com/29387023/173143197-d66d0e20-a7c3-4703-8f1a-0eb8915e0a46.png)

![grafik](https://user-images.githubusercontent.com/29387023/173143378-e37d4f1e-9ffb-4b45-9054-2404da2e8c99.png)

### Get the /sys/devices/platform/[...]/input/inputX/inhibited path of the device
Use `~$ sudo udevadm info --attribute-walk --path=$(udevadm info --query=path --name=/dev/input/event3) | grep --extended-regexp --regexp='looking at parent device .\/devices\/platform\/[A-Za-z0-9]+\/[A-Za-z0-9]+\/input\/input[0-9]+.:' | awk '{print $5}' | sed 's/://' | sed 's/^./\/sys/' | sed 's/.$/\/inhibited/'` to get the "/sys/devices/platform/[...]/input/inputX/inhibited"-Path 

![grafik](https://user-images.githubusercontent.com/29387023/173150787-969acfd6-c885-40a7-b601-29fc4f790f3d.png)

### Check / Disable / Re-Enable the Device
Watch out that you dont lock yourself out of accessing/controlling your device when you deactivate your touchpad and/or internal keyboard and have external devices (or a touch screen) at hand to interact with the device and re-enable the internal devices.

**Check current status of the device**
```
~$ cat /sys/devices/platform/[...]/[...]/input/inputX/inhibited
```
Output 0 is not inhibited (device is not ignored by the kernel). Output 1 or higher is inhibited (Kernel ignores inputs from the device).

**Disable the device (as root)**
```
~# echo 1 > /sys/devices/platform/[...]/[...]/input/inputX/inhibited
```

**Re-Enable the device (as root)**
```
~# echo 0 > /sys/devices/platform/[...]/[...]/input/inputX/inhibited
```

### Create Script for ease of use (Example)

```
~$ nano ~/.local/bin/convertible-mode.sh
#!/bin/bash

## Syntax
# To enable Convertible Mode (inhibit internal Keyboard and Touchpad) use './convertible-mode.sh enable'
# To disable Convertible Mode (re-enable internal Keyboard and Touchpad) use './convertible-mode.sh disable'

## Check User
if [[ "$USER" != "root" ]]; then
  echo "Script must be run by root or via sudo, exiting."
  exit 1
fi

## Check parameters
if [[ $# -gt 1 ]]; then
  echo "Too many arguments, exiting."
  echo "Syntax: ./convertible-mode.sh ( enable | disable )"
  exit 2
elif [[ $# -lt 1 ]]; then
  echo "No Arguments given, exiting."
  echo "Syntax: ./convertible-mode.sh ( enable | disable )"
  exit 3
elif [[ "$1" != "enable" && "$1" != "disable" ]]; then
  echo "Wrong arguments given, exiting."
  echo "Syntax: ./convertible-mode.sh ( enable | disable )"
  exit 4
fi

## Variables
sys_devices_platform_basepath="/sys/devices/platform"
platform="/i8042"
input_touchpad="/serio1/input/input5"
input_keyboard="/serio0/input/input3"
touchpad_fullpath="$sys_devices_platform_basepath$platform$input_touchpad/inhibited"
keyboard_fullpath="$sys_devices_platform_basepath$platform$input_keyboard/inhibited"
# decide if enable or disable
if [[ "$1" == "enable" ]]; then
  echo "# Enabling Convertible Mode #"
  echo "inhibiting integrated touchpad via $touchpad_fullpath"
  echo 1 > $touchpad_fullpath
  echo "inhibiting integrated keyboard via $keyboard_fullpath"
  echo 1 > $keyboard_fullpath
  echo "# Convertible Mode enabled #"
  exit 0
elif [[ "$1" == "disable" ]]; then
  echo "# Disabling Convertible Mode #"
  echo "un-inhibiting integrated touchpad via $touchpad_fullpath"
  echo 0 > $touchpad_fullpath
  echo "un-inhibiting integrated keyboard via $keyboard_fullpath"
  echo 0 > $keyboard_fullpath
  echo "# Disabled Convertible Mode #"
  exit 0
fi
```
**make the script executable**
```
~$ chmod u+x ~/.local/bin/convertible-mode.sh
```

### Allow user to execute Script with sudo without entering password

Create a new Group "convertible", add yourself to the new group and re-login or reboot and check your groups. 
```
~$ sudo groupadd convertible
~$ sudo usermod -a -G convertible USER
~$ groups
```

Allow the new Group to execute the new Script with sudo without entering a password.
```
~# echo '%convertible ALL=(root) NOPASSWD: /home/USER/.local/bin/convertible-mode.sh' > /etc/sudoers.d/convertible
~# chmod 400 /etc/sudoers.d/convertible
```

### Create .desktop-Files for Access to the Script in Graphical Desktop Environment

```
~$ nano ~/.local/share/applications/Convertible\ Mode.desktop
[Desktop Entry]
Encoding=UTF-8
Type=Application
NoDisplay=false
Terminal=false
Exec=/usr/bin/sudo /home/USER/.local/bin/convertible-mode.sh enable
Icon=/home/USER/.local/share/icons/hand-touching-tablet-screen.png
Name=Convertible Mode
Comment=Disables the internal Keyboard and Track-/Touchpad to allow a Convertible Device to flip without problems.
Categories=Convertible
```

```
~$ nano ~/.local/share/applications/Laptop\ Mode.desktop
[Desktop Entry]
Encoding=UTF-8
Type=Application
NoDisplay=false
Terminal=false
Exec=/usr/bin/sudo /home/USER/.local/bin/convertible-mode.sh disable
Icon=/home/USER/.local/share/icons/laptop.png
Name=Laptop Mode
Comment=Re-Enables the internal Keyboard and Track-/Touchpad to allow a Convertible Device to flip back without problems.
Categories=Convertible
```

The here referenced images / logos are from Flaticon:
 - hand-touching-tablet-screen.png https://www.flaticon.com/free-icon/hand-touching-tablet-screen_46210
 - laptop.png https://www.flaticon.com/premium-icon/laptop_1055329

```
~$ mkdir -p ~/.local/share/icons/
~$ mv ~/Downloads/hand-touching-tablet-screen.png ~/.local/share/icons/
~$ mv ~/Downloads/laptop.png ~/.local/share/icons/
```

### End Result

![grafik](https://user-images.githubusercontent.com/29387023/173155598-7585442d-425d-4c86-9dee-e8487704fc2f.png)
![grafik](https://user-images.githubusercontent.com/29387023/173155669-542aaea3-25ae-4628-9b5b-90f702122d22.png)


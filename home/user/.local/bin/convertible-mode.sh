#!/bin/bash

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

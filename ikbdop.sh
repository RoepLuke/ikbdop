#
# USE: This simple shell program can be used to disable the internal keyboard of a laptop. This can be done by
# $ ./ikbdop.sh detach
#
# To attach the internal keyboard again, use the command
# $ ./ikbdop.sh attach
# 
# You may choose to use the Desktop-Entry Files provided with this script for added simplicity / user friendlyness.
# 
# USAGE: When the internal laptop keyboard goes defective, it usually results in continuous generation of some keyboard character, thereby making it impossible to do any commandline stuff. This shell program is an easy fix.
# USAGE: When the Device is a Convertible without a supported flip/tablet-mode-switch (like HP ENVY x360) the physical keyboard can be (de)activated at will.
# 
# Original Author: anitaggu@gmail.com
# Additions/Edits by: contact@roeper-luke.de
#
# PREREQUISITES
# - install xinput (Xorg only, not recommended with XWayland) if not installed
# - install libinput (wayland only) if not installed


#!/bin/bash


#-----------------------------------------------------
# check_user()
#
# Checks if the user runing the script has 
# administrative privileges on this system.
#
# RETURNS:
# 0 when the user is root or equivalent
# 1 when the user has sudo-privileges
# 2 when the user is not privileged or could not be detected
#-----------------------------------------------------

check_user()
{
	exec_user=$(whoami)
	sudoer_user=$(sudo -lU $exec_user | grep --after-context 10 $(hostname --short))
	sudoer_all_users=$(echo $sudoer_user | grep "(ALL) ALL")
	sudoer_only_root=$(echo $sudoer_user | grep "(root) ALL")
	if [[ "$exec_user" == "root" ]]; then
		return 0
	elif [[ "$sudoer_all_users" != "" || "$sudoer_only_root" != "" ]]; then
		return 1
	else
		return 2
	fi
}


#-----------------------------------------------------
# check_displayserver()
#
# ARGS: None
#
# Checks which display server is currently runing on 
# the machine and reports result back as int.
# 
# RETURNS: 
# 1 if no display server detected
# 2 both Xorg and wayland detected
# 3 if Xorg / x11 detected
# 4 if wayland detected
#-----------------------------------------------------

check_displayserver()
{
	WAYLAND=$(pgrep wayland --count)
	XORG=$(pgrep Xorg --count)
	if [[ $WAYLAND GRT 0 ]]; then
		if [[ $XORG GRT 0 ]]; then
			#echo "both wayland and xorg display server detected"
			return 2
		else
			#echo "wayland display server detected"
			return 4
		fi
	else
		if [[ $XORG GRT 0 ]]; then
			#echo "xorg display server detected"
			return 3
		else
			#echo "no running display server detected"
			return 1
		fi
	fi
}


#-----------------------------------------------------
# usage()
#
# ARGS: All commandline arguments passed to shell.
# 
# Checks if option is either status, detach or attach
# Exits program if improper usage
#
# RETURNS: Nothing
#-----------------------------------------------------

usage() 
{
	if [[ $# -lt 1 || $# -gt 2 ]]
	then
		echo "$0 ( status | detach | attach | help ) [ xorg | wayland ]"
		exit 4
	fi
	
	if [[ "$1" -eq "help" || "$1" -eq "--help" || "$1" -eq "-help" ]]; then
		help
		exit 0
	fi
	
	if [[ "$1" -neq "status" && "$1" -neq "detach" && "$1" -neq "attach" && "$1" -neq "help" ]]; then
		echo "Syntax error on first argument. For details see '$0 help'."
		exit 4
	fi
	
	if [[ "$2" -neq "xorg" && "$2" -neq "wayland" && "$2" -neq "" ]]; then
		echo "Syntax error on second argument. For details see '$0 help'."
		exit 4
	fi
}


#-----------------------------------------------------
# help()
#
# ARGS: None
# 
# Echos the program help to stdout
#
# RETURNS: Nothing
#-----------------------------------------------------

help()
{
	echo "This simple shell program can be used to disable the internal keyboard of a laptop."
	echo ""
	echo "Syntax: $0 ( status | detach | attach | help ) [ xorg | wayland ]"
	echo ""
	echo "Arguments:"
	echo "  ( status | detach | attach | help )"
	echo "    REQUIRED ARGUMENT"
	echo "    - status: Output the current Keyboard status"
	echo "    - detach: disable the internal keyboard"
	echo "    - attach: re-enable the internal keyboard"
	echo "    - help: display this help"
	echo "  [ xorg | wayland ]"
	echo "    OPTIONAL ARGUMENT"
	echo "    - xorg: override the display server detection and try to disable the keyboard with xorg tools"
	echo "    - wayland: override the display server detection and try to disable the keyboard with wayland tools (includes xwayland and possibly no running displayserver)"
	echo ""
	echo "Exit Codes:"
	echo "  0: success (attach / detach successfull; keyboard already in the wanted state)"
	echo "  1: the attachment or detachment failed"
	echo "  2: no running display server detected"
	echo "  3: detected both xorg and wayland running and no second argument given"
	echo "  4: Command syntax error"
}


#-----------------------------------------------------
# VARIABLES
#-----------------------------------------------------

readonly mode_attached=2
readonly mode_detached=3
readonly attach_pattern='AT Translated Set 2 keyboard[[:space:]]*id=[[:digit:]]*[[:space:]]*\[slave  keyboard \([[:digit:]]*\)\]'
readonly detach_pattern='AT Translated Set 2 keyboard[[:space:]]*id=[[:digit:]]*[[:space:]]*\[floating slave\]'
readonly masterkbd_pattern='\[slave[[:space:]]*keyboard[[:space:]]*\([[:digit:]]*\)\]'
readonly wayland_device_name_internal_keyboard='AT Translated Set 2 keyboard'
readonly wayland_device_name_internal_touchpad='SynPS/2 Synaptics TouchPad'
wayland_device_inhibited_internal_keyboard=""
wayland_device_inhibited_internal_touchpad=""

#-----------------------------------------------------------
# find_status()
#
# ARGS: None
#
# Uses the output of xinput list command to detect whether
# keyboard attached or detached
#
# RETURNS: 
# 2 if keyboard attached
# 3 if keyboard dettached
#-----------------------------------------------------------

find_status() {
xinput list | awk -v attach_pattern='$attach_pattern' \
		  -v detach_pattern='$detachpattern'  \
		  -v mode_attached='$mode_attached'   \
		  -v mode_detached='$mode_detached'   \
'
/'"$attach_pattern"'/ {
	#print "Internal Keyboard attached"
	mode='"$mode_attached"' #kbd attached
}
/'"$detach_pattern"'/ {
	#print "Internal Keyboard detached"
	mode='"$mode_detached"' #kbd dettached
}
END {
	exit mode
}'
return $?
}

#-----------------------------------------------------------
# find_status_wayland()
#
# ARGS: None
#
# Uses the output of libinput command to detect whether
# keyboard attached or detached
#
# RETURNS: 
# 2 if keyboard attached
# 3 if keyboard dettached
#-----------------------------------------------------------

find_status_wayland() {

# // TODO //


return 0
}

#-------------------------------------------------------------
# find_attached_devices_wayland()
#
# ARGS: None
# PRE-CONDITION: The internal keyboard / touchpad must be attached.
# RETURNS: nothing
#-------------------------------------------------------------

find_attached_devices_wayland() {
	
	## Get /dev/input/eventX Path for internal keyboard and touchpad
	#wayland_dev-input-event_path_internal_keyboard="$(libinput list-devices | grep --after-context 1 ""$wayland_device_name_internal_keyboard"" | grep Kernel | awk '{print $2}')"
	#wayland_dev-input-event_path_internal_touchpad=$(libinput list-devices | grep --after-context 1 "$wayland_device_name_internal_touchpad" | grep Kernel | awk '{print $2}')
	
	# Get /sys/devices/platform/[...]/[...]/input/inputX/inhibited Path for internal keyboard and touchpad
	#wayland_sys-devices-platform_path_internal_keyboard=$(udevadm info --attribute-walk --path=$(udevadm info --query=path --name=$wayland_dev-input-event_path_internal_keyboard) | grep --extended-regexp --regexp='looking at parent device .\/devices\/platform\/[A-Za-z0-9]+\/[A-Za-z0-9]+\/input\/input[0-9]+.:' | awk '{print $5}' | sed 's/://' | sed 's/^./\/sys/' | sed 's/.$/\/inhibited/')
	#wayland_sys-devices-platform_path_internal_touchpad=$(udevadm info --attribute-walk --path=$(udevadm info --query=path --name=/dev/input/eventX) | grep --extended-regexp --regexp='looking at parent device .\/devices\/platform\/[A-Za-z0-9]+\/[A-Za-z0-9]+\/input\/input[0-9]+.:' | awk '{print $5}' | sed 's/://' | sed 's/^./\/sys/' | sed 's/.$/\/inhibited/')
	
}

#-------------------------------------------------------------
# find_attached_kbd_id()
#
# ARGS: None
# PRE-CONDITION: The internal keyboard must be attached.
# RETURNS: device id of the attached internal keyboard
#-------------------------------------------------------------

find_attached_kbd_id() 
{

	xinput list | awk -v attach_pattern='$attach_pattern' '
		/'"$attach_pattern"'/ {
			id=$7
			gsub("id=","", id)
			#print id
		}
		END {
			exit id
		}'
	return $?
}


#-------------------------------------------------------------
# find_detached_kbd_id()
#
# ARGS: None
# PRE-CONDITION: The internal keyboard must be detached.
# 
# Function returns the device id
#-------------------------------------------------------------

find_detached_kbd_id() 
{

	xinput list | awk -v detach_pattern='$attach_pattern' '
		/'"$detach_pattern"'/ {
			id=$7
			gsub("id=","", id)
			#print id
		}
		END {
			exit id
		}'
	return $?
}


#-------------------------------------------------------------
# find_master_kbd_id()
#
# // TODO //
# 
#-------------------------------------------------------------

find_master_kbd_id() 
{

	xinput list | awk -v masterkbd_pattern='$masterkbd_pattern' '
		BEGIN {
			masterid = -1 # impossible master id
		}
		/'"$masterkbd_pattern"'/ {
			id=$0 #save entire string to id first
			gsub(".*\[slave[[:space:]]*keyboard[[:space:]]*\(","", id) #remove preceding junk
			gsub("\)\]","", id) #remove trailing )]
			if (masterid == -1) { 
				masterid = id # initialize masterid 
				#printf("Initialized masterid to %d\n", masterid)
			} else {
				#check if new master keyboard IDs are different.
				if (masterid != id) {
					printf("ERROR: Stored master keyboard ID %d is different from new ID %d\n", masterid, id);
					exit -1 # More than one master keyboards found cannot safely reattach
				}
			}
		}
		END {
			exit masterid	
		}'
	#return $?
}

#----------------------------------------
# MAIN PROGRAM STARTS FROM HERE
#----------------------------------------

usage $*

check_displayserver
displayserver=$?
if [[ "$2" -neq "" ]]; then
	#continue
elif [[ $displayserver -eq 1 ]]; then
	echo "$0: No running display server detected, cannot decide how to disable input device. Maybe try 'wayland' as second argument. For futher details see '$0 help'."
	exit 2
elif [[ $displayserver -eq 2 ]]; then
	echo "$0: Detected both Xorg and Wayland display server running simultaneously, please see '$0 help'."
	exit 3
fi

case $1 in

status) 
	find_status
	stat=$?
	if [ $stat -eq $mode_detached ]
	then
		echo "$0: Internal keyboard detached"
	else
		echo "$0: Internal keyboard attached"
	fi
	exit 0
;;
detach)
	find_status
	stat=$?
	if [ $stat -eq $mode_detached ]
	then
		echo "$0: Internal keyboard already detached. No action taken."
		exit 0
	fi

	find_attached_kbd_id
	kbd_id=$?
	detach_cmd=`echo "xinput float $kbd_id"`
	echo "Executing command: $detach_cmd"
	$detach_cmd
	if [[ $? -neq 0 ]]; then
		exit 1
	fi
;;

attach)
	find_status
	stat=$?
	if [ $stat -eq $mode_attached ]
	then
		echo "$0: Internal keyboard already attached. No action taken."
		exit 0
	fi

	find_detached_kbd_id
	kbd_id=$?

	find_master_kbd_id
	masterid=$?

	attach_cmd=`echo "xinput reattach $kbd_id $masterid"`
	echo "Executing command: $attach_cmd"
	$attach_cmd
	if [[ $? -neq 0 ]]; then
		exit 1
	fi

;;

*)
	usage $*
;;

esac


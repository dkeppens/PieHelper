PieHelper is an extensible, user-friendly, scripted software suite for Raspberry Pi
intended for novice linux users that :

* allows for easy CLI and text menu-based management of the RaspBerry's most-used applications
	- installation
	- uninstallation
	- basic configuration
* provides easy control over these applications from either a CLI pseudo-terminal or the PieHelper menu
	- stop
	- start
	- restart
	- switching from one application to another
* offers some additional features
	- can integrate additional out-of-scope (not integrated by default) applications of the user's choice
	- running each application under a separate account
	- mounting/unmounting CIFS shares at application startup/halt
	- configuring bluetooth controllers (official PS3/PS4 controllers supported)
	- checking for required controller presence (official PS3/PS4/XBOX360 controllers and Sony Wireless Adapter/XBOX360 USB Receiver/usb/bluetooth connection methods supported)
	- optionally setting up automatic xboxdrv mapping for your controller(s) (official PS3/PS4 controllers supported)
	- selecting one integrated application to start by default on system boot

* The default list of supported integrable applications is :
	- Kodi (Media Center)
	- Moonlight (Gamestreaming from devices running NVIDIA graphic cards with Geforce Experience software)
	- RetroPie/Emulationstation (Emulator collection for retro-gaming)
	- X11 (Graphical Desktop)
	- Bash (CLI login)
	- PieHelper (Menu and CLI based management of all listed)
* Currently uninplemented :
	- Controller detection for XBOX360 controllers using an XBOX360 USB Receiver
* Needs verification :
	- xboxdrv mapping for usb PS3 controllers, bluetooth PS3 controllers and bluetooth PS4 controllers

PieHelper binds each application to a specific TTY and uses autologin functionality at TTY selection 

PieHelper has been written entirely in ksh93 and currently has no other prerequisites
except for the following assumptions 

* systemd as a service management facility
* presence of a /proc filesystem
* either apt or pacman as a package management utility

It should therefore work out of the box on Raspbian, Noobs, Ubuntu and ArchLinux distros for the Raspberry Pi

Currently however, it has only been tested on Raspbian

PieHelper written by Davy Keppens on 04/10/08
PieHelper.official@gmail.com

PieHelper is an extensible, user-friendly, scripted software suite for Raspberry Pi,
mostly intended for novice linux users that :

* allows for easy CLI and text menu-based management of the RaspBerry's most-used applications :
	- installation (package-based/script-based for Emulationstation/compilation or package-based for Moonlight)
	- uninstallation
	- basic configuration
* provides easy control over these applications from either a CLI pseudo-terminal or a TTY :
	- stop
	- start
	- restart
	- switching from one application to another
* offers some additional features :
	- can integrate additional out-of-scope (not integrated by default) applications of the user's choice
	- running each application under a separate account
	- CLI and menu-based basic OS configuration options as an alternative to raspi-config
	- optionally mounting/unmounting CIFS shares at application startup/halt (for configuration backups/restores, providing roms to Emulationstation, ...)
	- optionally running a PRE/POST command/script before/after application startup/halt
	- configuring bluetooth controllers (official PS3/PS4 controllers supported)
	- checking for configurable required controller presence for each application (official PS3/PS4/XBOX360 controllers and Sony Wireless Adapter/XBOX360 USB Receiver/usb/bluetooth connection methods supported)
	- optionally setting up automatic xboxdrv mapping for your controller(s) (official PS3/PS4 controllers supported)
	- selecting one integrated application to start by default on system boot
	- managing which TTY is allocated to each application

* The default list of supported integrable applications is :
	- Kodi (Media Center)
	- Moonlight (Gamestreaming from devices running NVIDIA graphic cards with Geforce Experience software)
	- RetroPie/Emulationstation (Emulator collection for retro-gaming)
	- X11 (Graphical Desktop)
	- Bash (CLI login)
	- PieHelper (Menu and CLI based management of all listed)

No more hassle manually installing and configuring all applications when (re)installing the system

PieHelper automates all these processes for its supported applications through an intuitive menu or well-documented CLI tools if preferred

PieHelper functions by binding each application to a specific TTY and uses autologin functionality at TTY selection  
Since PieHelper creates custom TTY configurations, any pre-existing TTY customizations should be removed before configuring PieHelper

Developed exclusively with ksh93, no other prerequisites exist except for the following assumptions :

	- systemd as a service management facility
	- presence of a /proc filesystem
	- either apt or pacman as a package management utility

Compatibility should therefore be out-of-the-box for Pi-based Raspbian, Noobs, Ubuntu and ArchLinux distros

Currently however, only the official Raspbian distro has been tested

Feedback, bug reports and feature requests can be reported on the official github repository
or emailed to the address listed below

Current state :

	- Released

Currently unimplemented :

	- Controller detection for XBOX360 controllers using an XBOX360 USB Receiver

Planned :

	- Archlinux confoper_ph.sh support
	- OSMC support
	- Enhancements in 'TODO'

Unsupported : 

	- Multiple physical displays
	- Mixing different controller types

PieHelper written by Davy Keppens on 04/10/18
PieHelper.official@gmail.com

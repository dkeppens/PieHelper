#### 
####	NOTE :	Currently undergoing a complete rewrite which is taking longer than expected
####		So be warned, at the moment large parts are not in a working state
####		Do not download for production use
####

* PieHelper is an extensible, user-friendly, scripted software suite for Raspberry Pi that aims to facilitate

	- all initial configuration tasks required, after the initial hardware and OS installation of a Raspberry Pi
	- the subsequent setup tasks such as installation, configuration and uninstallation of the most popular RaspBerry Pi software
	  Supported software will be integrated into the PieHelper framework
	- the management of that integrated software (stopping, starting, restarting and switching from one software to another)
	- the process of reinstalling the system by providing built-in methods which aim to save any manual steps (such as information entered, Kodi preferences, etc) done during the initial
	  setup to be available for automatic reuse when reinstalling

  In short, PieHelper is mainly intended for people who would like to use a RaspBerry Pi for well-known and popular applications (see default apps list below) and possibly have little to no knowledge of
  Linux to get started, as well as generally be useful for speeding up the process of installing/reinstalling systems mainly used for running those applications
  
  All operations required to set up and use the system (after the initial hardware and OS installation) and these applications are offered via intuitive text menus, with the sole exception of PieHelper's initial installation
  which is a short step-by-step process, available in the PieHelper wiki on https://github.com/dkeppens/PieHelper/wiki/Install-instructions

  PieHelper functions by binding each application to a specific TTY and uses autologin functionality at TTY selection  
  Since PieHelper creates custom TTY configurations, any pre-existing TTY customizations should be removed before configuring PieHelper and no independent ones should be created after

* The default list of applications supported by default is :

	- Kodi (Media Center)
	- Moonlight (Gamestreaming from devices running NVIDIA graphic cards with Geforce Experience software)
	- RetroPie/Emulationstation (Emulator collection for retro-gaming)
	- X11 (Graphical Desktop)
	- Bash (CLI login)
	- PieHelper (Menu and CLI based management of all the previous)

* Additionally, PieHelper offers the following functionality :

	- documented command line tools as an alternative for the menus
	- can integrate additional out-of-scope (not integrated by default) applications of the user's choice
	- running each application under a separate user account
	- optionally mounting/unmounting CIFS shares at application startup/halt (for configuration backups/restores, providing roms to Emulationstation, ...)
	- optionally running a PRE/POST command/script before/after application startup/halt
	- configuring bluetooth controllers (official PS3/PS4 controllers supported)
	- checking for configurable required controller presence for each application (official PS3/PS4/XBOX360 controllers and Sony Wireless Adapter/XBOX360 USB Receiver/usb/bluetooth connection methods supported)
	- optionally setting up automatic xboxdrv mapping for your controller(s) (official PS3/PS4 controllers supported)
	- selecting one integrated application to start by default on system boot
	- managing which TTY is allocated to each application

* Developed exclusively with bash, no other prerequisites exist except for the following assumptions :

	- systemd as a service management facility
	- presence of a /proc and /sys filesystem
	- either apt or pacman as a package management utility

* Note that PieHelper :

	- Is incompatible with login managers since graphical environments are only supported through xinit or GL
	- Must be contained to a single filesystem

* Compatibility should be out-of-the-box for Pi-based Raspbian, Noobs, and Ubuntu linux distributions
  Currently however, only the official Raspbian distro has been tested

* Feedback, bug reports and feature requests can be reported on the official github repository
  or emailed to the address listed below

* Current state : Released but still under active development (Bugs are likely so update frequently !)

* Important notes :

  Needs some work :

	- xboxdrv mapping for PS3/PS4 controllers

  Currently unimplemented :

	- Controller detection for XBOX360 controllers using an XBOX360 USB Receiver
	- expand root filesystem module for confoper_ph.sh

  Planned :
	- Enhancements in 'TODO'
	- OSMC support
	- Archlinux support

  Unsupported : 

	- Multiple physical displays
	- Mixing different controller types
	- Login managers of any kind

PieHelper written by Davy Keppens on 04/10/18
PieHelper.official@gmail.com

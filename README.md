PieHelper is an extensible, user-friendly, scripted software suite which

* allows for easy CLI and text menu-based management of the RaspBerryPi's most-used applications
	- installation
	- uninstallation
	- basic configuration
* provides easy control over these applications from either a CLI pseudo-terminal or the PieHelper menu
	- stop
	- start
	- restart
	- switching from one application to another
* the current list of supported applications is 
	- Kodi
	- Moonlight
	- RetroPie/Emulationstation
	- X11
	- Bash
	- PieHelper
* offers some additional features
	- adding and removing out-of-scope applications as supported applications
	- mounting/unmounting CIFS shares at application startup/halt
	- checking for required controller presence (PS3/PS4 supported)
	- optionally setting up automatic xboxdrv mapping for your controller(s)

* Currently uninplemented :
	- xboxdrv mapping for PS3 usb, PS3 bluetooth, PS4 bluetooth
	- Correct handling of XBOX controllers

PieHelper has been written entirely in ksh and currently has no prerequisites
except for the following assumptions 

* systemd as a service managament facility
* presence of a /proc filesystem
* either apt or pacman as a package management utility

It *SHOULD* therefore work out of the box on Raspbian, Noobs, Ubuntu and ArchLinux distros
Currently however, it has only been tested on Raspbian

PieHelper written by Davy Keppens on 04/10/08
PieHelper.official@gmail.com

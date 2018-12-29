#!/bin/ksh
# Main PieHelper (By Davy Keppens on 06/10/18)
# Enable/Disable debug by running confpieh_ph.sh -d main.sh

#set -x

# First things first
# Local variables

typeset PH_DISTRO=""
typeset PH_i=""

# Global variables
# Make PieHelper callable from anywhere

PH_SCRIPTS_DIR="$( cd "$( dirname "$0" )" && pwd )"
PH_CONF_DIR=$PH_SCRIPTS_DIR/../conf
PH_MAIN_DIR=$PH_SCRIPTS_DIR/../main
PH_FILES_DIR=$PH_SCRIPTS_DIR/../files

# Exports

export PH_MAIN_DIR PH_CONF_DIR PH_SCRIPTS_DIR PH_FILES_DIR PH_VERSION="" PH_RUN_USER="" PH_SUDO=""

# Autodetect linux distro

[[ -f /usr/bin/pacman ]] && PH_DISTRO="Archlinux" || PH_DISTRO="Debian"

# Set PATHS once

if [[ "$PH_PIEH_LOADED_CONFIG" != "yes" ]]
then
	LD_LIBRARY_PATH="/usr/local/lib:/usr/lib:/lib:$LD_LIBRARY_PATH"
	PATH="$PH_SCRIPTS_DIR:/usr/local/bin:$PATH"
	PH_PIEH_LOADED_CONFIG="yes"
	export LD_LIBRARY_PATH PATH PH_PIEH_LOADED_CONFIG
fi

# Load all application configs and controller settings

for PH_i in `ls $PH_CONF_DIR/*conf`
do
	. $PH_i
done

# Load function declarations

. $PH_MAIN_DIR/functions 
. $PH_MAIN_DIR/functions.user 

# Load distro dependent config

. $PH_CONF_DIR/distros/$PH_DISTRO.conf

# Handle functions xtrace

for PH_i in `sed 's/,/ /g' <<<$PH_PIEH_DEBUG`
do
	[[ "$PH_i" != *.sh ]] && functions -t $PH_i
done

# Setting version number

PH_VERSION=`cat $PH_CONF_DIR/VERSION`

# Setting PH_SUDO

`which sudo` bash -c exit && PH_SUDO=`which sudo`

# Autodetect first run

if [[ -f $PH_FILES_DIR/first_run ]]
then
	ph_configure_pieh || exit 1
fi

# Setting PH_RUN_USER

PH_RUN_USER=`nawk -v app=^"PieHelper"$ '$1 ~ app { print $2 }' $PH_CONF_DIR/installed_apps 2>/dev/null`

# Check who we run as

if [[ `whoami` != "$PH_RUN_USER" ]]
then
	printf "%s\n" "- Running PieHelper $PH_VERSION"
	[[ -n "$PH_RUN_USER" ]] || (printf "%2s%s\n" "" "FAILED : Cannot run PieHelper $PH_VERSION" ; \
				       printf "%10s%s\n" "" "Variable PH_RUN_USER which defines the run account is uninitialized" ; \
				       printf "%10s%s\n" "" "PieHelper needs to be configured first by running  \"$PH_SCRIPTS_DIR/confpieh_ph.sh -c\"" ; \
				       printf "%10s%s\n" "" "Rerun your original command afterwards" ; return 1) || exit $?
	printf "%2s%s\n" "" "FAILED : PieHelper must run as account \"$PH_RUN_USER\""
	exit 1
fi

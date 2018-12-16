# launch our autostart apps (if we are on the correct tty)
if [ "`tty`" = "/dev/tty1" ] && [ "$USER" = "dkeppens" ]; then
    bash "/opt/retropie/configs/all/autostart.sh"
fi

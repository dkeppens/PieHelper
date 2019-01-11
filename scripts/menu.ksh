#!/usr/bin/ksh

declare -g VAR

echo "starting menu"

echo "VAR is $VAR"

echo "setting export VAR to 'tralala'"

export VAR="tralala"

setopt

echo "VAR is $VAR"

echo "ending menu"

#!/bin/sh

# Disable screen blanking and power management modifications
xset s off
xset s noblank
xset -dpms

# Loop the shell environment continuously. If it crashes, it restarts instantly.
while true; do
    /usr/bin/AnodyneOS
done
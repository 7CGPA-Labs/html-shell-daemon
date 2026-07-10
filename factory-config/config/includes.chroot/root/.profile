# If we are on the primary virtual console, launch the display server immediately
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    exec startx -- -quiet
fi
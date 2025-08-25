#!/bin/bash

# make CapsLock behave like Ctrl:
setxkbmap -option ctrl:nocaps

# make short-pressed Ctrl behave like Escape:
xcape -e 'Control_L=Escape'

# Make <> behave like \|
xmodmap -e "keycode 94 = backslash bar"
xmodmap -e "keycode 133 = Alt_L"
xmodmap -e "keycode 134 = Alt_R"

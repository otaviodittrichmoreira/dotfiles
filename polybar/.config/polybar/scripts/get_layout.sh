#!/bin/bash

setxkbmap -query | awk '/layout:/ {print $2}'

#!/bin/bash
on=$(xset -q | grep 'Scroll Lock:' | awk '{print $NF}')
echo "$on"
if [ "$on" == "off" ]; then
   xset led named "Scroll Lock"
else
   xset -led named "Scroll Lock"
fi

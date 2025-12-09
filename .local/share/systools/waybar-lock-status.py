#!/usr/bin/python3

syscaps = open("/sys/class/leds/input3::capslock/brightness")
sysnum = open("/sys/class/leds/input3::numlock/brightness")
sysscroll = open("/sys/class/leds/input3::scrolllock/brightness")

capslock = bool(int(syscaps.read()))
numlock = bool(int(sysnum.read()))
scrolllock = bool(int(sysscroll.read()))

syscaps.close()
sysnum.close()
sysscroll.close()

text = ""
if capslock:
    text += " C "
if numlock:
    text += " N "
if scrolllock:
    text += " S "

print(f'{{"text": "{text}"}}')

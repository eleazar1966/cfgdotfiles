#!/bin/bash
killall -9 waybar 2>/dev/null
sleep 0.3
waybar >/dev/null 2>&1 &

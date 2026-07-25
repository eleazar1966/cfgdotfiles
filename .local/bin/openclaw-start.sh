#!/bin/bash
# Start OpenClaw gateway if not running
if ! pgrep -f "openclaw gateway run" > /dev/null 2>&1; then
    nohup openclaw gateway run > /dev/null 2>&1 &
    disown
    echo "OpenClaw gateway started"
else
    echo "OpenClaw gateway already running"
fi

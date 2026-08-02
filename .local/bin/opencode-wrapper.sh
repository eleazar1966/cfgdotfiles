#!/bin/bash
export PATH="/home/eleazar/.npm-global/bin:$PATH"
export TMPDIR="/var/tmp/tmpfs/opencode"
mkdir -p "$TMPDIR"
LOG="/var/tmp/tmpfs/opencode/opencode-debug.log"
echo "=== opencode launched at $(date) ===" >> "$LOG"
echo "PATH=$PATH" >> "$LOG"
echo "TTY=$(tty)" >> "$LOG"
echo "TERM=$TERM" >> "$LOG"
echo "DISPLAY=$DISPLAY" >> "$LOG"
echo "PWD=$(pwd)" >> "$LOG"
/home/eleazar/.npm-global/bin/opencode --version >> "$LOG" 2>&1
echo "version exit code: $?" >> "$LOG"
/home/eleazar/.npm-global/bin/opencode 2>> "$LOG"
EXIT_CODE=$?
echo "opencode exited with code: $EXIT_CODE" >> "$LOG"
echo "=== end ===" >> "$LOG"

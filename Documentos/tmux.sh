#!/bin/sh
tmux new-session -s "mySession" -d
tmux split-window -v
tmux split-window -h
tmux select-pane -t 0
tmux split-window -h
#tmux send-keys -t 0 C-z 'htop' Enter
tmux -2 attach-session -d

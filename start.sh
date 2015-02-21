#!/bin/bash

function new_tab() {
  TAB_NAME=$1
  COMMAND=$2
  osascript \
    -e "tell application \"Terminal\"" \
    -e "tell application \"System Events\" to keystroke \"t\" using {command down}" \
    -e "do script \"printf '\\\e]1;$TAB_NAME\\\a'; $COMMAND\" in front window" \
    -e "end tell" > /dev/null
}

killall node

new_tab "MongoDB" "cd /Users/rafalenden/Documents/Projects/api.enden.com; mongod --dbpath data/apiDatabase"
new_tab "api.enden.com" "cd /Users/rafalenden/Documents/Projects/api.enden.com; npm start"
new_tab "enden.com" "cd /Users/rafalenden/Documents/Projects/enden.com; npm start"

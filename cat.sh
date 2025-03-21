#!/usr/local/bin/bash

source ~/p/bash-debugger
fifo_name="fifo"

main() {
  n=1
  mkfifo $fifo_name 2>/dev/null
  #debug
  while [[ -p "$fifo_name" ]]; do
    echo "line #${n} = \"$(cat fifo)\""
    (( n++ ))
  done
}

alias scat='source cat.sh && echo "cat.sh was sourced successfully"'

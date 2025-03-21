#!/usr/local/bin/bash

source ~/p/bash-debugger

main() {
  n=1
  mkfifo fifo 2>/dev/null
  while true; do
    echo "line #${n} = \"$(cat fifo)\""
    (( n++ ))
  done
}

main

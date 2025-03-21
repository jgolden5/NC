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

close_fifo() {
  echo "closing fifo" >"$fifo_name"
  rm "$fifo_name"
}

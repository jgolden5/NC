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

add_line_to_fifo() {
  if [[ "$1" ]]; then
    echo "$1" >fifo
  else
    read line
    echo "$line" >fifo
  fi
}

alias scat='source cat.sh && echo "cat.sh was sourced successfully"'
alias altf='add_line_to_fifo'

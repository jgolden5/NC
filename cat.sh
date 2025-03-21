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

get_input_from_stdin_or_read() {
  if [[ "$1" ]]; then
    echo "$1"
  else
    read line
    echo "$line"
  fi
}

add_line_to_fifo() {
  get_input_from_stdin_or_read "$@" >fifo
}

alias scat='source cat.sh && echo "cat.sh was sourced successfully"'
alias altf='add_line_to_fifo'

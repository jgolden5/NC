#!/bin/bash

source ~/p/bash-debugger
fifo_name="/tmp/cat_fifo"
storage=""

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

store() {
  if [[ "$storage" ]]; then
    storage+=$'\n'"$(get_input_from_stdin_or_read "$@" | tee fifo)"
  else
    storage+="$(get_input_from_stdin_or_read "$@" | tee fifo)"
  fi
}

view_storage() {
  if [[ "$storage" ]]; then
    echo -e "$storage"
  else
    echo "--storage is empty--"
  fi
}

clear_storage() {
  storage=
}

alias altf='add_line_to_fifo'
alias sf='source fifo.sh && echo "fifo.sh was sourced successfully"'
alias cs='clear_storage'
alias vs='view_storage'

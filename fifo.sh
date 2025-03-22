#!/bin/bash

source ~/p/bash-debugger
fifo_name="/tmp/fifo"
storage=""

main() {
  n=1
  mkfifo "$fifo_name" 2>/dev/null
  #debug
  while [[ -p "$fifo_name" ]]; do
    echo "line #${n} = \"$(cat $fifo_name)\""
    (( n++ ))
  done
}

get_line() {
  if [[ "$1" ]]; then
    echo "$1"
  else
    read line
    echo "$line"
  fi
}

add_multiple_lines() {
  while read line; do
    if [[ "$line" =~ ^EOF$ ]]; then
      break
    else
      echo "$line" >$fifo_name
    fi
    (( n++ ))
  done
}

add_line() {
  get_line "$@" >$fifo_name
}

store() {
  if [[ "$storage" ]]; then
    storage+=$'\n'"$(get_input_from_stdin_or_read "$@" | tee $fifo_name)"
  else
    storage+="$(get_input_from_stdin_or_read "$@" | tee $fifo_name)"
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
  unset storage && echo "storage was successfully cleared"
}

alias al='add_line'
alias sf='source fifo.sh && echo "fifo.sh was sourced successfully"'
alias cs='clear_storage'
alias vs='view_storage'

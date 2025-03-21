#!/bin/bash

source ~/p/bash-debugger

main() {
  mkfifo /tmp/fifo 2>/dev/null #ignore "/tmp/fifo already exists" message if fifo already exists
  exec {fd}<>/tmp/fifo
  debug
  nc -l 1234 <&$fd | server >&$fd
  eval "exec $fd>&-"
}

server() {
  while true; do
    get_request || exit 1 
    send_response || exit 1
  done
}

get_request() {
  n=1
  while read line; do
    if [[ $n == 1 ]]; then
      local method="$(echo "$line" | awk '{ print $1 }')"
      local path="$(echo "$line" | awk '{ print $2 }')"
      local version="$(echo "$line" | awk '{ print $3 }' | sed 's/\r//')"
      if [[ $method == "GET" ]]; then
        if [[ $path == "/" ]]; then
          local success_message="Netcat Succeeded"
          local content_header="Content-Type: text/plain"
          response="$version 200 OK\r\n$content_header\r\n\r\n$success_message"
        else
          response="$version 404 Not Found\r\n$content_header\r\n\r\nPage not found"
        fi
      else
        response="$version 405 Method Not Allowed\r\n$content_header\r\n\r\nMethod not allowed"
      fi
    elif [[ "$line" == $'\r' ]]; then
      break
    fi
    ((n++))
    echo "$line" >&2
  done
}

send_response() {
  echo -e "$response"
  echo -e "$response" >&2
}

main

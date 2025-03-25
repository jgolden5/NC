#!/usr/local/bin/bash

source ~/p/bash-debugger

main() {
  set -x
  mkfifo /tmp/fifo_request 2>/dev/null #ignore "/tmp/fifo already exists" message if fifo already exists
  mkfifo /tmp/fifo_response 2>/dev/null
  exec {request_fd}<>/tmp/fifo_request
  exec {response_fd}<>/tmp/fifo_response 
  #nc -l 1234 <&$request_fd | server >&$request_fd
  cat <&$request_fd | server >&$response_fd
  #debug
  #echo "BLOB" | server
  eval "exec $fd>&-"
}

server() {
  local response=
  while true; do
    if [[ ! "$response" ]]; then
      get_request || exit 1 
      if [[ "$response" ]]; then
        send_response >&$response_fd || exit 1
        cat <&$response_fd | handle_response
        unset response
      else
        echo "Error: Response from request was not recognized"
        break
      fi
    fi
  done
  set +x
}

get_request() {
  n=1
  while read line; do
    if [[ "$line" =~ "200 OK" || "$line" =~ "404 Not Found" || "$line" =~ "405 Method Not Allowed" ]]; then
      continue
    elif [[ $n == 1 ]]; then
      local method="$(echo "$line" | awk '{ print $1 }')"
      local path="$(echo "$line" | awk '{ print $2 }')"
      local version="$(echo "$line" | awk '{ print $3 }' | sed 's/\r//')"
      version=${version:-"HTTP/1.0"}
      local content_header="Content-Type: text/plain"
      if [[ $method == "GET" ]]; then
        if [[ $path == "/" ]]; then
          local success_message="Netcat Succeeded"
          response="$version 200 OK\r\n$content_header\r\n\r\n$success_message"
        else
          response="$version 404 Not Found\r\n$content_header\r\n\r\nPage not found"
        fi
      else
        response="$version 405 Method Not Allowed\r\n$content_header\r\n\r\nMethod not allowed"
      fi
    elif [[ "$line" == $'\r' || ! "$line" ]]; then
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

handle_response() {
  echo "response $response is currently being handled"
}

main

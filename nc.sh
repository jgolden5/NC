#!/usr/local/bin/bash

source ~/p/bash-debugger

main() {
  mkfifo /tmp/fifo_request 2>/dev/null #ignore "/tmp/fifo already exists" message if fifo already exists
  exec {request_fd}<>/tmp/fifo_request
  #debug
  #nc -l 1234 <&$request_fd | server >&$request_fd
  cat <&$request_fd | server
  #echo "BLOB" | server
  eval "exec $request_fd>&-"
}

server() {
  local response=
  #set -x
  while true; do
    if [[ ! "$response" ]]; then
      get_request || exit 1 
      if [[ "$response" ]]; then
        handle_response || exit 1
        unset response
      else
        echo "Error: Response from request was not recognized"
        break
      fi
    fi
  done
  #set +x
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

handle_response() {
  response_code="$(echo "$response" | awk '{ print $2 }')"
  case "$response_code" in
    200)
      echo "200 OK"
      final_message="$(echo -e "$response" | awk 'END { print }')"
      echo "$final_message"
      ;;
    404)
      echo "404 Not Found. Path was not recognized"
      ;;
    405)
      echo "405 Method Not Allowed. Method was not recognized"
      ;;
    *)
      echo "Response code not recognized"
      ;;
  esac
}

main

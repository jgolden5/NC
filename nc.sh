#!/usr/local/bin/bash

source ~/p/bash-debugger

main() {
  mkfifo /tmp/fifo 2>/dev/null #ignore "/tmp/fifo already exists" message if fifo already exists
  exec {fd}<>/tmp/fifo
  #nc -l 1234 <&$fd | server >&$fd
  cat <&$fd | server >&$fd
  #debug
  #echo "BLOB" | server
  eval "exec $fd>&-"
}

server() {
  local response=
  #set -x
  while true; do
    if [[ ! "$response" ]]; then
      get_request || exit 1 
      if [[ "$response" ]]; then
        send_response || exit 1
      else
        echo "Error: Response from request was not recognized"
        break
      fi
    else
      handle_response >&2
      unset response
      break
    fi
  done
  #set +x
}

get_request() {
  n=1
  while read line; do
    if [[ $n == 1 ]]; then
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
  response_code="$(echo $response | awk '{ print $2 }')"
  case $response_code in
    200)
      cat <&$fd
      ;;
    404)
      echo "404 Not Found"
      ;;
    405)
      echo "405 Method Not Allowed"
      ;;
    *)
      echo "response code $response_code not recognized"
      ;;
  esac
}

main

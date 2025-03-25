#!/usr/local/bin/bash

source ~/p/bash-debugger

main() {
  mkfifo request 2>/dev/null
  exec {request_fd}<>request
  mkfifo response 2>/dev/null
  exec {response_fd}<>response
  #debug
  #nc -l 1234 <&$request_fd | server >&$request_fd
  cat <&$request_fd | server >&$response_fd
  eval "exec $fd>&-"
}

server() {
  local \
    line_number=1 \
    request= \
    response= \
    response_code= \
    response_message= \

  set -x
  while read line; do
    if [[ "$line" ]]; then
      get_request "$line" || exit 1 
      process_request
      response="$response_code $response_message"
    else
      send_response || exit 1
    fi
    (( line_number++ ))
  done
  set +x
}

get_request() {
  if [[ $line_number == 1 ]]; then
    request+="$1"
  fi
  echo "$line" >&2
}

process_request() {
  local method="$(echo "$line" | awk '{ print $1 }')"
  local path="$(echo "$line" | awk '{ print $2 }')"
  local version="$(echo "$line" | awk '{ print $3 }' | sed 's/\r//')"
  version=${version:-"HTTP/1.0"}
  local content_header="Content-Type: text/plain"
  if [[ $method == "GET" ]]; then
    if [[ $path == "/" ]]; then
      response_code=200
      response_message="Netcat Succeeded"
    else
      response_code="404"
    fi
  else
    response="405 $response_message"
  fi
}

send_response() {
  echo -e "$response"
}

main

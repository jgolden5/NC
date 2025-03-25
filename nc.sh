#!/usr/local/bin/bash

source ~/p/bash-debugger

main() {
  set_fifos
  #debug

  #nc -l 1234 <&$request_fd | server >&$response_fd
  cat <&$request_fd | server >&$response_fd

  eval "exec $fd>&-"
}

set_fifos() {
  mkfifo request 2>/dev/null
  exec {request_fd}<>request
  mkfifo response 2>/dev/null
  exec {response_fd}<>response
}

server() {
  local \
    line_number=1 \
    request= \
    response= \
    response_code= \
    response_reason= \
    response_body= \

  while read line; do
    set -x
    if [[ "$line" ]]; then
      get_request "$line" || exit 1
      process_request
      generate_response
    else
      echo -e "$response" >&$response_fd
      unset request
      line_number=0
    fi
    (( line_number++ ))
    set +x
  done
}

get_request() {
  if [[ $line_number == 1 ]]; then
    request+="$1"
  fi
  echo "$line" >&2
}

process_request() {
  method="$(echo "$request" | awk '{ print $1 }')"
  path="$(echo "$request" | awk '{ print $2 }')"
}

generate_response() {
  if [[ $method == "GET" ]]; then
    if [[ $path == "/" ]]; then
      response_code=200
      response_reason="OK"
      response_body="Netcat Succeeded"
    else
      response_code="404"
      response_reason="Not Found"
      response_body="path didn't exist"
    fi
  else
    response_code=405
    response_reason="Method Not Allowed"
    response_body="method was invalid"
  fi
  response="HTTP/1.0 $response_code $response_reason\r\nContent-Type: text/plain\r\nContent-Length: ${#response_body}\r\n\r\n$response_body"
}

main

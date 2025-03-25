#!/usr/local/bin/bash

source ~/p/bash-debugger

main() {
  mkfifo request 2>/dev/null
  exec {request_fd}<>request
  mkfifo response 2>/dev/null
  exec {response_fd}<>response
  #debug
  #nc -l 1234 <&$request_fd | server >&$response_fd
  cat <&$request_fd | server >&$response_fd
  eval "exec $fd>&-"
}

server() {
  local \
    line_number=1 \
    request= \
    response= \
    response_code= \
    response_reason= \
    response_body= \

  set -x
  while read line; do
    if [[ "$line" ]]; then
      get_request "$line" || exit 1
      process_request
      response="HTTP/1.0 $response_code $response_reason\r\nContent-Type: text/plain\r\nContent-Length: ${#response_body}\r\n\r\n$response_body"
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
  local method="$(echo "$request" | awk '{ print $1 }')"
  local path="$(echo "$request" | awk '{ print $2 }')"
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
}

send_response() {
  echo -e "$response" >&$response_fd
}

main

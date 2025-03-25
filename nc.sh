#!/usr/local/bin/bash

source ~/p/bash-debugger

main() {
  mkfifo response 2>/dev/null
  exec {response_fd}<>response
  nc -kl 1234 <&$response_fd | server >&$response_fd
  eval "exec $fd>&-"
}

server() {
  local \
    line_number=1 \
    request= \
    response= \
    response_code_and_reason= \
    response_body= \
    response_count=1 \

  while read line; do
    process_request_fifo "$line"
  done
}

process_request_fifo() {
  if [[ "$line" && "$line" != $'\r' ]]; then
    if [[ $line_number == 1 ]]; then
      get_request "$line" || exit 1
      process_request
      generate_response
    fi
    (( line_number++ ))
  else
    echo -e "$response"
    line_number=1
    (( response_count++ ))
  fi
}

get_request() {
  request="$1"
}

process_request() {
  method="$(echo "$request" | awk '{ print $1 }')"
  path="$(echo "$request" | awk '{ print $2 }')"
}

generate_response() {
  if [[ $method == "GET" ]]; then
    if [[ $path == "/" ]]; then
      response_code_and_reason="200 OK"
      response_body="Netcat Succeeded #${response_count}"
    else
      response_code_and_reason="404 Not Found"
      response_body="path didn't exist"
    fi
  else
    response_code_and_reason="405 Method Not Allowed"
    response_body="method was invalid"
  fi
  response="HTTP/1.0 $response_code_and_reason\r\nContent-Type: text/plain\r\nContent-Length: ${#response_body}\r\n\r\n$response_body"
}

main

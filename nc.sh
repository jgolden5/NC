#!/usr/local/bin/bash

source ~/p/bash-debugger

main() {
  mkfifo response 2>/dev/null
  exec {response_fd}<>response
  #debug
  nc -kl 1234 <&$response_fd | server >&$response_fd
  eval "exec $response_fd>&-"
  rm response
}

server() {
  local \
    line_number=1 \
    request= \
    response= \
    response_code_and_reason= \
    response_body= \
    basic_response_count=1 \

  while read line; do
    echo "line = $line" >&2
    process_request_fifo
  done
}

process_request_fifo() {
  if [[ "$line" && "$line" != $'\r' ]]; then
    if [[ $line_number == 1 ]]; then
      request="$line"
      process_request
      generate_response
    fi
    (( line_number++ ))
  else
    set -x
    echo -e "$response"
    if [[ "$binary_file" ]]; then
      cat "$binary_file"
    fi
    line_number=1
    set +x
  fi
}

process_request() {
  method="$(echo "$request" | awk '{ print $1 }')"
  path="$(echo "$request" | awk '{ print $2 }')"
}

generate_response() {
  if [[ $method == "GET" ]]; then
    if [[ "$path" == "/" ]]; then
      response_code_and_reason="200 OK"
      content_type='text/plain'
      response_body="Netcat Succeeded #${basic_response_count}"
      content_length="${#response_body}"
      (( basic_response_count++ ))
    elif [[ $path == /image.jpg ]]; then
      response_code_and_reason="200 OK"
      content_type='image/jpeg'
      content_length="$(wc -c < /Users/jgolden1/web_data/pictures_for_carolyn.jpg | awk '{ print $1 }')"
      binary_file="/Users/jgolden1/web_data/pictures_for_carolyn.jpg"
    else
      response_code_and_reason="404 Not Found"
      content_type="text/plain"
      response_body="path didn't exist"
      content_length="${#response_body}"
    fi
  else
    response_code_and_reason="405 Method Not Allowed"
    content_type="text/plain"
    response_body="method was invalid"
    content_length="${#response_body}"
  fi
  response="HTTP/1.0 $response_code_and_reason\r\nContent-Type: $content_type\r\nContent-Length: $content_length\r\n\r\n$response_body"
}

main

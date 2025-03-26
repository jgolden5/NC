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
    should_cat_file=f \
    cat_file=f \

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
    set -x
    echo -e "$response"
    if [[ "$should_cat_file" == t ]]; then
      cat "$cat_file"
    fi
    line_number=1
    (( response_count++ ))
    set +x
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
    if [[ $path == "/" || $path == index.html ]]; then
      response_code_and_reason="200 OK"
      response_body=
      content_type='image/png'
      content_length="$(wc -c <vim_image.png | awk '{ print $1 }')"
      should_cat_file=t
      cat_file=vim_image.png
    else
      response_code_and_reason="404 Not Found"
      response_body="path didn't exist"
      content_type="text/plain"
      content_length="${#response_body}"
    fi
  else
    response_code_and_reason="405 Method Not Allowed"
    response_body="method was invalid"
    content_type="text/plain"
    content_length="${#response_body}"
  fi
  response="HTTP/1.0 $response_code_and_reason\r\nContent-Type: $content_type\r\nContent-Length: $content_length\r\n\r\n$response_body"
}

main

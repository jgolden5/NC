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
    file= \

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
    echo -ne "$response"
    if [[ -f "$file" ]]; then
      cat "$file"
      unset file
    fi
    line_number=1
  fi
}

process_request() {
  method="$(echo "$request" | awk '{ print $1 }')"
  path="$(echo "$request" | awk '{ print $2 }')"
}

generate_response() {
  if [[ "$method" == "GET" ]]; then
    if [[ "$path" == "/" ]]; then
      response_body="Netcat Succeeded #${basic_response_count}"
      response="HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: ${#response_body}\r\n\r\n${response_body}"
      (( basic_response_count++ ))
    elif [[ $path == /index.html ]]; then
      response_body="$(cat /Users/jgolden1/web_data/index.html)"
      response="HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: ${#response_body}\r\n\r\n${response_body}"
    elif [[ $path == /vim_image.png ]]; then
      file="/Users/jgolden1/web_data/vim_image.png"
      content_length="$(wc -c /Users/jgolden1/web_data/vim_image.png | awk '{ print $1 }')"
      response="HTTP/1.1 200 OK\r\nContent-Type: image/png\r\nContent-Length: $content_length\r\n\r\n"
    else
      response_body="Path didn't exist"
      response="HTTP 1.1 404 Not Found\r\nContent-Type: text/plain\r\nContent-Length: ${#response_body}\r\n\r\n${response_body}"
    fi
  else
    response_body="Method was invalid"
    response="HTTP/1.1 405 Method Not Allowed\r\nContent-Type: text/plain\r\nContent-Length: ${#response_body}\r\n\r\n${response_body}"
  fi
}

main

#!/bin/sh
# Git credential helper for clones inside `docker build`.
if [ "$1" != "get" ]; then
  exit 0
fi

secret=/run/secrets/github_token
if [ ! -r "$secret" ]; then
  exit 0
fi

token=$(tr -d '\n\r' < "$secret")
if [ -z "$token" ]; then
  exit 0
fi

host=
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    host=*) host=${line#host=} ;;
  esac
done
host=${host%%:*}

case "$host" in
  github.com) ;;
  *) exit 0 ;;
esac

printf 'username=x-access-token\npassword=%s\n' "$token"

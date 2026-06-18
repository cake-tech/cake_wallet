#!/usr/bin/env bash

set -euo pipefail

INPUT_STRING="${1:?Usage: $0 <seed_string> <result.png>}"
OUTPUT="${2:?Usage: $0 <seed_string> <result.png>}"

if [[ ! -f "$OUTPUT" ]]; then
  echo "Error: '$OUTPUT' not found." >&2
  exit 1
fi

read -r IMG_W IMG_H < <(
  ffprobe -v error \
    -select_streams v:0 \
    -show_entries stream=width,height \
    -of csv=p=0 \
    "$OUTPUT" | tr ',' ' '
)

if [[ -z "$IMG_W" || -z "$IMG_H" ]]; then
  echo "Error: could not read dimensions from '$OUTPUT'." >&2
  exit 1
fi

HASH=$(printf '%s' "$INPUT_STRING" | sha256sum | awk '{print $1}')

chunk1=$(( 16#${HASH:0:8}  ))
chunk2=$(( 16#${HASH:8:8}  ))
chunk3=$(( 16#${HASH:16:8} ))
chunk4=$(( 16#${HASH:24:8} ))

R=$(( chunk1 % 256 ))
G=$(( chunk2 % 256 ))
B=$(( chunk3 % 256 ))

ROTATION=$(( chunk4 % 360 ))

R2=$(( (chunk1 / 256) % 256 ))
G2=$(( (chunk2 / 256) % 256 ))
B2=$(( (chunk3 / 256) % 256 ))

STRLEN=${#INPUT_STRING}
TILE_SIZE=$(( 64 + (STRLEN % 192) ))

GEQ_R="between(mod((X+Y),${TILE_SIZE}),0,$(( TILE_SIZE / 2 )))*${R}  + between(mod((X+Y),${TILE_SIZE}),$(( TILE_SIZE / 2 + 1 )),${TILE_SIZE})*${R2}"
GEQ_G="between(mod((X+Y),${TILE_SIZE}),0,$(( TILE_SIZE / 2 )))*${G}  + between(mod((X+Y),${TILE_SIZE}),$(( TILE_SIZE / 2 + 1 )),${TILE_SIZE})*${G2}"
GEQ_B="between(mod((X+Y),${TILE_SIZE}),0,$(( TILE_SIZE / 2 )))*${B}  + between(mod((X+Y),${TILE_SIZE}),$(( TILE_SIZE / 2 + 1 )),${TILE_SIZE})*${B2}"

ROTATION_RAD=$(awk "BEGIN { printf \"%.6f\", ${ROTATION} * 3.14159265358979 / 180 }")

TMPFILE=$(mktemp "${OUTPUT}.tmp.XXXXXX.png")
trap 'rm -f "$TMPFILE"' EXIT

ffmpeg -y \
  -f lavfi -i "nullsrc=size=${IMG_W}x${IMG_H}:rate=1" \
  -i "$OUTPUT" \
  -filter_complex "
    [0:v]geq=
      r='${GEQ_R}':
      g='${GEQ_G}':
      b='${GEQ_B}':
      a=255,
    format=rgba[bg];

    [1:v]format=rgba,
    geq=
      r='r(X,Y)':
      g='g(X,Y)':
      b='b(X,Y)':
      a='if(gte(r(X,Y)+g(X,Y)+b(X,Y),720),0,if(lte(r(X,Y)+g(X,Y)+b(X,Y),15)*gte(alpha(X,Y),250),0,alpha(X,Y)))',
    rotate=
      angle=${ROTATION_RAD}:
      fillcolor=none:
      ow=rotw(${ROTATION_RAD}):
      oh=roth(${ROTATION_RAD})[ovr];

    [bg][ovr]overlay=
      x=(W-w)/2:
      y=(H-h)/2:
      format=auto[out]
  " \
  -map "[out]" \
  -frames:v 1 \
  -update 1 \
  "$TMPFILE"

mv "$TMPFILE" "$OUTPUT"
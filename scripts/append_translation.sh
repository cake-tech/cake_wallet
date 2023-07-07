#!/bin/bash

langs=("ar" "bg" "cs" "de" "en" "es" "fr" "ha" "hi" "hr" "id" "it" "ja" "ko" "my" "nl" "pl" "pt" "ru" "th" "tr" "uk" "ur" "yo" "zh")

name=$1
text=$2

for lang in "${langs[@]}"; do
	translation="$(trans en:$lang --brief "$text")"

	# Use jq to add the new key-value pair to the JSON object
	jq_result=$(jq '. += { "'"$name"'": "'"$translation"'" }' strings_$lang.arb)

	echo "$jq_result" >strings_$lang.arb
  echo 'Added { "'"$name"'": "'"$translation"'" } to '"strings_$lang.arb"''
done

#!/bin/bash

# to use on Mac first install the translation shell `brew install translate-shell`
# then install the jq `brew install jq`
# then run this file with the English key and value that you want to be translated
# `./append_translation.sh "greetings" "Hello World!"`
# if you get an error `command not found`
# give the correct permissions to this file using `chmod 777 append_translation.sh`

langs=("ar" "bg" "cs" "de" "en" "es" "fr" "ha" "hi" "hr" "id" "it" "ja" "ko" "my" "nl" "pl" "pt" "ru" "th" "tl" "tr" "uk" "ur" "yo" "zh")

name=$1
text=$2

for lang in "${langs[@]}"; do
	translation="$(trans en:$lang --brief "$text")"

	# Use jq to add the new key-value pair to the JSON object
	jq_result=$(jq '. += { "'"$name"'": "'"$translation"'" }' ../res/values/strings_$lang.arb)

	echo "$jq_result" > ../res/values/strings_$lang.arb
  echo 'Added { "'"$name"'": "'"$translation"'" } to '"strings_$lang.arb"''
done

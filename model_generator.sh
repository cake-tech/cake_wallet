CURRENCIES=(
  "core"
  "evm"
  "monero"
  "bitcoin"
  "haven"
  "nano"
  "bitcoin_cash"
  "lightning"
  "solana"
  "ethereum"
  "polygon"
)

CURRENCY=$1

if [ "$CURRENCY" == "all" ]; then
  for dir in "${CURRENCIES[@]}"; do
    echo "Processing cw_$dir"
    cd "cw_$dir" && flutter pub get && flutter packages pub run build_runner build --delete-conflicting-outputs && cd ..
  done
else
  if [[ " ${CURRENCIES[@]} " =~ " $CURRENCY " ]]; then
    echo "Processing cw_$CURRENCY"
    cd "cw_$CURRENCY" && flutter pub get && flutter packages pub run build_runner build --delete-conflicting-outputs && cd ..
  else
    echo "Invalid currency type. Available options: all, ${CURRENCIES[@]}"
    exit 1
  fi
fi

flutter packages pub run build_runner build --delete-conflicting-outputs
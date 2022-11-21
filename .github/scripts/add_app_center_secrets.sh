while getopts a: flag
do
    case "${flag}" in
        a) android=${OPTARG};;
        #i) ios=${OPTARG};;
        *) ;;
    esac
done

# Replace app center secret with the original secret
sed -i -e "s/APP_CENTER_ANDROID_SECRET_KEY/$android/g" /opt/android/cake_wallet/android/app/src/main/java/com/cakewallet/cake_wallet/MainActivity.java
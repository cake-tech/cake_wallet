#!/bin/sh

# Decrypt the file
cd ../lib/
# --batch to prevent interactive command
# --yes to assume "yes" for questions
gpg --quiet --batch --yes --decrypt --passphrase="$SECRETS_PASSPHRASE" \
--output .secrets.g.dart .secrets.g.dart.gpg

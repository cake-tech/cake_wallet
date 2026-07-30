// Funded wallet seeds for the funds test suites.
//
// This default is empty on purpose and must stay empty in git. The manual funds workflow
// overwrites this file from the FUNDS_SECRETS_FILE secret, keys are WalletType names and
// values are that chain's funded wallet seed phrases, at least two per chain. Adding a
// chain to that secret is all it takes for the funds matrix to pick it up.
const Map<String, List<String>> fundedWalletSeeds = {};

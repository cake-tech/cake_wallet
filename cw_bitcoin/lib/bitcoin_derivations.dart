import 'package:cw_core/wallet_info.dart';

Map<DerivationType, List<DerivationInfo>> bitcoin_derivations = {
  DerivationType.bip39: [
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/0'/1",
      description: "cake default?",
      script_type: "???",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/44'/0'/0'",
      description: "Standard BIP44 legacy",
      script_type: "p2pkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/49'/0'/0'",
      description: "Standard BIP49 compatibility segwit",
      script_type: "p2wpkh-p2sh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/0'/0'",
      description: "Standard BIP84 native segwit",
      script_type: "p2wpkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/0'",
      description: "Non-standard legacy",
      script_type: "p2pkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/0'",
      description: "Non-standard compatibility segwit",
      script_type: "p2wpkh-p2sh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/0'",
      description: "Non-standard native segwit",
      script_type: "p2wpkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/44'/0'/0'",
      description: "Copay native segwit",
      script_type: "p2wpkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/0'/2147483644'",
      description: "Samourai Bad Bank (toxic change)",
      script_type: "p2wpkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/0'/2147483645'",
      description: "Samourai Whirlpool Pre Mix",
      script_type: "p2wpkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/0'/2147483646'",
      description: "Samourai Whirlpool Post Mix",
      script_type: "p2wpkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/44'/0'/2147483647'",
      description: "Samourai Ricochet legacy",
      script_type: "p2pkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/49'/0'/2147483647'",
      description: "Samourai Ricochet compatibility segwit",
      script_type: "p2wpkh-p2sh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/0'/2147483647'",
      description: "Samourai Ricochet native segwit",
      script_type: "p2wpkh",
    ),
  ],

};

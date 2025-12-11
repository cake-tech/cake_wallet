import 'package:cw_core/wallet_info.dart';

const SILENT_PAYMENTS_SCAN_PATH = "m/352'/0'/0'/1'/0";
const SILENT_PAYMENTS_SPEND_PATH = "m/352'/0'/0'/0'/0";
const SILENT_PAYMENTS_SCAN_PATH_TESTNET = "m/352'/1'/0'/1'/0";
const SILENT_PAYMENTS_SPEND_PATH_TESTNET = "m/352'/1'/0'/0'/0";

Map<DerivationType, List<DerivationInfo>> electrum_derivations = {
  DerivationType.electrum: [
    DerivationInfo(
      derivationType: DerivationType.electrum,
      derivationPath: "m/0'",
      description: "Electrum",
      scriptType: "p2wpkh",
    ),
  ],
  DerivationType.bip39: [
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/44'/0'/0'",
      description: "Standard BIP44",
      scriptType: "p2pkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/49'/0'/0'",
      description: "Standard BIP49 compatibility segwit",
      scriptType: "p2wpkh-p2sh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/0'/0'",
      description: "Standard BIP84 native segwit",
      scriptType: "p2wpkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/86'/0'/0'",
      description: "Standard BIP86 Taproot",
      scriptType: "p2tr",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/0'",
      description: "Non-standard legacy",
      scriptType: "p2pkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/0'",
      description: "Non-standard compatibility segwit",
      scriptType: "p2wpkh-p2sh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/0'",
      description: "Non-standard native segwit",
      scriptType: "p2wpkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/44'/0'/0'",
      description: "Samourai Deposit",
      scriptType: "p2wpkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/49'/0'/0'",
      description: "Samourai Deposit",
      scriptType: "p2wpkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/0'/2147483644'",
      description: "Samourai Bad Bank (toxic change)",
      scriptType: "p2wpkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/0'/2147483645'",
      description: "Samourai Whirlpool Pre Mix",
      scriptType: "p2wpkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/0'/2147483646'",
      description: "Samourai Whirlpool Post Mix",
      scriptType: "p2wpkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/44'/0'/2147483647'",
      description: "Samourai Ricochet legacy",
      scriptType: "p2pkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/49'/0'/2147483647'",
      description: "Samourai Ricochet compatibility segwit",
      scriptType: "p2wpkh-p2sh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/0'/2147483647'",
      description: "Samourai Ricochet native segwit",
      scriptType: "p2wpkh",
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/2'/0'",
      description: "Default Litecoin",
      scriptType: "p2wpkh",
    ),
  ],
};

String electrum_path = electrum_derivations[DerivationType.electrum]!.first.derivationPath!;

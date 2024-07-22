import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_core/wallet_info.dart';

Map<DerivationType, List<DerivationInfo>> electrum_derivations = {
  DerivationType.electrum: [
    DerivationInfo(
      derivationType: DerivationType.electrum,
      derivationPath: "m/0'",
      description: "Electrum",
      scriptType: SegwitAddresType.p2wpkh.value,
    ),
  ],
  DerivationType.bip39: [
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/44'/0'/0'",
      description: "Standard BIP44",
      scriptType: P2pkhAddressType.p2pkh.value,
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
      scriptType: SegwitAddresType.p2wpkh.value,
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/86'/0'/0'",
      description: "Standard BIP86 Taproot",
      scriptType: SegwitAddresType.p2tr.value,
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/0'",
      description: "Non-standard legacy",
      scriptType: P2pkhAddressType.p2pkh.value,
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/0'",
      description: "Non-standard compatibility segwit",
      scriptType: P2shAddressType.p2wpkhInP2sh.value,
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/0'",
      description: "Non-standard native segwit",
      scriptType: SegwitAddresType.p2wpkh.value,
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/44'/0'/0'",
      description: "Samourai Deposit",
      scriptType: SegwitAddresType.p2wpkh.value,
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/49'/0'/0'",
      description: "Samourai Deposit",
      scriptType: SegwitAddresType.p2wpkh.value,
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/0'/2147483644'",
      description: "Samourai Bad Bank (toxic change)",
      scriptType: SegwitAddresType.p2wpkh.value,
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
      scriptType: SegwitAddresType.p2wpkh.value,
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/44'/0'/2147483647'",
      description: "Samourai Ricochet legacy",
      scriptType: P2pkhAddressType.p2pkh.value,
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/49'/0'/2147483647'",
      description: "Samourai Ricochet compatibility segwit",
      scriptType: P2shAddressType.p2wpkhInP2sh.value,
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/0'/2147483647'",
      description: "Samourai Ricochet native segwit",
      scriptType: SegwitAddresType.p2wpkh.value,
    ),
    DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/2'/0'",
      description: "Default Litecoin",
      scriptType: SegwitAddresType.p2wpkh.value,
    ),
  ],
};

String electrum_path = electrum_derivations[DerivationType.electrum]!.first.derivationPath!;


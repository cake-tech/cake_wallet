import 'package:bitcoin_base/bitcoin_base.dart';

/// Networks supported by the app that have segwit addresses and can be used in the app
/// types (P2WPKH, P2WPKH-in-P2SH, P2WSH, P2TR).
const List<BasedUtxoNetwork> SEGWIT_SUPPORTED_NETWORKS = [
  BitcoinNetwork.mainnet,
  BitcoinNetwork.testnet,
  LitecoinNetwork.mainnet,
  LitecoinNetwork.testnet,
];

/// Networks supported by the app that only support legacy (no segwit)
/// types  (P2PKH, P2PK, P2SH).
const List<BasedUtxoNetwork> SEGWIT_NOT_SUPPORTED_NETWORKS = [
  BitcoinCashNetwork.mainnet,
  BitcoinCashNetwork.testnet,
  DogecoinNetwork.mainnet,
  DogecoinNetwork.testnet,
];

/// Determines whether a transaction has at least one input that can be
/// identified as belonging to one of [addresses], using ONLY data revealed by
/// the input itself (scriptSig pushes / witness stack) and no prevout fetch
/// required.
///
/// This works for P2PKH, P2WPKH, P2SH-P2WPKH (nested segwit) and bare P2WSH
/// 1-of-1 (this wallet's `OP_1 <pubkey> OP_1 OP_CHECKMULTISIG` scheme)
/// inputs, since spending them reveals the spender's public key directly in
/// the scriptSig, witness stack, or witness script. It does NOT work for
/// P2TR key-path spends (the witness only contains a Schnorr signature,
/// never the public key) or for any input type this function fails to parse,
/// those are reported as "unknown".
///
/// The caller must treat "unknown" as "potentially ours": route it down the
/// same prevout-fetch path as a confirmed-owned input (which needs that fetch
/// anyway, to price the fee) rather than risk misclassifying a self-funded tx
/// as received-only.
///
/// Returns true if ownership is confirmed for at least one input, false if
/// every input was parseable and confirmed NOT ours, or null if any input
/// could not be conclusively classified (caller should fail safe).
bool? transactionHasOwnedInput(
  BtcTransaction transaction,
  Set<String> addresses,
  BasedUtxoNetwork network,
) {
  var anyUnknown = false;

  for (var i = 0; i < transaction.inputs.length; i++) {
    final witness = i < transaction.witnesses.length ? transaction.witnesses[i] : null;
    final result =
        isInputOwnedByWitnessOrScriptSig(transaction.inputs[i], witness, addresses, network);

    if (result == true) {
      return true;
    }
    if (result == null) {
      anyUnknown = true;
    }
  }

  return anyUnknown ? null : false;
}

/// Classifies a single input: true = confirmed ours, false = confirmed not
/// ours, null = could not be determined from scriptSig/witness alone.
bool? isInputOwnedByWitnessOrScriptSig(
  TxInput input,
  TxWitnessInput? witness,
  Set<String> addresses,
  BasedUtxoNetwork network,
) {
  final scriptPushes = input.scriptSig.script.whereType<String>().toList();
  final witnessStack = witness?.stack ?? const <String>[];

  // P2WPKH: empty scriptSig, witness = [sig, pubkey]
  // P2SH-P2WPKH: scriptSig = [redeemScript push], witness = [sig, pubkey]
  if (witnessStack.length == 2) {
    final pubkeyHex = witnessStack[1];
    if (_isValidPubkeyHex(pubkeyHex)) {
      return _pubkeyMatchesAnyAddress(pubkeyHex, addresses, network);
    }
    return null;
  }

  // P2PKH: scriptSig = [sig, pubkey] (as script pushes)
  if (witnessStack.isEmpty && scriptPushes.length == 2) {
    final pubkeyHex = scriptPushes[1];
    if (_isValidPubkeyHex(pubkeyHex)) {
      return _pubkeyMatchesAnyAddress(pubkeyHex, addresses, network);
    }
    return null;
  }

  // Bare P2WSH 1-of-1 "multisig" (this wallet's own P2WSH scheme, see
  // ECPublic.toP2wshRedeemScript): witness = [dummy (empty), sig,
  // witnessScript], where witnessScript is `OP_1 <pubkey> OP_1
  // OP_CHECKMULTISIG`. The pubkey is embedded in the witness script rather
  // than pushed directly.
  if (witnessStack.length == 3 && witnessStack[0].isEmpty) {
    final pubkeyHex = _pubkeyFromBareMultisigScript(witnessStack[2]);
    if (pubkeyHex != null) {
      return _pubkeyMatchesAnyAddress(pubkeyHex, addresses, network);
    }
    return null;
  }

  // P2TR key-path (witness = [sig] only) reveals no pubkey; any other shape
  // (script-path spends, larger multisig, etc.) is also not conclusively
  // parseable.
  return null;
}

/// Whether [hex] is a well-formed compressed (33-byte) or uncompressed
/// (65-byte) public key hex string.
/// A shape check only, not a curve-point validity check.
bool _isValidPubkeyHex(String hex) {
  final len = hex.length;
  return (len == 66 || len == 130) && RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex);
}

/// Extracts the pubkey from a bare 1-of-1 CHECKMULTISIG witness script of
/// the form `OP_1 <pubkey> OP_1 OP_CHECKMULTISIG`, or null if [scriptHex]
/// doesn't match that exact shape.
String? _pubkeyFromBareMultisigScript(String scriptHex) {
  try {
    final ops = Script.fromRaw(hexData: scriptHex, hasSegwit: true).script;
    if (ops.length != 4 || ops[0] != 'OP_1' || ops[2] != 'OP_1' || ops[3] != 'OP_CHECKMULTISIG') {
      return null;
    }
    final pubkeyHex = ops[1] as String;
    return _isValidPubkeyHex(pubkeyHex) ? pubkeyHex : null;
  } catch (_) {
    return null;
  }
}

/// Derives every address type [pubkeyHex] could correspond to on [network]
/// (P2PKH, plus P2WPKH/P2SH-P2WPKH/P2WSH when [network] supports segwit) and
/// checks whether any of them is in [addresses]. Returns false, rather than
/// throwing, if [pubkeyHex] isn't a valid public key.
bool _pubkeyMatchesAnyAddress(String pubkeyHex, Set<String> addresses, BasedUtxoNetwork network) {
  final ECPublic pub;
  try {
    pub = ECPublic.fromHex(pubkeyHex);
  } catch (_) {
    return false;
  }

  final candidates = SEGWIT_SUPPORTED_NETWORKS.contains(network)
      ? <String>{
          pub.toP2pkhAddress().toAddress(network),
          pub.toP2wpkhAddress().toAddress(network),
          pub.toP2wpkhInP2sh().toAddress(network),
          pub.toP2wshAddress().toAddress(network),
        }
      : <String>{pub.toP2pkhAddress().toAddress(network)};

  return candidates.any(addresses.contains);
}

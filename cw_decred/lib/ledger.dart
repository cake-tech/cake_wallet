import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:cw_decred/wallet_service.dart';
import 'package:cw_decred/api/libdcrwallet.dart';
import 'package:dart_varuint_bitcoin/dart_varuint_bitcoin.dart' as varint;
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/src/operations/litecoin_sign_msg_operation.dart';
import 'package:ledger_litecoin/src/tx_utils/transaction.dart';
import 'package:ledger_litecoin/src/litecoin_transformer.dart';
import 'package:ledger_litecoin/src/tx_utils/finalize_input.dart';
import 'package:ledger_litecoin/src/tx_utils/constants.dart';
import 'package:ledger_litecoin/src/ledger/ledger_input_operation.dart';
import 'package:ledger_litecoin/src/ledger/litecoin_instructions.dart';
import 'package:ledger_litecoin/src/utils/bip32_path_helper.dart';
import 'package:ledger_litecoin/src/utils/bip32_path_to_buffer.dart';

/// This command is used to sign a given secure hash using a private key (after
/// re-hashing it following the standard Bitcoin signing process) to finalize a
/// transaction input signing process.
///
/// This command will be rejected if the transaction signing state is not
/// consistent or if a user validation is required and the provided user
/// validation code is not correct.
class UntrustedHashSignOperation extends LedgerInputOperation<Uint8List> {
  final String derivationPath;

  final int lockTime;

  final int sigHashType;

  final int expiryHeight;

  UntrustedHashSignOperation(
      this.derivationPath, this.lockTime, this.expiryHeight, this.sigHashType)
      : super(btcCLA, untrustedHashSignINS);

  @override
  int get p1 => 0x00;

  @override
  int get p2 => 0x00;

  @override
  Future<Uint8List> read(ByteDataReader reader) async {
    final result = reader.read(reader.remainingLength);

    if (result.isNotEmpty) {
      result[0] = 0x30;
      return result.sublist(0, result.length - 2);
    }

    return result;
  }

  @override
  Future<Uint8List> writeInputData() async {
    final writer = ByteDataWriter();

    final path = BIPPath.fromString(derivationPath).toPathArray();
    writer.write(packDerivationPath(path));
    writer.writeUint32(lockTime);
    writer.writeUint32(expiryHeight);
    writer.write([sigHashType]);

    return writer.toBytes();
  }
}

class HashOutputFull extends LedgerInputOperation<Uint8List> {
  final Uint8List outputScript;

  HashOutputFull(this.outputScript) : super(btcCLA, untrustedHashTransactionInputFinalizeINS);

  @override
  int get p1 => 0x80;

  @override
  int get p2 => 0x00;

  @override
  Future<Uint8List> read(ByteDataReader reader) async => reader.read(reader.remainingLength);

  @override
  Future<Uint8List> writeInputData() async => outputScript;
}

class TrustedInput {
  final bool trustedInput;
  final Uint8List value;
  final Uint8List tree;
  final Uint8List sequence;

  const TrustedInput({
    required this.trustedInput,
    required this.value,
    required this.tree,
    required this.sequence,
  });
}

/// This command is used to sign a given secure hash using a private key (after
/// re-hashing it following the standard Bitcoin signing process) to finalize a
/// transaction input signing process.
///
/// This command will be rejected if the transaction signing state is not
/// consistent or if a user validation is required and the provided user
/// validation code is not correct.
class UntrustedHashTxInputStartOperation extends LedgerInputOperation<Uint8List> {
  final bool firstRound;
  final bool isNewTransaction;

  final Uint8List transactionData;

  UntrustedHashTxInputStartOperation(this.isNewTransaction, this.firstRound, this.transactionData)
      : super(btcCLA, untrustedHashTransactionInputStartINS);

  @override
  int get p1 => firstRound ? 0x00 : 0x80;

  @override
  int get p2 => isNewTransaction ? 0x00 : 0x80;

  @override
  Future<Uint8List> read(ByteDataReader reader) async => reader.read(reader.remainingLength);

  @override
  Future<Uint8List> writeInputData() async => transactionData;
}

Future<void> startUntrustedHashTransactionInput(
    LedgerConnection connection, LedgerTransformer transformer,
    {required bool isNewTransaction,
    required Transaction transaction,
    required List<TrustedInput> inputs}) async {
  var data = ByteDataWriter()
    ..write(transaction.version)
    ..write(varint.encode(transaction.inputs.length).buffer);

  await connection.sendOperation(
      UntrustedHashTxInputStartOperation(
        isNewTransaction,
        true,
        data.toBytes(),
      ),
      transformer: transformer);

  var i = 0;

  for (final input in transaction.inputs) {
    late final Uint8List prefix;
    if (inputs[i].trustedInput) {
      prefix = Uint8List.fromList([0x01, inputs[i].value.length]);
    } else {
      prefix = Uint8List.fromList([0x00]);
    }

    final data = Uint8List.fromList([
      ...prefix,
      ...inputs[i].value,
      ...inputs[i].tree,
      ...varint.encode(input.script.length).buffer,
    ]);

    await connection.sendOperation(
        UntrustedHashTxInputStartOperation(
          isNewTransaction,
          false,
          data,
        ),
        transformer: transformer);

    final scriptBlocks = <Uint8List>[];
    var offset = 0;

    if (input.script.isEmpty) {
      scriptBlocks.add(input.sequence);
    } else {
      while (offset != input.script.length) {
        final blockSize = input.script.length - offset > MAX_SCRIPT_BLOCK
            ? MAX_SCRIPT_BLOCK
            : input.script.length - offset;

        if (offset + blockSize != input.script.length) {
          scriptBlocks.add(input.script.sublist(offset, offset + blockSize));
        } else {
          scriptBlocks.add(
            Uint8List.fromList(
                [...input.script.sublist(offset, offset + blockSize), ...input.sequence]),
          );
        }

        offset += blockSize;
      }
    }

    for (final scriptBlock in scriptBlocks) {
      await connection.sendOperation(
          UntrustedHashTxInputStartOperation(
            isNewTransaction,
            false,
            scriptBlock,
          ),
          transformer: transformer);
    }

    i++;
  }
}

/// This command is used to extract a Trusted Input (encrypted transaction hash,
/// output index, output amount) from a transaction.
///
/// The transaction data to be provided should be encoded using bitcoin standard
/// raw transaction encoding. Scripts can be sent over several APDUs.
/// Other individual transaction elements split over different APDUs will be
/// rejected. 64 bits varints are rejected.
class GetTrustedInputOperation extends LedgerInputOperation<Uint8List> {
  final int? indexLookup;

  final Uint8List inputData;

  GetTrustedInputOperation(this.inputData, [this.indexLookup]) : super(btcCLA, getTrustedInputINS);

  @override
  int get p1 => indexLookup != null ? 0x00 : 0x80;

  @override
  int get p2 => 0x00;

  @override
  Future<Uint8List> read(ByteDataReader reader) async {
    final result = reader.read(reader.remainingLength);

    return result.isNotEmpty ? result.sublist(0, result.length - 2) : result;
  }

  @override
  Future<Uint8List> writeInputData() async {
    final writer = ByteDataWriter();
    if (indexLookup != null) writer.writeUint32(indexLookup!, Endian.big);

    writer.write(inputData);

    return writer.toBytes();
  }
}

Future<String> getTrustedInput(LedgerConnection connection, LedgerTransformer transformer,
    {required int indexLookup, required Transaction transaction}) async {
  Future<Uint8List> processScriptBlocks(Uint8List script, Uint8List? sequence) async {
    final seq = sequence ?? Uint8List(0);
    final scriptBlocks = <Uint8List>[];
    var offset = 0;

    while (offset != script.length) {
      final blockSize =
          script.length - offset > MAX_SCRIPT_BLOCK ? MAX_SCRIPT_BLOCK : script.length - offset;

      if (offset + blockSize != script.length) {
        scriptBlocks.add(script.sublist(offset, offset + blockSize));
      } else {
        scriptBlocks
            .add(Uint8List.fromList([...script.sublist(offset, offset + blockSize), ...seq]));
      }

      offset += blockSize;
    }

    // Handle case when no script length: we still want to pass the sequence
    // relatable: https://github.com/LedgerHQ/ledger-live-desktop/issues/1386
    if (script.isEmpty) scriptBlocks.add(seq);

    Uint8List res = Uint8List(0);

    for (final scriptBlock in scriptBlocks) {
      res = await connection.sendOperation(GetTrustedInputOperation(scriptBlock),
          transformer: transformer);
    }

    return res;
  }

  await connection.sendOperation(
      GetTrustedInputOperation(
        Uint8List.fromList(
            [...transaction.version, ...varint.encode(transaction.inputs.length).buffer]),
        indexLookup,
      ),
      transformer: transformer);

  for (final input in transaction.inputs) {
    var data = Uint8List.fromList(
        [...input.prevout, ...input.tree!, ...varint.encode(input.script.length).buffer]);

    await connection.sendOperation(GetTrustedInputOperation(data), transformer: transformer);

    data = Uint8List.fromList([...input.script, ...input.sequence]);
    await connection.sendOperation(GetTrustedInputOperation(data), transformer: transformer);
  }

  await connection.sendOperation(
      GetTrustedInputOperation(varint.encode(transaction.outputs.length).buffer),
      transformer: transformer);

  for (final output in transaction.outputs) {
    final data = Uint8List.fromList([
      ...output.amount,
      ...[0, 0],
      ...varint.encode(output.script.length).buffer,
      ...output.script,
    ]);
    await connection.sendOperation(GetTrustedInputOperation(data), transformer: transformer);
  }

  final res = await processScriptBlocks(Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0]), null);

  return hex.encode(res);
}

class PubkeyResp {
  String pubkey;
  String address;
  String chainCode;

  PubkeyResp(this.pubkey, this.address, this.chainCode);
}

/// Returns an extended public key at the given derivation path, serialized as per BIP-32
class ExtendedPublicKeyOperation extends LedgerInputOperation<PubkeyResp> {
  /// If [displayPublicKey] is set to true the Public Key will be shown to the user on the ledger device
  final bool displayPublicKey;

  /// The [derivationPath] is a Bip32-path used to derive the public key/Address
  /// If the path is not standard, an error is returned
  final String derivationPath;

  ExtendedPublicKeyOperation({
    required this.displayPublicKey,
    required this.derivationPath,
  }) : super(0xE0, 0x40);

  @override
  Future<PubkeyResp> read(ByteDataReader reader) async {
    final b = reader.read(reader.remainingLength);
    final pubkeyLength = b[0];
    final addressLength = b[1 + pubkeyLength];
    final pubkeyB = b.sublist(1, 1 + pubkeyLength);
    final addressB = b.sublist(1 + pubkeyLength + 1, 1 + pubkeyLength + 1 + addressLength);
    final chainCodeB =
        b.sublist(1 + pubkeyLength + 1 + addressLength, 1 + pubkeyLength + 1 + addressLength + 32);
    final pubkey = uint8ListToHex(pubkeyB);
    final address = ascii.decode(addressB);
    final chainCode = uint8ListToHex(chainCodeB);
    return PubkeyResp(pubkey, address, chainCode);
  }

  @override
  int get p1 => displayPublicKey ? 0x01 : 0x00;

  @override
  int get p2 => 0x00; // legacy key type

  @override
  Future<Uint8List> writeInputData() async {
    final path = BIPPath.fromString(derivationPath).toPathArray();

    final writer = ByteDataWriter()..writeUint8(path.length); // Write length of the derivation path

    for (final element in path) {
      writer.writeUint32(element); // Add each part of the path
    }
    final b = writer.toBytes();

    return b;
  }
}

String uint8ListToHex(Uint8List data) {
  final StringBuffer hexBuffer = StringBuffer();
  for (int byte in data) {
    hexBuffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return hexBuffer.toString();
}

Uint8List hexToUint8List(String hexString) {
  if (hexString.length % 2 != 0) {
    throw ArgumentError('Hex string must have an even number of characters');
  }

  final List<int> bytes = [];
  for (int i = 0; i < hexString.length; i += 2) {
    String hexPair = hexString.substring(i, i + 2);
    int byte = int.parse(hexPair, radix: 16);
    bytes.add(byte);
  }
  return Uint8List.fromList(bytes);
}

Uint8List intToLittleEndianBytes(int value, int byteCount) {
  final buffer = Uint8List(byteCount).buffer;
  final byteData = ByteData.view(buffer);

  switch (byteCount) {
    case 1:
      byteData.setUint8(0, value);
      break;
    case 2:
      byteData.setUint16(0, value, Endian.little);
      break;
    case 4:
      byteData.setUint32(0, value, Endian.little);
      break;
    case 8:
      byteData.setUint64(0, value, Endian.little);
      break;
    default:
      throw ArgumentError('Unsupported byteCount: $byteCount');
  }

  return buffer.asUint8List();
}

Uint8List strHashToUint8List(String txid) {
  if (txid.length != 64) {
    throw ArgumentError('txid should be 32 bytes long');
  }

  final List<int> bytes = [];
  for (int i = 64; i > 0; i -= 2) {
    String hexPair = txid.substring(i - 2, i);
    int byte = int.parse(hexPair, radix: 16);
    bytes.add(byte);
  }
  return Uint8List.fromList(bytes);
}

class InputTx {
  Transaction tx;
  int vout;
  String path;
  String pubkey;
  Uint8List sequence;
  Uint8List tree;
  Uint8List redeemScript;

  InputTx(this.tx, this.vout, this.path, this.pubkey, this.sequence, this.tree, this.redeemScript);
}

Future<InputTx> createInputTx(Map<dynamic, dynamic> inp, int n, String walletName,
    Uint8List sequence, Uint8List tree, Libwallet libwallet) async {
  List<TransactionInput> ins = [];
  final vins = inp["vin"];
  for (var vin in vins) {
    final sequence = intToLittleEndianBytes(vin["sequence"], 4);
    final tree = intToLittleEndianBytes(vin["tree"], 1);
    final prevout = strHashToUint8List(vin["txid"]);
    final vout = intToLittleEndianBytes(vin["vout"], 4);
    BytesBuilder bb = BytesBuilder();
    bb.add(prevout);
    bb.add(vout);
    final inp = TransactionInput(bb.toBytes(), Uint8List.new(25), sequence, tree);
    ins.add(inp);
  }
  List<TransactionOutput> outs = [];
  final vouts = inp["vout"];
  String addr = "";
  Uint8List redeemScript = Uint8List(0);
  for (var vout in vouts) {
    final atoms = (vout["value"] * 100000000).toInt();
    final amount = intToLittleEndianBytes(atoms, 8);
    final script = hexToUint8List(vout["scriptPubKey"]["hex"]);
    final out = TransactionOutput(amount, script);
    outs.add(out);
    if (vout["n"] == n) {
      addr = vout["scriptPubKey"]["addresses"][0];
      redeemScript = hexToUint8List(vout["scriptPubKey"]["hex"]);
    }
  }
  final vaJSON = await libwallet.validateAddr(walletName, addr);
  final va = json.decode(vaJSON.isEmpty ? "{}" : vaJSON);
  final accountn = va["accountn"] ?? 0;
  final branch = va["branch"] ?? 0;
  final index = va["index"] ?? 0;
  final path = "44'/42'/" + accountn.toString() + "'/" + branch.toString() + "/" + index.toString();
  final tx = Transaction(
      version: intToLittleEndianBytes(inp["version"], 4),
      inputs: ins,
      outputs: outs,
      locktime: intToLittleEndianBytes(inp["locktime"], 4));
  return InputTx(tx, n, path, va["pubkey"], sequence, tree, redeemScript);
}

Uint8List serializeTransactionOutputs(List<dynamic> outs) {
  var outputBuffer = outs.isNotEmpty ? varint.encode(outs.length).buffer : Uint8List(0);

  for (final out in outs) {
    final atoms = (out["value"] * 100000000).toInt();
    outputBuffer = Uint8List.fromList([
      ...outputBuffer,
      ...intToLittleEndianBytes(atoms, 8),
      ...intToLittleEndianBytes(out["version"], 2),
      ...varint.encode(out["scriptPubKey"]["hex"].length).buffer,
      ...hexToUint8List(out["scriptPubKey"]["hex"]),
    ]);
  }

  return outputBuffer;
}

Future<String> signTransaction(
    String unsignedTx, String walletName, LedgerConnection connection, Libwallet libwallet) async {
  final verboseTxJSON = await libwallet.decodeTx(walletName, unsignedTx);
  final verboseTx = json.decode(verboseTxJSON.isEmpty ? "{}" : verboseTxJSON);
  final targetTx = Transaction(version: intToLittleEndianBytes(verboseTx["version"], 4));
  targetTx.locktime = intToLittleEndianBytes(verboseTx["locktime"], 4);
  final vins = verboseTx["vin"];
  final nullScript = Uint8List(0);
  final nullPrevout = Uint8List(0);
  var ins = [];
  List<TransactionInput> ttIns = [];
  for (var vin in vins) {
    final txIds = jsonEncode([vin["txid"]]);
    final txHexesJSON = await libwallet.getTxn(walletName, txIds);
    final txHexes = json.decode(txHexesJSON);
    final verboseInJSON = await libwallet.decodeTx(walletName, txHexes[0]);
    final verboseIn = json.decode(verboseInJSON.isEmpty ? "{}" : verboseInJSON);
    final sequence = intToLittleEndianBytes(vin["sequence"], 4);
    final tree = intToLittleEndianBytes(vin["tree"], 1);
    ins.add(await createInputTx(verboseIn, vin["vout"], walletName, sequence, tree, libwallet));
    ttIns.add(TransactionInput(nullPrevout, nullScript, sequence, tree));
  }
  targetTx.inputs = ttIns;
  String changePath = "";
  final vouts = verboseTx["vout"];
  final prefixWriter = ByteDataWriter();
  prefixWriter.write(varint.encode(vouts.length).buffer);
  for (var vout in vouts) {
    final addr = vout["scriptPubKey"]["addresses"][0];
    final vaJSON = await libwallet.validateAddr(walletName, addr);
    final va = json.decode(vaJSON.isEmpty ? "{}" : vaJSON);
    final atoms = (vout["value"] * 100000000).toInt();
    final script = vout["scriptPubKey"]["hex"];
    prefixWriter.write(intToLittleEndianBytes(atoms, 8));
    prefixWriter.write(intToLittleEndianBytes(vout["version"], 2));
    prefixWriter.write(varint.encode((script.length / 2).toInt()).buffer);
    prefixWriter.write(hexToUint8List(script));
    final branch = va["branch"] ?? 0;
    // Assume the internal branch is change.
    if (branch == 1) {
      final accountn = va["accountn"] ?? 0;
      final index = va["index"] ?? 0;
      changePath = "44'/42'/" + accountn.toString() + "'/1/" + index.toString();
    }
  }
  final version = intToLittleEndianBytes(verboseTx["version"], 4);
  final List<TrustedInput> trustedInputs = [];
  final List<TransactionOutput> regularOutputs = [];
  final List<Uint8List> signatures = [];
  final LitecoinTransformer transformer = LitecoinTransformer();
  final outputScript = serializeTransactionOutputs(vouts);

  for (final inp in ins) {
    final trustedInput =
        await getTrustedInput(connection, transformer, indexLookup: inp.vout, transaction: inp.tx);

    trustedInputs.add(TrustedInput(
      trustedInput: true,
      value: hexToUint8List(trustedInput),
      tree: inp.tree,
      sequence: inp.sequence,
    ));

    regularOutputs.add(inp.tx.outputs[inp.vout]);
  }
  var isNewTx = true;
  for (var i = 0; i < ins.length; i++) {
    final script = ins[i].redeemScript;
    targetTx.inputs[i].script = script;
    await startUntrustedHashTransactionInput(
      connection,
      transformer,
      isNewTransaction: isNewTx,
      transaction: targetTx,
      inputs: trustedInputs,
    );

    await provideOutputFullChangePath(connection, transformer, path: changePath);

    await connection.sendOperation(HashOutputFull(prefixWriter.toBytes()),
        transformer: transformer);

    const SIGHASH_ALL = 1;
    final signature = await connection.sendOperation(
        UntrustedHashSignOperation(
            ins[i].path, verboseTx["locktime"], verboseTx["expiry"], SIGHASH_ALL),
        transformer: transformer);

    isNewTx = false;
    signatures.add(signature);
    targetTx.inputs[i].script = nullScript;
  }

  var sigScripts = [];
  for (int i = 0; i < signatures.length; i++) {
    final pk = hexToUint8List(ins[i].pubkey);
    final sigBuffer = Uint8List.fromList([
      ...varint.encode(signatures[i].length).buffer,
      ...signatures[i],
      ...varint.encode(pk.length).buffer,
      ...pk,
    ]);
    sigScripts.add(hex.encode(sigBuffer));
  }
  final sigScriptsJSON = jsonEncode(sigScripts);
  return await libwallet.addSigs(walletName, unsignedTx, sigScriptsJSON);
}

class LedgerWalletService extends HardwareWalletService {
  LedgerWalletService(
    this.ledgerConnection, {
    this.transformer = const LitecoinTransformer(),
    this.derivPath = "m/44'/42'/0'/0/0",
  });
  final LedgerConnection ledgerConnection;
  final LitecoinTransformer transformer;
  final String derivPath;

  // NOTE: Seems unused. We need the wallet name and libwallet for signing so
  // not adding to this class.
  @override
  Future<Uint8List> signTransaction({required String transaction}) => throw UnimplementedError();

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    await DecredWalletService.initLibwallet();

    final accounts = <HardwareAccountData>[];
    final indexRange = List.generate(limit, (i) => i + index);
    final parentPkRes = await ledgerConnection.sendOperation<PubkeyResp>(
        ExtendedPublicKeyOperation(displayPublicKey: false, derivationPath: "44'/42'"),
        transformer: transformer);

    for (final i in indexRange) {
      final derivationPath = "44'/42'/$i'";
      final pkRes = await ledgerConnection.sendOperation<PubkeyResp>(
          ExtendedPublicKeyOperation(displayPublicKey: false, derivationPath: derivationPath),
          transformer: transformer);

      final createReq = {
        "key": pkRes.pubkey,
        "parentkey": parentPkRes.pubkey,
        "chaincode": pkRes.chainCode,
        "network": "mainnet", // TODO: Change with network.
        "depth": 2,
        "childn": i,
        "isprivate": false,
      };

      final xpub = await DecredWalletService.libwallet!.createExtendedKey(jsonEncode(createReq));

      // The xpub is at the account level. 0/0 will take the address from the
      // external branch with index 0.
      final addrReq = {
        "key": xpub,
        "path": "0/0",
        "addrtype": "p2pkh",
      };

      final address = await DecredWalletService.libwallet!.addrFromExtendedKey(jsonEncode(addrReq));

      accounts.add(HardwareAccountData(
        address: address,
        accountIndex: i,
        derivationPath: derivationPath,
        xpub: xpub,
      ));
    }

    return accounts;
  }

  /// This command is used to sign message using a private key.
  ///
  /// The signature is performed as follows:
  /// The [message] to sign is the magic "\x19Decred Signed Message:\n" -
  /// followed by the length of the message to sign on 1 byte (if requested) followed by the binary content of the message
  /// The signature is performed on a double SHA-256 hash of the data to sign using the selected private key
  ///
  ///
  /// The signature is returned using the standard ASN-1 encoding.
  /// To convert it to the proprietary Bitcoin-QT format, the host has to :
  ///
  /// Get the parity of the first byte (sequence) : P
  /// Add 27 to P if the public key is not compressed, otherwise add 31 to P
  /// Return the Base64 encoded version of P || r || s
  @override
  Future<Uint8List> signMessage({required Uint8List message, String? derivationPath}) async {
    var dp = derivationPath;
    if (dp == null) {
      dp = derivPath;
    }
    return await ledgerConnection.sendOperation<Uint8List>(
      LitecoinSignMsgOperation(message, dp),
      transformer: transformer,
    );
  }
}

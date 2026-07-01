import 'package:cw_core/db/sqlite.dart';

class BridgeTransfer {
  BridgeTransfer({
    required this.id,
    required this.walletId,
    required this.sourceChainId,
    required this.destinationChainId,
    required this.tokenSymbol,
    required this.tokenContract,
    required this.amount,
    required this.recipientAddress,
    required this.sourceTxHash,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.confirmedAt,
    this.amountRaw,
    this.errorMessage,
    this.statusMessage,
  });

  static const tableName = 'BridgeTransfer';

  static Future<List<BridgeTransfer>> selectAll() async {
    final database = db;
    if (database == null) return [];

    final rows = await database.query(
      tableName,
      orderBy: 'created_at DESC',
    );
    return rows.map(fromRow).toList();
  }

  static Future<void> insert(BridgeTransfer transfer) async {
    final database = db;
    if (database == null) return;

    await database.insert(tableName, transfer.toRow());
  }

  static Future<void> update(BridgeTransfer transfer) async {
    final database = db;
    if (database == null) return;

    await database.update(
      tableName,
      transfer.toRow(),
      where: 'id = ?',
      whereArgs: [transfer.id],
    );
  }

  String id;
  String walletId;
  int sourceChainId;
  int destinationChainId;
  String tokenSymbol;
  String tokenContract;
  String amount;
  String recipientAddress;
  String sourceTxHash;
  String status;
  DateTime createdAt;
  DateTime? updatedAt;
  DateTime? confirmedAt;
  String? amountRaw;
  String? errorMessage;
  String? statusMessage;

  bool get isActive => status == 'submitted' || status == 'confirming' || status == 'initiated';

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'wallet_id': walletId,
      'source_chain_id': sourceChainId,
      'destination_chain_id': destinationChainId,
      'token_symbol': tokenSymbol,
      'token_contract': tokenContract,
      'amount': amount,
      'recipient_address': recipientAddress,
      'source_tx_hash': sourceTxHash,
      'status': status,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
      'confirmed_at': confirmedAt?.millisecondsSinceEpoch,
      'amount_raw': amountRaw,
      'error_message': errorMessage,
      'status_message': statusMessage,
    };
  }

  static int? _nullableInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static int _parseInt(Object? v) => _nullableInt(v) ?? 0;
  static DateTime _parseDateTime(Object? v) => DateTime.fromMillisecondsSinceEpoch(_parseInt(v));

  static BridgeTransfer fromRow(Map<String, Object?> m) {
    String? asStr(Object? v) => v as String?;

    return BridgeTransfer(
      id: m['id'] as String,
      walletId: m['wallet_id'] as String,
      sourceChainId: _parseInt(m['source_chain_id']),
      destinationChainId: _parseInt(m['destination_chain_id']),
      tokenSymbol: m['token_symbol'] as String,
      tokenContract: m['token_contract'] as String,
      amount: m['amount'] as String,
      recipientAddress: m['recipient_address'] as String,
      sourceTxHash: m['source_tx_hash'] as String,
      status: m['status'] as String,
      createdAt: _parseDateTime(m['created_at']),
      updatedAt: _parseDateTime(m['updated_at']),
      confirmedAt: _parseDateTime(m['confirmed_at']),
      amountRaw: asStr(m['amount_raw']),
      errorMessage: asStr(m['error_message']),
      statusMessage: asStr(m['status_message']),
    );
  }
}

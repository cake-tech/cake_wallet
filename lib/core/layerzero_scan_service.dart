import 'dart:convert';

import 'package:cw_core/utils/proxy_wrapper.dart';

class LayerZeroScanService {
  static const String _baseUrl = 'https://scan.layerzero-api.com/v1';

  static Future<LayerZeroMessageStatus?> getMessageStatus(
    String sourceTxHash,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/messages/tx/$sourceTxHash');

      final response = await ProxyWrapper().get(clearnetUri: uri);

      if (response.statusCode != 200) return null;

      final decoded = json.decode(response.body);

      Map<String, dynamic>? data;
      if (decoded is List && decoded.isNotEmpty) {
        data = decoded.first as Map<String, dynamic>?;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('data') && decoded['data'] is List) {
          final dataList = decoded['data'] as List;
          if (dataList.isNotEmpty) {
            data = dataList.first as Map<String, dynamic>?;
          }
        } else {
          data = decoded;
        }
      }
      if (data == null) return null;
      return LayerZeroMessageStatus.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}

class LayerZeroMessageStatus {
  final String? guid;
  final LayerZeroStatus? status;
  final LayerZeroSource? source;
  final LayerZeroDestination? destination;
  final LayerZeroVerification? verification;

  LayerZeroMessageStatus({
    this.guid,
    this.status,
    this.source,
    this.destination,
    this.verification,
  });

  factory LayerZeroMessageStatus.fromJson(Map<String, dynamic> json) {
    return LayerZeroMessageStatus(
      guid: json['guid'] as String?,
      status: json['status'] != null
          ? LayerZeroStatus.fromJson(
              json['status'] as Map<String, dynamic>,
            )
          : null,
      source: json['source'] != null
          ? LayerZeroSource.fromJson(
              json['source'] as Map<String, dynamic>,
            )
          : null,
      destination: json['destination'] != null
          ? LayerZeroDestination.fromJson(
              json['destination'] as Map<String, dynamic>,
            )
          : null,
      verification: json['verification'] != null
          ? LayerZeroVerification.fromJson(
              json['verification'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  bool get isDelivered =>
      status?.name == 'DELIVERED' ||
      destination?.status == 'DELIVERED' ||
      destination?.status == 'SUCCEEDED';

  bool get isFailed => status?.name == 'FAILED' || destination?.status == 'FAILED';

  bool get isInflight =>
      status?.name == 'INFLIGHT' ||
      status?.name == 'CONFIRMING' ||
      destination?.status == 'WAITING' ||
      destination?.status == 'VALIDATING_TX' ||
      (destination?.status != 'SUCCEEDED' &&
          destination?.status != 'DELIVERED' &&
          destination?.status != 'FAILED' &&
          destination?.tx == null);
}

class LayerZeroStatus {
  final String? name;
  final String? message;

  LayerZeroStatus({this.name, this.message});

  factory LayerZeroStatus.fromJson(Map<String, dynamic> json) {
    return LayerZeroStatus(
      name: json['name'] as String?,
      message: json['message'] as String?,
    );
  }
}

class LayerZeroSource {
  final String? status;
  final LayerZeroTransaction? tx;

  LayerZeroSource({
    this.status,
    this.tx,
  });

  factory LayerZeroSource.fromJson(Map<String, dynamic> json) {
    return LayerZeroSource(
      status: json['status'] as String?,
      tx: json['tx'] != null
          ? LayerZeroTransaction.fromJson(
              json['tx'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class LayerZeroDestination {
  final String? status;
  final LayerZeroTransaction? tx;
  final LayerZeroNativeDrop? nativeDrop;
  final LayerZeroLzCompose? lzCompose;

  LayerZeroDestination({
    this.status,
    this.tx,
    this.nativeDrop,
    this.lzCompose,
  });

  factory LayerZeroDestination.fromJson(Map<String, dynamic> json) {
    return LayerZeroDestination(
      status: json['status'] as String?,
      tx: json['tx'] != null
          ? LayerZeroTransaction.fromJson(
              json['tx'] as Map<String, dynamic>,
            )
          : null,
      nativeDrop: json['nativeDrop'] != null
          ? LayerZeroNativeDrop.fromJson(
              json['nativeDrop'] as Map<String, dynamic>,
            )
          : null,
      lzCompose: json['lzCompose'] != null
          ? LayerZeroLzCompose.fromJson(
              json['lzCompose'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class LayerZeroNativeDrop {
  final String? status;

  LayerZeroNativeDrop({this.status});

  factory LayerZeroNativeDrop.fromJson(Map<String, dynamic> json) {
    return LayerZeroNativeDrop(
      status: json['status'] as String?,
    );
  }
}

class LayerZeroLzCompose {
  final String? status;

  LayerZeroLzCompose({this.status});

  factory LayerZeroLzCompose.fromJson(Map<String, dynamic> json) {
    return LayerZeroLzCompose(
      status: json['status'] as String?,
    );
  }
}

class LayerZeroTransaction {
  final String? txHash;
  final String? blockHash;
  final String? blockNumber;
  final int? blockTimestamp;
  final String? from;

  LayerZeroTransaction({
    this.txHash,
    this.blockHash,
    this.blockNumber,
    this.blockTimestamp,
    this.from,
  });

  factory LayerZeroTransaction.fromJson(Map<String, dynamic> json) {
    final blockNumberValue = json['blockNumber'];
    final blockNumberStr = blockNumberValue != null
        ? (blockNumberValue is int ? blockNumberValue.toString() : blockNumberValue as String?)
        : null;
    return LayerZeroTransaction(
      txHash: json['txHash'] as String?,
      blockHash: json['blockHash'] as String?,
      blockNumber: blockNumberStr,
      blockTimestamp: json['blockTimestamp'] as int?,
      from: json['from'] as String?,
    );
  }
}

class LayerZeroVerification {
  final LayerZeroDvn? dvn;
  final LayerZeroSealer? sealer;

  LayerZeroVerification({
    this.dvn,
    this.sealer,
  });

  factory LayerZeroVerification.fromJson(Map<String, dynamic> json) {
    return LayerZeroVerification(
      dvn: json['dvn'] != null
          ? LayerZeroDvn.fromJson(
              json['dvn'] as Map<String, dynamic>,
            )
          : null,
      sealer: json['sealer'] != null
          ? LayerZeroSealer.fromJson(
              json['sealer'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class LayerZeroDvn {
  final Map<String, LayerZeroDvnStatus>? dvns;
  final String? status;

  LayerZeroDvn({
    this.dvns,
    this.status,
  });

  factory LayerZeroDvn.fromJson(Map<String, dynamic> json) {
    final dvnsMap = json['dvns'] as Map<String, dynamic>?;
    final parsedDvns = dvnsMap?.map(
      (key, value) => MapEntry(
        key,
        LayerZeroDvnStatus.fromJson(value as Map<String, dynamic>),
      ),
    );
    return LayerZeroDvn(
      dvns: parsedDvns,
      status: json['status'] as String?,
    );
  }
}

class LayerZeroDvnStatus {
  final String? status;
  final String? txHash;
  final String? blockHash;
  final int? blockNumber;
  final int? blockTimestamp;

  LayerZeroDvnStatus({
    this.status,
    this.txHash,
    this.blockHash,
    this.blockNumber,
    this.blockTimestamp,
  });

  factory LayerZeroDvnStatus.fromJson(Map<String, dynamic> json) {
    return LayerZeroDvnStatus(
      status: json['status'] as String?,
      txHash: json['txHash'] as String?,
      blockHash: json['blockHash'] as String?,
      blockNumber: json['blockNumber'] as int?,
      blockTimestamp: json['blockTimestamp'] as int?,
    );
  }
}

class LayerZeroSealer {
  final String? status;
  final LayerZeroTransaction? tx;

  LayerZeroSealer({
    this.status,
    this.tx,
  });

  factory LayerZeroSealer.fromJson(Map<String, dynamic> json) {
    return LayerZeroSealer(
      status: json['status'] as String?,
      tx: json['tx'] != null
          ? LayerZeroTransaction.fromJson(
              json['tx'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

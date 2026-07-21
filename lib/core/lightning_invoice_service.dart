import "dart:convert";

import "package:cw_core/utils/proxy_wrapper.dart";

Future<String?> getBolt11FromLightingAddress(String lightningAddress, {int amount = 0}) async {
  try {
    final uri = getURlOfLightningAddress(lightningAddress);

    var response = await ProxyWrapper().get(clearnetUri: uri);
    final responseBody =
        _LNURLPResponseDTO.fromJson(jsonDecode(response.body) as Map<String, dynamic>);

    response =
        await ProxyWrapper().get(clearnetUri: Uri.parse("${responseBody.callback}?amount=$amount"));

    final callbackResponseBody =
        _LNURLPCallbackResponseDTO.fromJson(jsonDecode(response.body) as Map<String, dynamic>);

    return callbackResponseBody.pr;
  } catch (e) {
    return null;
  }
}

Uri getURlOfLightningAddress(String lightningAddress) {
  final parts = lightningAddress.split("@");

  final name = parts.first;
  final domain = parts.last;
  return Uri.parse("https://$domain/.well-known/lnurlp/$name");
}

class _LNURLPResponseDTO {
  const _LNURLPResponseDTO(
    this.callback,
    this.maxSendable,
    this.minSendable,
    this.tag,
    this.metadata,
  );

  factory _LNURLPResponseDTO.fromJson(Map<String, dynamic> map) => _LNURLPResponseDTO(
        map["callback"] as String,
        map["maxSendable"] as int,
        map["minSendable"] as int,
        map["tag"] as String,
        map["metadata"] as String,
      );

  final String callback;
  final int maxSendable;
  final int minSendable;
  final String tag;
  final String metadata;
}

class _LNURLPCallbackResponseDTO {
  const _LNURLPCallbackResponseDTO(this.pr);

  factory _LNURLPCallbackResponseDTO.fromJson(Map<String, dynamic> map) =>
      _LNURLPCallbackResponseDTO(map["pr"] as String);

  final String pr;
}

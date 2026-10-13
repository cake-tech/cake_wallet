import "dart:convert";

import "package:cw_core/utils/proxy_wrapper.dart";
import "package:json_annotation/json_annotation.dart";

enum HttpMethod { get, post }

abstract class ApiRequest<Res> {
  const ApiRequest() : method = HttpMethod.get;

  const ApiRequest.post() : method = HttpMethod.post;

  @JsonKey(includeToJson: false, includeFromJson: false)
  final HttpMethod method;

  // no it can't be String get path because the json serializer would break lol
  String path();

  Map<String, dynamic> toJson();

  Res decode(Object json);
}

class ProviderHttpException implements Exception {
  ProviderHttpException(this.statusCode, this.message, {required this.body, this.json});

  final int statusCode;
  final String message;
  final String body;

  final Object? json;

  @override
  String toString() => message;
}

class ProviderApi {
  ProviderApi(this._proxy, {required this.authority, this.headers = const {}, this.errorMessage});

  final ProxyWrapper _proxy;
  final String authority;
  final Map<String, String> headers;

  // every provider has a slightly different way of providing the error message
  // we pass in a function for this to show a meaningful error in logs instead of Instance of WhateverException
  final String? Function(Map<String, dynamic> json)? errorMessage;

  Future<Res> send<Res>(
    ApiRequest<Res> request, {
    Exception? Function(ProviderHttpException error)? mapError,
  }) async {
    final response = switch (request.method) {
      HttpMethod.get => await _proxy.get(
        clearnetUri: Uri.https(authority, request.path(), request.toJson()),
        headers: headers,
      ),
      HttpMethod.post => await _proxy.post(
        clearnetUri: Uri.https(authority, request.path()),
        headers: {...headers, "Content-Type": "application/json"},
        body: json.encode(request.toJson()),
      ),
    };

    if (response.statusCode < 200 || response.statusCode > 299) {
      final error = _error(response.statusCode, response.body);
      throw mapError?.call(error) ?? error;
    }

    return request.decode(json.decode(response.body) as Object);
  }

  ProviderHttpException _error(int statusCode, String body) {
    final decoded = _tryDecode(body);
    final parsed = decoded is Map<String, dynamic> ? errorMessage?.call(decoded) : null;
    final message = parsed ?? (decoded == null ? "HTTP $statusCode" : "HTTP $statusCode: $body");
    return ProviderHttpException(statusCode, message, body: body, json: decoded);
  }

  static Object? _tryDecode(String body) {
    try {
      return json.decode(body);
    } on FormatException {
      return null;
    }
  }
}

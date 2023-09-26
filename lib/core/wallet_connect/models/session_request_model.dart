import 'package:wallet_connect_v2/wallet_connect_v2.dart';

class SessionRequestModel {
  final SessionProposal? request;
  final String? message;

  SessionRequestModel({
    this.request,
    this.message,
  });

  @override
  String toString() {
    return 'SessionRequestModel(request: $request, sessionRequest: $message)';
  }
}
